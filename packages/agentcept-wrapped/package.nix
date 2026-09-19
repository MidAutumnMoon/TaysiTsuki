{
    lib,
    makeBinaryWrapper,
    symlinkJoin,
    tsuki,
}:

let
    agentcept = lib.getOutput "agentcept" tsuki.inori;
    agentceptBin = lib.makeBinPath [ agentcept ];
    wrapped = {
        omp = tsuki.__pin.omp;
        zcode = tsuki.__pin.zcode;
    };

    wrapProgram = program: unwrapped: /* sh */ ''
        rm -v "$out/bin/${program}"
        makeBinaryWrapper "${lib.getExe' unwrapped program}" "$out/bin/${program}" \
            --prefix PATH : "${agentceptBin}"
    '';
in
symlinkJoin {

    name = "agentcept-wrapped";

    paths = builtins.attrValues wrapped;
    nativeBuildInputs = [ makeBinaryWrapper ];

    postBuild =
        wrapped
        |> lib.mapAttrsToList wrapProgram
        |> lib.concatStringsSep "\n";

    passthru = {
        inherit agentcept;
        unwrapped = wrapped;
    };

}
