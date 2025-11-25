# code-cursor-nix

Nix flake for Cursor (AI code editor). Packages AppImage for Linux.

## Structure

- `flake.nix` - flake outputs: packages, apps, overlay, devShell
- `package.nix` - derivation using appimageTools.wrapType2
- `.github/workflows/` - (TODO) automated version updates

## Version Info

`package.nix` requires both:

- `version` - semver (e.g., "2.1.34")
- `commit` - git commit hash from Cursor downloads

Sources fetched from: `https://downloads.cursor.com/production/${commit}/linux/{x64,arm64}/Cursor-${version}-{arch}.AppImage`

## Updating

Manual:

1. Find new version/commit from cursor.com downloads or release notes
2. Update `version` and `commit` in `package.nix`
3. Get hashes: `nix-prefetch-url <url>` for both arches
4. Update `hash` fields (SRI format: sha256-xxx)
5. Test: `nix build && ./result/bin/cursor --version`

## Automation Plan

Model after github.com/sadjow/claude-code-nix:

- GitHub workflow on schedule (hourly cron)
- Check Cursor API/downloads for new version
- Auto-update `package.nix` with new version/commit/hashes
- Create PR, auto-merge on CI pass
- Push to Cachix for binary cache

Key difference: need to discover version+commit (not just npm version). May need to scrape cursor.com or check their API.

## Platforms

Linux only: x86_64-linux, aarch64-linux (AppImage doesn't work on Darwin)

## Commands

```bash
nix build              # build package
nix run               # run cursor directly
nix develop           # dev shell with nixpkgs-fmt, nix-prefetch-url, cachix
```
