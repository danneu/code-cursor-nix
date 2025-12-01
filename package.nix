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

  version = "2.1.42";
  commit = "2e353c5f5b30150ff7b874dee5a87660693d9de6";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-UqHi9QlQSaOJZWW6bmElDrK5GaEGT3kU5LsXg2LUeHg=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-v7m9puw9xQKt36U8+m0n7sGmkoNkVjiDI+Wo6qaN64g=";
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
