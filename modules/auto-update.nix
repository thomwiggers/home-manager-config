# hm-update, and a daily job that runs it: a systemd user timer on Linux, a
# launchd agent on macOS. The job pulls with --ff-only, so a checkout with
# local commits or a dirty tree that blocks the merge is left alone.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.thom.autoUpdate;

  # The units name the profile's hm-update, not its store path: a unit that
  # changes on every nixpkgs bump would be reloaded (and the running job
  # killed) by the very switch it started.
  hmUpdate = "${config.home.profileDirectory}/bin/hm-update";
  path = lib.concatStringsSep ":" [
    "${config.home.profileDirectory}/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/bin"
    "/bin"
  ];

  home = config.home.homeDirectory;

  # The chroot role has /nix only inside nix-user-chroot.
  command =
    if cfg.nixUserChroot then
      [
        "${home}/.local/bin/nix-user-chroot"
        "${home}/.nix"
        "/bin/sh"
        "-c"
        # No $ here: systemd would expand it in ExecStart.
        ". ${home}/.nix-profile/etc/profile.d/nix.sh && exec ${home}/.nix-profile/bin/hm-update"
      ]
    else
      [ hmUpdate ];
in
{
  options.thom.autoUpdate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run hm-update daily.";
    };
    nixUserChroot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run hm-update inside nix-user-chroot (chroot role).";
    };
  };

  config = lib.mkMerge [
    {
      # hm-update: pull this repository and switch to it. Extra arguments go
      # to `home-manager switch`.
      home.packages = [
        (pkgs.writeShellApplication {
          name = "hm-update";
          runtimeInputs = [ pkgs.git ];
          text = ''
            git -C "${config.xdg.configHome}/home-manager" pull --ff-only
            exec home-manager switch -b hm-bak "$@"
          '';
        })
      ];
    }

    (lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
      systemd.user.services.hm-update = {
        Unit.Description = "Pull ~/.config/home-manager and switch";
        Service = {
          Type = "oneshot";
          Environment = [ "PATH=${path}" ];
          ExecStart = lib.escapeShellArgs command;
        };
      };
      systemd.user.timers.hm-update = {
        Unit.Description = "Daily home-manager switch";
        Timer = {
          OnCalendar = "04:00";
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })

    (lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      # Missed runs (asleep at 04:00) fire on wake.
      launchd.agents.hm-update = {
        enable = true;
        config = {
          ProgramArguments = command;
          StartCalendarInterval = [
            {
              Hour = 4;
              Minute = 0;
            }
          ];
          EnvironmentVariables.PATH = path;
          ProcessType = "Background";
          LowPriorityIO = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/hm-update.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/hm-update.log";
        };
      };
    })
  ];
}
