# hm-update, and a daily job that runs it: a systemd user timer on Linux, a
# launchd agent on macOS. hm-update pulls with --ff-only and then switches
# only to the commit just fetched from upstream: it fails, without switching,
# on a dirty tree or unpushed local commits. Sandboxed Claude sessions may
# write the checkout, and the job must not activate their edits unsandboxed.
# On machines registered in machines/ the job reports to healthchecks.io
# through runitor, when the ping key is deployed (not with THOM_NO_SECRETS).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.thom.autoUpdate;

  home = config.home.homeDirectory;

  # hm-update: pull this repository and switch to it. Extra arguments go to
  # `home-manager switch`. The configuration is <user>@<role>: the role
  # registered in machines/<hostname -s>, else the one bootstrap.sh picks by
  # platform. Unregistered hosts (containers) need no entry.
  hmUpdate = pkgs.writeShellApplication {
    name = "hm-update";
    runtimeInputs = [ pkgs.git ];
    text = ''
      repo="${config.xdg.configHome}/home-manager"
      # No hooks or fsmonitor: .git is as writable as the tree.
      g() { git -C "$repo" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }
      g pull --ff-only
      host=$(uname -n)
      host=''${host%%.*}
      if [ -s "$repo/machines/$host" ]; then
        role=$(cat "$repo/machines/$host")
      else
        case "$(uname -s)/$(uname -m)" in
          Darwin/arm64) role=darwin ;;
          Linux/x86_64) role=linux ;;
          Linux/aarch64) role=linux-arm ;;
          *)
            echo "hm-update: unsupported platform; register it in machines/$host" >&2
            exit 1
            ;;
        esac
      fi
      flake="$repo#$(id -un)@$role"

      # Switch only to what upstream has: flakes build tracked files as they
      # are on disk (staged and `git add -N` files included, and files hidden
      # from status by skip-worktree/assume-unchanged).
      refuse() {
        echo "hm-update: $1 in $repo; not switching." >&2
        echo "Commit and push it, or test it with: home-manager switch --flake '$flake' -b hm-bak" >&2
        exit 1
      }
      # Assignments, so that a failing git fails the script.
      changes=$(g status --porcelain --untracked-files=no)
      [ -z "$changes" ] || refuse "uncommitted changes"
      flags=$(g ls-files -v)
      if grep -qv '^H ' <<<"$flags"; then
        refuse "files marked skip-worktree or assume-unchanged"
      fi
      upstream=$(g rev-parse --verify -q '@{u}') || refuse "no upstream branch"
      [ "$(g rev-parse HEAD)" = "$upstream" ] || refuse "HEAD is not the upstream commit"

      exec home-manager switch --flake "$flake" -b hm-bak "$@"
    '';
  };

  # The scheduled job: hm-update under runitor, which pings healthchecks.io
  # on start, success and failure (with the output). The key file holds the
  # project's ping key; runitor reads it itself (file:), so it never appears
  # on a command line. The check is created on first ping. Other hosts run
  # hm-update unreported.
  hmUpdateJob = pkgs.writeShellApplication {
    name = "hm-update-job";
    runtimeInputs = [ pkgs.runitor ];
    text = ''
      key="${home}/.config/runitor/hc_key"
      host=$(uname -n)
      host=''${host%%.*}
      # Registered machines only: a disposable host would leave a check
      # behind that alerts forever once the machine is gone.
      if [ -s "${config.xdg.configHome}/home-manager/machines/$host" ] && [ -r "$key" ] && [ -s "$key" ]; then
        # Slugs are lowercase.
        export PING_KEY="file:$key" CHECK_SLUG="hm-update-''${host,,}"
        exec runitor -create -- ${lib.getExe hmUpdate}
      fi
      exec ${lib.getExe hmUpdate}
    '';
  };

  # The units name the profile's hm-update-job, not its store path: a unit
  # that changes on every nixpkgs bump would be reloaded (and the running job
  # killed) by the very switch it started.
  job = "${config.home.profileDirectory}/bin/hm-update-job";
  path = lib.concatStringsSep ":" [
    "${config.home.profileDirectory}/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/bin"
    "/bin"
  ];

  # The chroot role has /nix only inside nix-user-chroot.
  command =
    if cfg.nixUserChroot then
      [
        "${home}/.local/bin/nix-user-chroot"
        "${home}/.nix"
        "/bin/sh"
        "-c"
        # No $ here: systemd would expand it in ExecStart.
        ". ${home}/.nix-profile/etc/profile.d/nix.sh && exec ${home}/.nix-profile/bin/hm-update-job"
      ]
    else
      [ job ];
in
{
  options.thom.autoUpdate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run hm-update daily, reporting to healthchecks.io.";
    };
    nixUserChroot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run hm-update inside nix-user-chroot (chroot role).";
    };
  };

  config = lib.mkMerge [
    {
      home.packages = [
        hmUpdate
        hmUpdateJob
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
