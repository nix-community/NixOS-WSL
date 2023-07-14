{ config, lib, writeText, toShellPath, shellOverride ? null, ... }:
writeText "passwd" (
  lib.concatStringsSep "\n" (
    map
      (user: "${user.name}:x:${toString user.uid}:${toString config.users.groups.${user.group}.gid}:${user.description}:${user.home}:${if shellOverride != null then shellOverride else toShellPath user.shell}}")
      (lib.attrValues config.users.users)
  )
)
