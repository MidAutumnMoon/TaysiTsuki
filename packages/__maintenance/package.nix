{
    lib,
    tsuki,
}:

tsuki.rust.buildRustPackage rec {

    pname = "maintenance";
    version = "0.1.0";

    src = with lib.fileset; toSource {
        root = ./.;
        fileset = gitTracked ./.;
    };

    cargoLock.lockFile = ./Cargo.lock;
    meta.mainProgram = pname;

}
