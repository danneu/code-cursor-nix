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

  version = "2.1.49";
  commit = "21a2ed198584d56a91c0b996d1a09c93f8538440";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-o64V7fjbsqSR/S/7uviIKumCljjetwsYo3R3jzXz3cY=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-tPL2T1DRIXCwaIs59x2ZIpSg+vSAavH+6b/jRy291o8=";
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
