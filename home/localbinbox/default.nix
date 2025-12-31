{
    lib,
    tsuki,
    par2cmdline-turbo,
}:

tsuki.rust.buildRustPackage rec {
    pname = "localbinbox";
    version = "0.1.0";

    inherit (tsuki.workspace)
        src cargoLock;

    nativeBuildInputs = [
        tsuki.hooks.prefixCommaToBin
    ];

    cargoBuildFlags = "-p ${pname}";
    doCheck = false;

    env = {
        CFG_PAR2 = lib.getExe' par2cmdline-turbo "par2";
    };
}
