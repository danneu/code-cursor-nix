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
    aarch64-darwin = fetchurl {
      url = "https://downloads.cursor.com/production/${commit}/darwin/arm64/Cursor-darwin-arm64.dmg";
      hash = "sha256-xEFVddQu4BwKCXECCOzMWTU6Jxg526TA18K/XA+n7JY=";
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
