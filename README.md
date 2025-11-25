# code-cursor-nix

Always up-to-date Nix package for [Cursor](https://cursor.com) - the AI-powered code editor.

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

Use the included Home Manager module for declarative settings management.

The `~/.config/Cursor/User/settings.json` remains writable by Cursor.

- On first run: creates `~/.config/Cursor/User/settings.json` with your nix settings
- On rebuild: merges nix settings into existing file based on `mergeStrategy`

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

            # (Default) Existing keyvals in settings.json take precedence
            # mergeStrategy = "file-wins";

            # The keyvals here take precedence on collision with settings.json
            # mergeStrategy = "nix-wins";

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

nix run
```

## How Updates Work

This repository uses GitHub Actions to automatically check for new Cursor versions every hour:

1. Checks the Cursor download API for new versions
2. Creates a pull request with updated version and hashes
3. Builds and tests the package
4. Auto-merges if all checks pass

New Cursor versions are typically available in this flake within 1 hour of release.
