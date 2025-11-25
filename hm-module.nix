# Home Manager module for Cursor
#
# Provides declarative settings management:
# - Creates default settings.json if it doesn't exist
# - Merges nix settings with existing file (strategy configurable)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.code-cursor;
  # jq merge: second argument wins on conflicts
  jqMergeExpr =
    if cfg.mergeStrategy == "nix-wins" then
      "'.[1] * .[0]'" # file first, then config overwrites
    else
      "'.[0] * .[1]'"; # config first, then file overwrites
in
{
  options.programs.code-cursor = {
    enable = mkEnableOption "Cursor editor with declarative settings";

    package = mkOption {
      type = types.package;
      default = pkgs.code-cursor;
      description = "The Cursor package to use";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Settings to merge into settings.json";
      example = literalExpression ''
        {
          "vim.useSystemClipboard" = true;
          "editor.fontSize" = 14;
          "editor.fontFamily" = "'JetBrains Mono', monospace";
          "workbench.colorTheme" = "Visual Studio Dark";
        }
      '';
    };

    mergeStrategy = mkOption {
      type = types.enum [
        "file-wins"
        "nix-wins"
      ];
      default = "file-wins";
      description = ''
        How to handle conflicts when merging deep-merging JSON settings:
        - "file-wins": existing settings.json values take precedence (default)
        - "nix-wins": nix config values take precedence
      '';
    };

    configDir = mkOption {
      type = types.str;
      default = "${config.xdg.configHome}/Cursor/User";
      description = "Path to Cursor's User config directory";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Create default settings on first run (doesn't overwrite existing)
    home.activation.codeCursorDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            SETTINGS_PATH="${cfg.configDir}/settings.json"
            if [ ! -f "$SETTINGS_PATH" ]; then
              $DRY_RUN_CMD mkdir -p "$(dirname "$SETTINGS_PATH")"
              $DRY_RUN_CMD cat > "$SETTINGS_PATH" <<'EOF'
      ${builtins.toJSON cfg.settings}
      EOF
            fi
    '';

    # Merge nix settings into existing file (existing settings win on conflicts)
    home.activation.codeCursorSettingsSync = lib.hm.dag.entryAfter [ "codeCursorDefaults" ] ''
            SETTINGS_PATH="${cfg.configDir}/settings.json"
            if [ -f "$SETTINGS_PATH" ] && [ ${builtins.toJSON (cfg.settings != { })} = "true" ]; then
              TEMP_FILE=$(${pkgs.coreutils}/bin/mktemp)
              cat > "$TEMP_FILE.defaults" <<'DEFAULTS_EOF'
      ${builtins.toJSON cfg.settings}
      DEFAULTS_EOF
              # Merge settings based on strategy
              $DRY_RUN_CMD ${pkgs.jq}/bin/jq -s ${jqMergeExpr} "$TEMP_FILE.defaults" "$SETTINGS_PATH" > "$TEMP_FILE"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TEMP_FILE" "$SETTINGS_PATH"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$TEMP_FILE.defaults"
            fi
    '';
  };
}
