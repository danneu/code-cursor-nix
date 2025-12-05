# code-cursor-nix

Nix flake for Cursor (AI code editor). Packages AppImage for Linux, .dmg for macOS.

## Structure

- `flake.nix` - flake outputs: packages, apps, overlay, devShell
- `package.nix` - derivation (AppImage on Linux, .dmg on Darwin)
- `.github/workflows/` - (TODO) automated version updates

## Version Info

`package.nix` requires both:

- `version` - semver (e.g., "2.1.49")
- `commit` - git commit hash from Cursor downloads

Sources fetched from:
- Linux: `https://downloads.cursor.com/production/${commit}/linux/{x64,arm64}/Cursor-${version}-{arch}.AppImage`
- Darwin: `https://downloads.cursor.com/production/${commit}/darwin/{arm64,x64}/Cursor-darwin-{arch}.dmg`

## Updating

Manual:

1. Find new version/commit from cursor.com downloads or release notes
   - Check: `curl -sIL "https://api2.cursor.sh/updates/download/golden/darwin-arm64/cursor/2.1" | grep location`
2. Update `version` and `commit` in `package.nix`
3. Get hashes for all 4 arches: `nix-prefetch-url <url>`
4. Convert to SRI: `nix hash convert --hash-algo sha256 --to sri <hash>`
5. Update `hash` fields
6. Test: `nix build && open result/Applications/Cursor.app` (macOS)

## Automation Plan

Model after github.com/sadjow/claude-code-nix:

- GitHub workflow on schedule (hourly cron)
- Check Cursor API/downloads for new version
- Auto-update `package.nix` with new version/commit/hashes
- Create PR, auto-merge on CI pass
- Push to Cachix for binary cache

Key difference: need to discover version+commit (not just npm version). May need to scrape cursor.com or check their API.

## Platforms

- Linux: x86_64-linux, aarch64-linux (AppImage)
- macOS: aarch64-darwin (Apple Silicon) (.dmg)

## Commands

```bash
nix build              # build package
nix run               # run cursor directly
nix develop           # dev shell with nixpkgs-fmt, nix-prefetch-url, cachix
```
