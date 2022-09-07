#!/usr/bin/env bash
set -euxo pipefail

mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc

exec systemd
