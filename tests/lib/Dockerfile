FROM scratch
ADD nixos-wsl-tarball.tar.gz /
CMD [ \
  "/bin/sh", \
  "-c", \
  "export PATH=/nix/var/nix/profiles/system/sw/bin && mkdir -p /run && mount --bind /run /run && mount --make-shared /run && /bin/sh" \
  ]
