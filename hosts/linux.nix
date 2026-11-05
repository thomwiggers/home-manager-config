# x86_64 Linux with a system-wide (daemon) Nix install: Incus/LXC
# containers (e.g. `development`) and VMs alike.
{ ... }:
{
  imports = [ ../modules/linux.nix ];
}
