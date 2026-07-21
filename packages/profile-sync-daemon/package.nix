{
    lib,
    stdenvNoCC,
    fetchFromGitHub,
    makeWrapper,
    rsync,
    gawk,
    coreutils,
    util-linux,
    procps,
    fuse-overlayfs,
    fuse3,
    kmod,
}:

let
    runtimeDeps = [
        rsync
        fuse-overlayfs
        fuse3
        gawk
        coreutils
        util-linux
        procps
        kmod
    ];
in

stdenvNoCC.mkDerivation rec {
    pname = "profile-sync-daemon";
    version = "7.04";

    src = fetchFromGitHub {
        owner = "graysky2";
        repo = "profile-sync-daemon";
        rev = "v${version}";
        hash = "sha256-G2w5V9Eq19Jjx7PZcKH8bBZ3tOoghYaPQyMjlwFkARY=";
    };

    nativeBuildInputs = [ makeWrapper ];

    # make install builds common/profile-sync-daemon from .in as a dependency
    dontBuild = true;

    installPhase = ''
        # INIITDIR_SYSTEMD is hardcoded, substitute is the only option.
        substituteInPlace Makefile \
            --replace-fail \
                "INITDIR_SYSTEMD = /usr/lib/systemd/user" \
                "INITDIR_SYSTEMD = /lib/systemd/user"
        PREFIX="" DESTDIR="$out" make install

        # Patch hardcoded /usr/ paths to point into the store
        substituteInPlace "$out/bin/profile-sync-daemon" \
            --replace-fail "/usr/" "$out/"
        substituteInPlace "$out/bin/psd-suspend-sync" \
            --replace-fail "/usr/" "$out/"

        substituteInPlace "$out/lib/systemd/user/psd.service" \
            --replace-fail "/usr/bin/profile-sync-daemon" "$out/bin/profile-sync-daemon"
        substituteInPlace "$out/lib/systemd/user/psd-resync.service" \
            --replace-fail "/usr/bin/profile-sync-daemon" "$out/bin/profile-sync-daemon"
        # Half-hour interval timer
        substituteInPlace "$out/lib/systemd/user/psd-resync.timer" \
            --replace-fail "OnCalendar=hourly" "OnCalendar=*:00/30"

        # Wrap with runtime deps not guaranteed in user service PATH
        wrapProgram "$out/bin/profile-sync-daemon" \
            --prefix PATH : ${lib.makeBinPath runtimeDeps}
        wrapProgram "$out/bin/psd-suspend-sync" \
            --prefix PATH : ${lib.makeBinPath runtimeDeps}
    '';

    meta = {
        description = "Syncs browser profile dirs to tmpfs for speed and reduced disk wear";
        homepage = "https://github.com/graysky2/profile-sync-daemon";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
        mainProgram = "profile-sync-daemon";
    };
}
