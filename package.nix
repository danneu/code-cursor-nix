# Cursor Package for Nix
#
# AI-powered code editor built on VS Code.
# Packaged from AppImage for Linux systems.

{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  makeWrapper,
}:

let
  version = "2.1.36";
  commit = "9cd7c8b6cebcbccc1242df211dee45a4b6fe15e4";

  sources = {
    x86_64-linux = {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-aaprRB2BAaUCHj7m5aGacCBHisjN2pVZ+Ca3u1ifxBA=";
    };
    aarch64-linux = {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-S2vFYBI6m0zjBJEDbk7gc6/zFiKWyhM73OUm1xsNx6Q=";
    };
  };

  src = fetchurl {
    inherit (sources.${stdenv.hostPlatform.system}) url hash;
  };

  appimageContents = appimageTools.extract {
    pname = "cursor";
    inherit version src;
  };

in
appimageTools.wrapType2 {
  pname = "cursor";
  inherit version src;

  extraInstallCommands = ''
    # Install desktop file
    install -Dm444 ${appimageContents}/cursor.desktop $out/share/applications/cursor.desktop

    # Fix desktop file - update icon path to absolute path
    substituteInPlace $out/share/applications/cursor.desktop \
      --replace-fail 'Icon=co.anysphere.cursor' "Icon=$out/share/icons/hicolor/512x512/apps/cursor.png"

    # Install icon from AppImage root
    install -Dm444 "${appimageContents}/co.anysphere.cursor.png" "$out/share/icons/hicolor/512x512/apps/cursor.png"
  '';

  meta = with lib; {
    description = "Cursor - AI-powered code editor";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "cursor";
  };
}
