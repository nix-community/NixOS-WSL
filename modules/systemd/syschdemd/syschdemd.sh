#!/usr/bin/env bash
set -euo pipefail

[ "${NIXOS_WSL_DEBUG:-}" == "1" ] && set -x

rundir="/run/nixos-wsl"
pidfile="$rundir/unshare.pid"

ensure_root() {
  if [ $EUID -ne 0 ]; then
    echo "[ERROR] Requires root! :( Make sure the WSL default user is set to root" >&2
    exit 1
  fi
}

activate() {
  mount --bind -o ro /nix/store /nix/store

  LANG="C.UTF-8" /nix/var/nix/profiles/system/activate
}

create_rundir() {
  if [ ! -d $rundir ]; then
    mkdir -p $rundir/ns
    touch $rundir/ns/{pid,mount}
  fi
}

is_unshare_alive() {
  [ -e $pidfile ] && [ -d "/proc/$(<$pidfile)" ]
}

run_in_namespace() {
  nsenter \
    --pid=$rundir/ns/pid \
    --mount=$rundir/ns/mount \
    -- "$@"
}

start_systemd() {
  mount --bind --make-private $rundir $rundir

  daemonize \
    -o $rundir/stdout \
    -e $rundir/stderr \
    -l $rundir/systemd.lock \
    -p $pidfile \
    -E LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive \
    "$(command -v unshare)" \
    --fork \
    --pid=$rundir/ns/pid \
    --mount=$rundir/ns/mount \
    --mount-proc=/proc \
    --propagation=unchanged \
    nixos-wsl-systemd-wrapper

  # Wait for systemd to start
  while ! (run_in_namespace systemctl is-system-running -q --wait) &>/dev/null; do
    sleep 1

    if ! is_unshare_alive; then
      echo "[ERROR] systemd startup failed!"

      echo "[ERROR] stderr:"
      cat $rundir/stderr

      echo "[ERROR] stdout:"
      cat $rundir/stdout

      exit 1
    fi
  done
}

get_shell() {
  getent passwd "$1" | cut -d: -f7
}

get_home() {
  getent passwd "$1" | cut -d: -f6
}

is_in_container() {
  [ "${INSIDE_NAMESPACE:-}" == "true" ]
}

clean_wslpath() {
  echo "$PATH" | tr ':' '\n' | grep -E "^@automountPath@" | tr '\n' ':'
}

main() {
  ensure_root

  if [ ! -e "/run/current-system" ]; then
    activate
  fi

  if [ ! -e "$rundir" ]; then
    create_rundir
  fi

  if ! is_in_container && ! is_unshare_alive; then
    start_systemd
  fi

  if [ $# -gt 1 ]; then # Ignore just -c without a command
    # wsl seems to prefix with "-c"
    shift
    command="$(get_shell @username@) -l -c \"$*\""
  else
    command="$(get_shell @username@) -l"
  fi

  # If we're executed from inside the container, e.g. sudo
  if is_in_container; then
    eval $command
  fi

  # If we are currently in /root, this is probably because the directory that WSL was started is inaccessible
  # cd to the user's home to prevent a warning about permission being denied on /root
  if [ "$PWD" == "/root" ]; then
    cd "$(get_home @username@)"
  fi

  # Pass external environment but filter variables specific to root user.
  exportCmd="$(export -p | grep -vE ' (HOME|LOGNAME|SHELL|USER)=')"

  run_in_namespace \
    systemd-run \
    --quiet \
    --collect \
    --wait \
    --pty \
    --service-type=exec \
    --setenv=INSIDE_NAMESPACE=true \
    --setenv=WSLPATH="$(clean_wslpath)" \
    --working-directory="$PWD" \
    --machine=.host \
    "$(which runuser)" --pty -u @username@ -- /bin/sh -c "$exportCmd; source /etc/set-environment; exec $command"
}

main "$@"
