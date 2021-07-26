#! @shell@

set -e

sw="/nix/var/nix/profiles/system/sw/bin"
systemPath=`${sw}/readlink -f /nix/var/nix/profiles/system`

# Needs root to work
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Requires root! :( Make sure the WSL default user is set to root"
    exit 1
fi

if [ ! -e "/run/current-system" ]; then
    LANG="C.UTF-8" /nix/var/nix/profiles/system/activate
fi

if [ ! -e "/run/systemd.pid" ]; then
    PATH=/run/current-system/systemd/lib/systemd:@fsPackagesPath@ \
        LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive \
        @daemonize@/bin/daemonize /run/current-system/sw/bin/unshare -fp --mount-proc systemd
    /run/current-system/sw/bin/pgrep -xf systemd > /run/systemd.pid

    # Wait for systemd to start
    status=1
    while [[ $status -gt 0 ]]; do
        $sw/sleep 1
        status=0
        $sw/nsenter -t $(< /run/systemd.pid) -p -m -- \
                    $sw/systemctl is-system-running -q --wait 2>/dev/null \
            || status=$?
    done
fi

userShell=$($sw/getent passwd @defaultUser@ | $sw/cut -d: -f7)
if [[ $# -gt 0 ]]; then
    # wsl seems to prefix with "-c"
    shift
    cmd="$@"
else
    cmd="$userShell"
fi

# store external environment but filter variables specific to current (root) user.
# systemd-run below will restore the current environment using this file.
env | $sw/grep -vE "^(HOME|LOGNAME|SHELL|USER)=" > /run/env.vars

exec $sw/nsenter -t $(< /run/systemd.pid) -p -m -- $sw/systemd-run \
    --uid=@defaultUser@ \
    --quiet \
    --collect \
    --wait \
    --pty \
    --working-directory="$PWD" \
    --property EnvironmentFile=/run/env.vars \
    /bin/sh -c "exec $cmd"
