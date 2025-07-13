{
    lib,
    strawberry,
}:

lib.onceride strawberry

{
    chromaprint = null;
    libgpod = null;
    libmtp = null;
    rapidjson = null;
    libcdio = null;
    libpulseaudio = null;
    libXdmcp = null;
    libselinux = null;
    libsepol = null;
    p11-kit = null;
}

( old: {

    cmakeFlags = with lib; [
        ( cmakeBool "ENABLE_SONGFINGERPRINTING" false )
        ( cmakeBool "ENABLE_MUSICBRAINZ" false )
        ( cmakeBool "ENABLE_AUDIOCD" false )
        ( cmakeBool "ENABLE_MTP" false )
        ( cmakeBool "ENABLE_GPOD" false )
        ( cmakeBool "ENABLE_TRANSLATIONS" false )
        ( cmakeBool "ENABLE_TIDAL" false )
        ( cmakeBool "ENABLE_SPOTIFY" false )
        ( cmakeBool "ENABLE_QOBUZ" false )
        ( cmakeBool "ENABLE_DISCORD_RPC" false )
        ( cmakeBool "ENABLE_UDISKS2" false )
        ( cmakeBool "ENABLE_X11_GLOBALSHORTCUTS" false )
        ( cmakeBool "ENABLE_PULSE" false )
    ];

} )
