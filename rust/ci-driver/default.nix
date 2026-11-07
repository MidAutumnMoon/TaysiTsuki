{
    pkg-config,
    zstd,
    tsuki,
    workspace,
}:

tsuki.rust.buildRustPackage rec {
    pname = "ci-driver";
    version = "0.1.0";

    src = workspace.selectSrc [ "ci-driver" ];
    cargoLock = workspace.cargoLock;

    cargoBuildFlags = "-p ${pname}";
    doCheck = false;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ zstd ];

    meta.mainProgram = pname;
}
