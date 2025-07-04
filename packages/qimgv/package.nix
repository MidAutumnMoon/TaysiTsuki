{
    lib,
    stdenv,
    fetchFromGitHub,
    cmake,
    pkg-config,
    qt6,
    opencv4,
}:

stdenv.mkDerivation rec {

    pname = "qimgv";
    version = "latest-dev-unstable-2025-03-03";

    src = fetchFromGitHub {
        owner = "easymodo";
        repo = pname;
        rev = "34f8b43ce2043e151df3e51d0cb9bff239f72a1b";
        sha256 = "sha256-3Z/1KwRb6z7vEwu1zloxceUs8yC5ETV4TO6zzxTbGsc=";
    };

    cmakeFlags = with lib; [
        ( cmakeBool "VIDEO_SUPPORT" false )
        ( cmakeBool "EXIV2" false )
    ];

    nativeBuildInputs = [
        cmake
        pkg-config
        qt6.wrapQtAppsHook
    ];

    buildInputs = [
        opencv4.cxxdev
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
