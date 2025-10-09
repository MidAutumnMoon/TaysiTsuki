{
    lib,
    tsuki,
    par2cmdline-turbo,
}:

tsuki.rust.buildRustPackage {

    pname = "localbinbox";
    version = "0.1.0";

    src = with lib.fileset; toSource {
        root = ./.;
        fileset = gitTracked ./.;
    };

    nativeBuildInputs = [
        tsuki.hooks.prefixCommaToBin
    ];

    env = {
        CFG_PAR2 = lib.getExe' par2cmdline-turbo "par2";
    };

    cargoLock.lockFile = ./Cargo.lock;

}
