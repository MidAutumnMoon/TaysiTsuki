{
    tsuki,
}:

tsuki.rust.buildRustPackage rec {
    pname = "package_maintenance";
    version = "0.1.0";

    inherit (tsuki.workspace)
        src cargoLock;

    cargoBuildFlags = "-p ${pname}";
    doCheck = false;

    meta.mainProgram = pname;
}
