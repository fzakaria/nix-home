let
  systems = {
    nyx = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOXmzOre8wnaZm4zXuXqzFRS+5GFlMyfhth9ie9AvW8t root@nyx";
    kuato = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWOYMWfn29KJeDGdDcsf22jOX9Xo1Z/hTBjolAxJesM root@kuato";
  };
  users = {
    fmzakari-yubikey = "age1yubikey1qg8nf40dfw4gprmywplggtg2wuvv55fcmujzrm65z8s3j6rhwje2vm3hhs7";
  };
  allUsers = builtins.attrValues users;
  allSystems = builtins.attrValues systems;
in {
  "nixbuild.key.age".publicKeys = allUsers ++ [systems.nyx];
  "tailscale.key.age".publicKeys = allUsers ++ [systems.kuato];
}
