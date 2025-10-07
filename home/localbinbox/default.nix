{
    lib,
    tsuki,
}:

tsuki.rust.buildRustPackage {

    pname = "localbinbox";
    version = "0.1.0";

    src = with lib.fileset; toSource {
        root = ./.;
        fileset = gitTracked ./.;
    };

    cargoLock.lockFile = ./Cargo.lock;

}
