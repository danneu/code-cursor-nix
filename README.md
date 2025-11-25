# code-cursor-nix

Always up-to-date Nix package for [Cursor](https://cursor.com) - the AI-powered code editor.

This was mostly vibe-coded using <https://github.com/sadjow/claude-code-nix> as reference.

**Automatically updated hourly** to check for a new Cursor release.

## Why this package?

- `code-cursor` in nixpkgs is always very out of date.
- The other projects that try to offer automatic Cursor updates for Nix seem unmaintained or too complicated.

| Feature              | nixpkgs                | This Flake              |
| -------------------- | ---------------------- | ----------------------- |
| **Update frequency** | Delayed (days/weeks)   | Hourly automated checks |
| **Platforms**        | x86_64 + aarch64 Linux | x86_64 + aarch64 Linux  |

## Quick Start

### Run directly (try it now!)

```bash
nix run github:danneu/code-cursor-nix
```

## Integration

### Using Nix Flakes

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    code-cursor.url = "github:danneu/code-cursor-nix";
  };

  outputs = { self, nixpkgs, code-cursor, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [ code-cursor.overlays.default ];
          environment.systemPackages = [ pkgs.code-cursor ];
        }
      ];
    };
  };
}
```

### Using Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    code-cursor.url = "github:danneu/code-cursor-nix";
  };

  outputs = { self, nixpkgs, home-manager, code-cursor, ... }: {
    homeConfigurations."username" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ code-cursor.overlays.default ];
      };
      modules = [
        ({ pkgs, ... }: {
          home.packages = [ pkgs.code-cursor ];
        })
      ];
    };
  };
}
```

### With VS Code Extensions

Use `programs.vscode` to declaratively manage extensions (works with any VS Code-compatible extensions):

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    code-cursor.url = "github:danneu/code-cursor-nix";
  };

  outputs = { self, nixpkgs, home-manager, code-cursor, ... }: {
    homeConfigurations."username" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ code-cursor.overlays.default ];
      };
      modules = [
        ({ pkgs, ... }: {
          programs.vscode = {
            enable = true;
            package = pkgs.code-cursor;
            profiles.default.extensions = with pkgs.vscode-extensions; [
              vscodevim.vim
              jnoortheen.nix-ide
              mads-hartmann.bash-ide-vscode
              golang.go
              rust-lang.rust-analyzer
              esbenp.prettier-vscode
            ];
          };
        })
      ];
    };
  };
}
```

### With Declarative Settings (Home Manager Module)

Use the included Home Manager module for declarative settings management. Settings defined in Nix are deep-merged into your existing `settings.json` where key/vals that exist in the file take precedence over key/vals in your Nix config.

This is so that you can define a settings baseline in your Nix config and then overwrite it with the Cursor settings GUI.

The `~/.config/Cursor/User/settings.json` remains writable by Cursor.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    code-cursor.url = "github:danneu/code-cursor-nix";
  };

  outputs = { self, nixpkgs, home-manager, code-cursor, ... }: {
    homeConfigurations."username" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ code-cursor.overlays.default ];
      };
      modules = [
        code-cursor.homeManagerModules.default
        {
          programs.code-cursor = {
            enable = true;
            settings = {
              "vim.useSystemClipboard" = true;
              "editor.fontSize" = 14;
              "editor.fontFamily" = "'JetBrains Mono', monospace";
              "editor.formatOnSave" = true;
              "editor.formatOnPaste" = true;
              "editor.minimap.enabled" = true;
              "workbench.colorTheme" = "Visual Studio Dark";
            };
          };
        }
      ];
    };
  };
}
```

**How it works:**

- On first run: creates `~/.config/Cursor/User/settings.json` with your nix settings
- On rebuild: merges nix settings into existing file (your manual edits win on conflicts)

## Development

```bash
# Clone the repository
git clone https://github.com/danneu/code-cursor-nix
cd code-cursor-nix

# Build the package
nix build

# Check for version updates
./scripts/update-version.sh --check

# Update to latest version
./scripts/update-version.sh

# Enter development shell
nix develop
```

## How Updates Work

This repository uses GitHub Actions to automatically check for new Cursor versions every hour:

1. Checks the Cursor download API for new versions
2. Creates a pull request with updated version and hashes
3. Builds and tests the package
4. Auto-merges if all checks pass

New Cursor versions are typically available in this flake within 1 hour of release.

### Testing the Auto-Update Workflow

```bash
# Manually trigger the workflow
gh workflow run "Update Cursor Version"

# List recent runs
gh run list --workflow="update-cursor.yml"

# View a specific run's summary
gh run view <run-id>

# View full logs
gh run view <run-id> --log

# Check if a PR was created (only happens when update is available)
gh pr list
```

If already on the latest version, the workflow will show "Already up to date!" and no PR is created.

## Troubleshooting

### GPU/Display Issues

Cursor is an Electron app that may have GPU rendering issues on some NixOS setups. Common fixes:

```bash
# Try running with software rendering
cursor --disable-gpu

# Or use nixGL wrapper
nix run nixpkgs#nixgl.nixGLIntel -- cursor
```

### Blank Window on Launch

If Cursor shows a blank window:

1. Try `cursor --disable-gpu`
2. Check your graphics drivers
3. Try running through nixGL

## Technical Details

### Package Architecture

- **AppImage packaging**: Uses `appimageTools.wrapType2` for proper FHS environment
- **Multi-arch support**: Both x86_64 and aarch64 Linux
- **Desktop integration**: Includes desktop file and icons

### Supported Platforms

- `x86_64-linux`
- `aarch64-linux`

Note: macOS is not supported as Cursor distributes AppImages for Linux only. On macOS, use the official Cursor installer.

## License

The Nix packaging is MIT licensed. Cursor itself is proprietary software.
