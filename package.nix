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
  version = "2.1.34";
  commit = "609c37304ae83141fd217c4ae638bf532185650f";

  sources = {
    x86_64-linux = {
      url = "https://downloads.cursor.com/production/${commit}/linux/x64/Cursor-${version}-x86_64.AppImage";
      hash = "sha256-NPs0P+cnPo3KMdezhAkPR4TwpcvIrSuoX+40NsKyfzA=";
    };
    aarch64-linux = {
      url = "https://downloads.cursor.com/production/${commit}/linux/arm64/Cursor-${version}-aarch64.AppImage";
      hash = "sha256-+bh6h/wDCZrfW3TALn96juNtr9Pd7CxwMc80ok3pq48=";
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
