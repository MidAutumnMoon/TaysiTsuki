{
    lib,
    tsuki,
}:

tsuki.rust.buildRustPackage rec {
    pname = "system76-scheduler-niri";
    version = "0.1.0";

    inherit (tsuki.workspace)
        src cargoLock;

    cargoBuildFlags = "-p ${pname}";
    doCheck = false;

    meta.mainProgram = "${pname}";
}
