#!/usr/bin/env bash
set -euxo pipefail

if grep -q binfmt_misc /proc/filesystems; then
  mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
fi

exec systemd
