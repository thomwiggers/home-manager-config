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

  # A personal server as a systemd user service; it is never restarted by a
  # switch (`systemctl --user restart rex` picks up a new version). Not on
  # macOS, where the Rex app runs the server, and not under nix-user-chroot,
  # where systemd can't see /nix; there the first `rex` command starts one.
  services.rex.enable = lib.mkDefault (
    pkgs.stdenv.hostPlatform.isLinux && !config.thom.autoUpdate.nixUserChroot
  );

  # Without lingering the user manager, and with it the server and every
  # session, stops at logout. Enabling it for yourself needs logind and
  # polkit; where that fails (some containers) the switch carries on. The
  # module's own linger warning can't tell and is still printed.
  home.activation.rexEnableLinger = lib.mkIf config.services.rex.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [[ ! -e /var/lib/systemd/linger/$USER ]]; then
        run ${lib.getExe' pkgs.systemd "loginctl"} enable-linger \
          || warnEcho "rex: could not enable lingering; run 'loginctl enable-linger' yourself"
      fi
    ''
  );
}
