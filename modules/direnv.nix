# direnv with nix-direnv (cached `use flake`).
{ pkgs, ... }:
{
  # Silence direnv's log (errors too); starship's direnv module shows the
  # state instead.
  home.sessionVariables.DIRENV_LOG_FORMAT = "";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # thom-container mounts every project at /project.
    config.whitelist.prefix = [ "/project" ];
    # Keep each project's layout (nix-direnv's flake-profile-* and GC roots)
    # in this machine's cache instead of ./.direnv, so machines syncing the
    # same project folder don't overwrite each other's caches.
    stdlib = ''
      direnv_layout_dir() {
        echo "''${XDG_CACHE_HOME:-$HOME/.cache}/direnv/layouts/$(printf %s "$PWD" | ${pkgs.coreutils}/bin/sha1sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
      }
    '';
  };
}
