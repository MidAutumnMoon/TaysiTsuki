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
    version = "latest-dev-unstable-2025-07-21";

    src = fetchFromGitHub {
        owner = "easymodo";
        repo = pname;
        rev = "a8e335b75b0767fd2ea2e1c9145f89a866d002b2";
        sha256 = "sha256-JOfHFgdSvEMvCTzUwfVMnasBHZfRFFDq2W2s9KeRAxU=";
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
