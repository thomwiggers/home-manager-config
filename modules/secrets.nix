# age-encrypted files, decrypted into $HOME at activation.
#
# Not sops-nix/agenix: the identity is a post-quantum (mlkem768x25519) age
# key, which needs age >= 1.3, and agenix's Home Manager module relies on a
# systemd user service that nix-user-chroot and containers don't have. The
# ciphertext lands in the Nix store; plaintext only ever exists in $HOME.
#
# The targets written are recorded in a state file, so plaintext of a secret
# that is no longer declared is removed on the next activation.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.thom.age;
  home = config.home.homeDirectory;

  stateFile = "${config.xdg.stateHome}/thom-age/targets";
  targetPath = secret: "${home}/${secret.target}";

  decryptOne = name: secret: ''
    thomDecrypt ${lib.escapeShellArg (targetPath secret)} ${secret.mode} ${secret.file}
  '';
in
{
  options.thom.age = {
    identity = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.configHome}/age/keys.txt";
      description = "age identity used to decrypt secrets (created by bootstrap.sh).";
    };

    secrets = lib.mkOption {
      default = { };
      description = "Encrypted files to decrypt into the home directory.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            file = lib.mkOption {
              type = lib.types.path;
              description = "The .age file in this repository.";
            };
            target = lib.mkOption {
              type = lib.types.str;
              description = "Destination, relative to the home directory.";
            };
            mode = lib.mkOption {
              type = lib.types.str;
              default = "0600";
            };
          };
        }
      );
    };
  };

  # Not conditional on any secrets being declared: removing the last one must
  # still clean up its plaintext.
  config = {
    home.activation.decryptSecrets = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      thomDecrypt() {
        local target="$1" mode="$2" src="$3" tmp
        if [[ -v DRY_RUN ]]; then
          echo "would decrypt $src -> $target"
          return
        fi
        (umask 077 && mkdir -p "$(dirname "$target")")
        tmp=$(umask 077 && mktemp "$target.XXXXXX")
        if ${lib.getExe pkgs.age} --decrypt --identity ${lib.escapeShellArg cfg.identity} --output "$tmp" "$src"; then
          chmod "$mode" "$tmp"
          mv -f "$tmp" "$target"
        else
          rm -f "$tmp"
          errorEcho "Failed to decrypt $src"
        fi
      }

      # Remove targets listed by the previous activation that are no longer
      # declared, then record the declared ones. Only paths from the state
      # file are ever deleted, and only regular files: a symlink there now
      # belongs to Home Manager (linkGeneration ran first).
      thomCleanup() {
        local state="$1" old tmp
        shift
        local -A declared=()
        for old in "$@"; do declared[$old]=1; done
        if [[ -f $state ]]; then
          while IFS= read -r old; do
            [[ -n $old && -z ''${declared[$old]-} ]] || continue
            [[ -f $old && ! -L $old ]] || continue
            if [[ -v DRY_RUN ]]; then
              echo "would remove undeclared secret $old"
            else
              verboseEcho "Removing undeclared secret $old"
              rm -f -- "$old"
            fi
          done < "$state"
        fi
        if [[ -v DRY_RUN ]]; then
          return
        fi
        (umask 077 && mkdir -p "$(dirname "$state")")
        tmp=$(umask 077 && mktemp "$state.XXXXXX")
        if (( $# )); then printf '%s\n' "$@" > "$tmp"; fi
        mv -f "$tmp" "$state"
      }

      # Without the key, leave everything (old plaintext included) alone.
      if [[ ! -r ${lib.escapeShellArg cfg.identity} ]]; then
        :
        ${lib.optionalString (cfg.secrets != { }) ''
          warnEcho "age identity ${cfg.identity} not found; skipping secrets (run bootstrap.sh)"
        ''}
      else
      ${lib.concatStrings (lib.mapAttrsToList decryptOne cfg.secrets)}
        thomCleanup ${lib.escapeShellArg stateFile} ${
          lib.concatMapStringsSep " " (s: lib.escapeShellArg (targetPath s)) (lib.attrValues cfg.secrets)
        }
      fi
      unset -f thomDecrypt thomCleanup
    '';
  };
}
