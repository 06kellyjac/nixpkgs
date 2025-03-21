{
  stdenv,
  lib,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  qmake,
  qtbase,
  qtxmlpatterns,
  qttools,
  qtwebengine,
  libGL,
  fontconfig,
  openssl,
  poppler,
  wrapQtAppsHook,
  ffmpeg,
  libva,
  alsa-lib,
  SDL,
  x264,
  libvpx,
  libvorbis,
  libtheora,
  libogg,
  libopus,
  lame,
  fdk_aac,
  libass,
  quazip,
  libXext,
  libXfixes,
}:

let
  importer = stdenv.mkDerivation {
    pname = "openboard-importer";
    version = "unstable-2016-10-08";

    src = fetchFromGitHub {
      owner = "OpenBoard-org";
      repo = "OpenBoard-Importer";
      rev = "47927bda021b4f7f1540b794825fb0d601875e79";
      sha256 = "19zhgsimy0f070caikc4vrrqyc8kv2h6rl37sy3iggks8z0g98gf";
    };

    nativeBuildInputs = [ qmake ];
    buildInputs = [ qtbase ];
    dontWrapQtApps = true;

    installPhase = ''
      install -Dm755 OpenBoardImporter $out/bin/OpenBoardImporter
    '';
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "openboard";
  version = "1.7.3";

  src = fetchFromGitHub {
    owner = "OpenBoard-org";
    repo = "OpenBoard";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Igp5WSVQ9FrzS2AhDDPwVBo76SaFw9xP6lqgW7S/KIE=";
  };

  postPatch = ''
    substituteInPlace OpenBoard.pro \
      --replace-fail '/usr/include/quazip5' '${lib.getDev quazip}/include/QuaZip-Qt5-${quazip.version}/quazip' \
      --replace-fail '-lquazip5' '-lquazip1-qt5' \
      --replace-fail '/usr/include/poppler' '${lib.getDev poppler}/include/poppler'

    substituteInPlace resources/etc/OpenBoard.config \
      --replace-fail 'EnableAutomaticSoftwareUpdates=true' 'EnableAutomaticSoftwareUpdates=false' \
      --replace-fail 'EnableSoftwareUpdates=true' 'EnableAutomaticSoftwareUpdates=false' \
      --replace-fail 'HideCheckForSoftwareUpdate=false' 'HideCheckForSoftwareUpdate=true'
  '';

  nativeBuildInputs = [
    qmake
    copyDesktopItems
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtxmlpatterns
    qttools
    qtwebengine
    libGL
    fontconfig
    openssl
    poppler
    ffmpeg
    libva
    alsa-lib
    SDL
    x264
    libvpx
    libvorbis
    libtheora
    libogg
    libopus
    lame
    fdk_aac
    libass
    quazip
    libXext
    libXfixes
  ];

  propagatedBuildInputs = [ importer ];

  makeFlags = [ "release-install" ];

  desktopItems = [
    (makeDesktopItem {
      name = "OpenBoard";
      exec = "OpenBoard %f";
      icon = "OpenBoard";
      comment = "OpenBoard, an interactive white board application";
      desktopName = "OpenBoard";
      mimeTypes = [ "application/ubz" ];
      categories = [ "Education" ];
      startupNotify = true;
    })
  ];

  installPhase = ''
    runHook preInstall

    lrelease OpenBoard.pro

    # Replicated release_scripts/linux/package.sh
    mkdir -p $out/opt/openboard/i18n
    cp -R resources/customizations build/linux/release/product/* $out/opt/openboard/
    cp resources/i18n/*.qm $out/opt/openboard/i18n/
    install -m644 resources/linux/openboard-ubz.xml $out/opt/openboard/etc/
    install -Dm644 resources/images/OpenBoard.png $out/share/icons/hicolor/64x64/apps/OpenBoard.png

    runHook postInstall
  '';

  dontWrapQtApps = true;

  postFixup = ''
    makeWrapper $out/opt/openboard/OpenBoard $out/bin/OpenBoard \
      "''${qtWrapperArgs[@]}"
  '';

  meta = with lib; {
    description = "Interactive whiteboard application";
    homepage = "https://openboard.ch/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      atinba
      fufexan
    ];
    platforms = platforms.linux;
    mainProgram = "OpenBoard";
  };
})
