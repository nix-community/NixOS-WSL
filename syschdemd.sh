#! @shell@

set -e

sw="/nix/var/nix/profiles/system/sw/bin"
systemPath=`${sw}/readlink -f /nix/var/nix/profiles/system`

# Needs root to work
if [[ $EUID -ne 0 ]]; then
    exec @wrapperDir@/sudo "$0" -u "$UID" "$@"
fi

targetUid=$UID

while [ "$#" -gt 0 ]; do
    i="$1"; shift 1
    case "$i" in
        -u)
            targetUid=$1; shift 1
            ;;
        *)
            echo "$0: unknown option \`$i'"
            exit 1
            ;;
    esac
done

if [ ! -e "/run/current-system" ]; then
    ln -sfn "$(${sw}/readlink -f "$systemPath")" /run/current-system
fi

if [ ! -e "/run/systemd.pid" ]; then
    PATH=/run/current-system/systemd/lib/systemd:@fsPackagesPath@ \
        LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive \
        @daemonize@/bin/daemonize /run/current-system/sw/bin/unshare -fp --mount-proc systemd
    /run/current-system/sw/bin/pgrep -xf systemd > /run/systemd.pid
fi

if [ $UID -ne $targetUid ]; then
    exec @wrapperDir@/su -s @shell@ $(/run/current-system/sw/bin/id -un $targetUid)
else
    exec @shell@
fi
