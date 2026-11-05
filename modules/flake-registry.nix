# `dotfiles` in the user flake registry points at this checkout, so
# `nix flake init -t dotfiles#devshell` works. Written directly for the same
# reason as nix.conf (see nix.nix). git+file, so only tracked files count.
{ config, ... }:
{
  xdg.configFile."nix/registry.json".text = builtins.toJSON {
    version = 2;
    flakes = [
      {
        from = {
          type = "indirect";
          id = "dotfiles";
        };
        to = {
          type = "git";
          url = "file://${config.xdg.configHome}/home-manager";
        };
      }
    ];
  };
}
