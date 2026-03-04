# Cursor Package for Nix
#
# AI-powered code editor built on VS Code.
# Linux: Uses vscode-generic with AppImage extraction
# Darwin: Installs .dmg as macOS app bundle

{
  lib,
  stdenv,
  callPackage,
  fetchurl,
  appimageTools,
  vscode-generic,
  undmg,
}:

let
  inherit (stdenv) hostPlatform;

  version = "2.6.11";
  commit = "8c95649f251a168cc4bb34c89531fae7db4bd992";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-VLWS2AT/tfKUkbrFCQcD66ulmk8ItlOOSuqdU+YJNNc=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-XB+eEDWZHFz4rmAWNCjkE6qgFMCVfpEHTZXVQJIrwsQ=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-AO0cfUS9fALDtGvQl1TgEeNVJxMlNROnYmsmdYmFgLk=";
    };
  };

  source = sources.${hostPlatform.system} or (throw "Unsupported system: ${hostPlatform.system}");

  # Darwin-specific derivation
  darwinPackage = stdenv.mkDerivation {
    pname = "cursor";
    inherit version;

    src = source;

    nativeBuildInputs = [ undmg ];

    sourceRoot = "Cursor.app";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications/Cursor.app
      cp -R . $out/Applications/Cursor.app

      # Symlink to the app's internal CLI which handles paths correctly
      mkdir -p $out/bin
      ln -s "$out/Applications/Cursor.app/Contents/Resources/app/bin/cursor" "$out/bin/cursor"

      runHook postInstall
    '';

    meta = {
      description = "Cursor - AI-powered code editor";
      homepage = "https://cursor.com";
      license = lib.licenses.unfree;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "cursor";
    };
  };

  # Linux-specific derivation using vscode-generic
  # vscode-generic is a curried function: outer takes deps, inner takes package attrs
  linuxPackage = (callPackage vscode-generic { }) rec {
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
  };
in
if hostPlatform.isDarwin then darwinPackage else linuxPackage
