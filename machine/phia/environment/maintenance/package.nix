{
    lib,
    tsuki,
    rclone,
}:

tsuki.rust.buildRustPackage rec {

    pname = "maintenance";
    version = "0.1.0";

    src = with lib.fileset; toSource {
        root = ./.;
        fileset = gitTracked ./.;
    };

    nativeBuildInputs = [
        tsuki.hooks.prefixCommaToBin
    ];

    env.CFG_RCLONE_PATH = lib.getExe rclone;

    cargoLock.lockFile = ./Cargo.lock;
    meta.mainProgram = pname;

}
