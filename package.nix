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

  version = "2.2.17";
  commit = "cf858ca030e9c9a99ea444ec6efcbcfc40bfda75";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-8TTNIGlatkHE8O87h8VGevjaiyWDR8qq8PA7l64Bijs=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-CVRjZFplTpJQ7gvL+S/1kTIdPT8+ZDQ+jfSMYy280BI=";
    };
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-Rs0olqE6SnN5GgTMPgzZ3D1gFnoCcpXZmcHrrwmwXS4=";
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
  linuxPackage = callPackage vscode-generic rec {
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
