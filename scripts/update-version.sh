#!/usr/bin/env bash
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly CURSOR_API_URL="https://api2.cursor.sh/updates/download/golden"

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

get_current_version() {
  sed -n 's/.*version = "\([^"]*\)".*/\1/p' package.nix | head -1 || echo "unknown"
}

get_current_commit() {
  sed -n 's/.*commit = "\([^"]*\)".*/\1/p' package.nix | head -1 || echo "unknown"
}

# Get the latest download URL from Cursor API (follows redirect)
get_latest_download_url() {
  local arch="$1"
  curl -sIL -o /dev/null -w '%{url_effective}' "${CURSOR_API_URL}/linux-${arch}/cursor/latest"
}

# Extract version from download URL
# URL format: https://downloads.cursor.com/production/COMMIT/linux/ARCH/Cursor-VERSION-ARCH.AppImage
extract_version_from_url() {
  local url="$1"
  echo "$url" | sed 's/.*Cursor-\([0-9.]*\)-.*/\1/'
}

# Extract commit from download URL
extract_commit_from_url() {
  local url="$1"
  echo "$url" | sed 's|.*/production/\([^/]*\)/.*|\1|'
}

fetch_appimage_hash() {
  local url="$1"
  local hash
  hash=$(nix-prefetch-url "$url" 2>/dev/null | tail -1)
  # Convert to SRI format
  nix hash to-sri --type sha256 "$hash" 2>/dev/null || nix hash convert --type sha256 --to sri "$hash" 2>/dev/null
}

update_package_version() {
  local version="$1"
  sed -i.bak "s/version = \"[^\"]*\"/version = \"$version\"/" package.nix
}

update_package_commit() {
  local commit="$1"
  sed -i.bak "s/commit = \"[^\"]*\"/commit = \"$commit\"/" package.nix
}

update_package_hash() {
  local arch="$1"
  local hash="$2"

  case "$arch" in
    x64)
      sed -i.bak "/x86_64-linux/,/};/s|hash = \"[^\"]*\"|hash = \"$hash\"|" package.nix
      ;;
    arm64)
      sed -i.bak "/aarch64-linux/,/};/s|hash = \"[^\"]*\"|hash = \"$hash\"|" package.nix
      ;;
    darwin-arm64)
      sed -i.bak "/aarch64-darwin/,/};/s|hash = \"[^\"]*\"|hash = \"$hash\"|" package.nix
      ;;
  esac
}

cleanup_backup_files() {
  rm -f package.nix.bak
}

update_to_version() {
  local new_version="$1"
  local new_commit="$2"

  log_info "Updating to version $new_version (commit: $new_commit)..."

  # Update version and commit in package.nix
  update_package_version "$new_version"
  update_package_commit "$new_commit"

  # Fetch and update x64 hash
  log_info "Fetching x86_64 AppImage hash..."
  local x64_url="https://downloads.cursor.com/production/${new_commit}/linux/x64/Cursor-${new_version}-x86_64.AppImage"
  local x64_hash
  x64_hash=$(fetch_appimage_hash "$x64_url")
  if [ -z "$x64_hash" ]; then
    log_error "Failed to fetch x86_64 hash"
    mv package.nix.bak package.nix
    exit 1
  fi
  log_info "x86_64 hash: $x64_hash"
  update_package_hash "x64" "$x64_hash"

  # Fetch and update arm64 hash
  log_info "Fetching aarch64 AppImage hash..."
  local arm64_url="https://downloads.cursor.com/production/${new_commit}/linux/arm64/Cursor-${new_version}-aarch64.AppImage"
  local arm64_hash
  arm64_hash=$(fetch_appimage_hash "$arm64_url")
  if [ -z "$arm64_hash" ]; then
    log_error "Failed to fetch aarch64 hash"
    mv package.nix.bak package.nix
    exit 1
  fi
  log_info "aarch64 hash: $arm64_hash"
  update_package_hash "arm64" "$arm64_hash"

  # Fetch and update darwin arm64 hash
  log_info "Fetching darwin arm64 DMG hash..."
  local darwin_arm64_url="https://downloads.cursor.com/production/${new_commit}/darwin/arm64/Cursor-darwin-arm64.dmg"
  local darwin_arm64_hash
  darwin_arm64_hash=$(fetch_appimage_hash "$darwin_arm64_url")
  if [ -z "$darwin_arm64_hash" ]; then
    log_error "Failed to fetch darwin arm64 hash"
    mv package.nix.bak package.nix
    exit 1
  fi
  log_info "darwin arm64 hash: $darwin_arm64_hash"
  update_package_hash "darwin-arm64" "$darwin_arm64_hash"

  cleanup_backup_files

  log_info "Verifying build..."
  if nix build .#code-cursor --no-link >/dev/null 2>&1; then
    log_info "Build successful!"
    return 0
  else
    log_error "Build verification failed"
    return 1
  fi
}

ensure_in_repository_root() {
  if [ ! -f "flake.nix" ] || [ ! -f "package.nix" ]; then
    log_error "flake.nix or package.nix not found. Please run this script from the repository root."
    exit 1
  fi
}

ensure_required_tools_installed() {
  command -v nix >/dev/null 2>&1 || {
    log_error "nix is required but not installed."
    exit 1
  }
  command -v nix-prefetch-url >/dev/null 2>&1 || {
    log_error "nix-prefetch-url is required but not installed."
    exit 1
  }
  command -v curl >/dev/null 2>&1 || {
    log_error "curl is required but not installed."
    exit 1
  }
}

print_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --check           Only check for updates, don't apply"
  echo "  --help            Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                    # Update to latest version"
  echo "  $0 --check            # Check if update is available"
}

main() {
  local check_only=false

  while [[ $# -gt 0 ]]; do
    case $1 in
    --check)
      check_only=true
      shift
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      print_usage
      exit 1
      ;;
    esac
  done

  ensure_in_repository_root
  ensure_required_tools_installed

  local current_version
  current_version=$(get_current_version)

  # Get latest version from Cursor API
  log_info "Checking for updates..."
  local download_url
  download_url=$(get_latest_download_url "x64")
  local latest_version
  latest_version=$(extract_version_from_url "$download_url")
  local latest_commit
  latest_commit=$(extract_commit_from_url "$download_url")

  log_info "Current version: $current_version"
  log_info "Latest version: $latest_version"

  if [ "$current_version" = "$latest_version" ]; then
    log_info "Already up to date!"
    exit 0
  fi

  # Compare versions to prevent downgrades
  # Sort versions and check if latest is actually newer
  newer_version=$(printf '%s\n%s\n' "$current_version" "$latest_version" | sort -V | tail -1)
  if [ "$newer_version" = "$current_version" ]; then
    log_info "Latest version ($latest_version) is not newer than current ($current_version). Skipping."
    exit 0
  fi

  if [ "$check_only" = true ]; then
    log_info "Update available: $current_version -> $latest_version"
    exit 1 # Exit with non-zero to indicate update is available
  fi

  update_to_version "$latest_version" "$latest_commit"

  log_info "Successfully updated code-cursor from $current_version to $latest_version"

  # Update flake.lock
  log_info "Updating flake.lock..."
  nix flake update

  # Show changes
  echo ""
  log_info "Changes made:"
  git diff --stat package.nix flake.lock 2>/dev/null || true
}

main "$@"
