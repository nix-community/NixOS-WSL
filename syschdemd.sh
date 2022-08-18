#! @shell@

set -e

sw="/nix/var/nix/profiles/system/sw/bin"
systemPath=$(${sw}/readlink -f /nix/var/nix/profiles/system)

function start_systemd {
    echo "Starting systemd..." >&2

    PATH=/run/current-system/systemd/lib/systemd:@fsPackagesPath@ \
        LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive \
        @daemonize@/bin/daemonize /run/current-system/sw/bin/unshare -fp --mount-proc @systemdWrapper@

    # Wait until systemd has been started to prevent a race condition from occuring
    while ! $sw/pgrep -xf systemd | $sw/tail -n1 >/run/systemd.pid; do
        $sw/sleep 1s
    done

    # Wait for systemd to start services
    status=1
    while [[ $status -gt 0 ]]; do
        $sw/sleep 1
        status=0
        $sw/nsenter -t $(</run/systemd.pid) -p -m -- \
            $sw/systemctl is-system-running -q --wait 2>/dev/null ||
            status=$?
    done
}

# Needs root to work
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Requires root! :( Make sure the WSL default user is set to root" >&2
    exit 1
fi

if [ ! -e "/run/current-system" ]; then
    LANG="C.UTF-8" /nix/var/nix/profiles/system/activate
fi

if [ ! -e "/run/systemd.pid" ]; then
    start_systemd
fi

userShell=$($sw/getent passwd @defaultUser@ | $sw/cut -d: -f7)
if [[ $# -gt 0 ]]; then
    # wsl seems to prefix with "-c"
    shift
    cmd="$@"
else
    cmd="$userShell"
fi

# Pass external environment but filter variables specific to root user.
exportCmd="$(export -p | $sw/grep -vE ' (HOME|LOGNAME|SHELL|USER)='); export WSLPATH=\"$PATH\"; export INSIDE_NAMESPACE=true"

if [[ -z "${INSIDE_NAMESPACE:-}" ]]; then

    # Test whether systemd is still alive if it was started previously
    if ! [ -d "/proc/$(</run/systemd.pid)" ]; then
        # Clear systemd pid if the process is not alive anymore
        $sw/rm /run/systemd.pid
        start_systemd
    fi

    # If we are currently in /root, this is probably because the directory that WSL was started is inaccessible
    # cd to the user's home to prevent a warning about permission being denied on /root
    if [[ $PWD == "/root" ]]; then
        cd @defaultUserHome@
    fi

    exec $sw/nsenter -t $(</run/systemd.pid) -p -m -- $sw/machinectl -q \
        --uid=@defaultUser@ shell .host /bin/sh -c \
        "cd \"$PWD\"; $exportCmd; source /etc/set-environment; exec $cmd"

else
    exec $cmd
fi
