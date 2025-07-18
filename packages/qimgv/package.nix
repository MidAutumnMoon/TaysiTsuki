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
    version = "latest-dev-unstable-2025-07-16";

    src = fetchFromGitHub {
        owner = "easymodo";
        repo = pname;
        rev = "dfa2c87d5ff91faf9d086cd14053b58918edef10";
        sha256 = "sha256-6l2+j8NQwmEfYeEstDab6+s+QiVjeLHsKJPXo7flgPo=";
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
