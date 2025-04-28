{
    lib,
    fastfetch,
}:

lib.onceride fastfetch

{
    rpmSupport = false;
    vulkanSupport = false;
    waylandSupport = false;
    x11Support = false;
    flashfetchSupport = false;

    ddcutil = null;
    imagemagick = null;
    opencl-headers = null;
}

( old: {

    cmakeFlags = old.cmakeFlags ++ [
        (lib.cmakeBool "ENABLE_THREADS" true)
        (lib.cmakeBool "ENABLE_OPENCL" false)
        (lib.cmakeBool "ENABLE_IMAGEMAGICK7" false)
        (lib.cmakeBool "ENABLE_IMAGEMAGICK6" false)
    ];

} )
