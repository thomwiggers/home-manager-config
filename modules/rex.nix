# Rex (https://www.superlogical.com/rex), the terminal multiplexer, from its
# prebuilt flake: the package (unfree, allowed inside that flake), the
# xterm-rex terminfo entry in ~/.terminfo and the ssh guard, an Include at the
# top of ~/.ssh/config that announces xterm-256color to hosts without the
# entry.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.rex.homeManagerModules.default ];

  programs.rex.enable = true;

  # A personal server as a systemd user service, which lives until logout
  # unless `loginctl enable-linger` was run; it is never restarted by a
  # switch (`systemctl --user restart rex` picks up a new version). Not on
  # macOS, where the Rex app runs the server, and not under nix-user-chroot,
  # where systemd can't see /nix; there the first `rex` command starts one.
  services.rex.enable = lib.mkDefault (
    pkgs.stdenv.hostPlatform.isLinux && !config.thom.autoUpdate.nixUserChroot
  );
}
