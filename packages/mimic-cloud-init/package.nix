{
    lib,
    tsuki,
}:

tsuki.rust.buildRustPackage {

    pname = "mimic-cloud-init";
    version = "0.1.0";

    src = with lib.fileset; toSource {
        root = ./.;
        fileset = gitTracked ./.;
    };

    cargoLock.lockFile = ./Cargo.lock;
    meta.mainProgram = "mimic-cloud-init";

}
