# Cursor Package for Nix
#
# AI-powered code editor built on VS Code.
# Uses vscode-generic like nixpkgs does.

{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  appimageTools,
  vscode-generic,
}:

let
  inherit (stdenv) hostPlatform;

  version = "2.1.39";
  commit = "60d42bed27e5775c43ec0428d8c653c49e58e26a";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-SsKhW8q/AzOn1HqykhwaVHyTVm+OqTUiFtda7XDiAho=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-m0QNf/ock6hRkOJXqMACBV6mM6/6ZAD6/yues9hGCfU=";
    };
  };

  source = sources.${hostPlatform.system};
in
callPackage vscode-generic rec {
  pname = "cursor";
  inherit version;

  executableName = "cursor";
  longName = "Cursor";
  shortName = "cursor";
  libraryName = "cursor";
  iconName = "cursor";

  commandLineArgs = "--update=false";

  src = appimageTools.extract {
    inherit pname version;
    src = source;
  };

  sourceRoot = "${pname}-${version}-extracted/usr/share/cursor";

  tests = { };
  updateScript = null;

  useVSCodeRipgrep = false;
  patchVSCodePath = false;

  meta = {
    description = "Cursor - AI-powered code editor";
    homepage = "https://cursor.com";
    license = lib.licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "cursor";
  };
}
