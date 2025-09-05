{
    lib,
    stdenv,
    fetchFromGitHub,
    cmake,
    pkg-config,
    qt6,
}:

stdenv.mkDerivation rec {

    pname = "qimgv";
    version = "latest-dev-unstable-2025-09-05";

    src = fetchFromGitHub {
        owner = "easymodo";
        repo = pname;
        rev = "6bdfad1f47be2cd5eb54c6da45073f8eee55963f";
        sha256 = "sha256-OsPI9+lKZIRo7QhLwQ3qBs8cm6VwH6sePEH5KhUegVo=";
    };

    cmakeFlags = with lib; [
        ( cmakeBool "VIDEO_SUPPORT" false )
        ( cmakeBool "EXIV2" false )
        ( cmakeBool "USE_QT5" false )
        ( cmakeBool "OPENCV_SUPPORT" false )
    ];

    nativeBuildInputs = [
        cmake
        pkg-config
        qt6.wrapQtAppsHook
    ];

    buildInputs = [
        qt6.qtbase
        qt6.qtimageformats
        qt6.qtsvg
        qt6.qttools
    ];

    meta = with lib; {
        mainProgram = "qimgv";
        homepage = "https://github.com/easymodo/qimgv";
        license = licenses.gpl3;
        platforms = platforms.linux;
    };

}
