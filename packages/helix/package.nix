{
    lib,
    stdenv,
    callPackage,

    tsuki,
    flakes,
}:

let
    src = flakes.helix-of-mine;

    # lastModifiedDate looks like "YYYYMMDDHHMMSS"
    version = "0-unstable-"
        + lib.substring 0 4 src.lastModifiedDate + "-"
        + lib.substring 4 2 src.lastModifiedDate + "-"
        + lib.substring 6 2 src.lastModifiedDate;

    unusedGrammars = [
        "verilog" "vhdl" "v"
        "julia" "nim" "crystal" "scala" "groovy"
        "lean" "agda" "slang" "ponylang" "ocaml" "ocaml-interface"
        "koto" "amber"
        "haskell" "perl"
    ];
in

(callPackage "${src}/default.nix" {
    rustPlatform = tsuki.rust;
    gitRev = src.rev or src.dirtyRev or null;
    includeGrammarIf = grammar: !builtins.elem grammar.name unusedGrammars;
}).overrideAttrs {
    name = "helix-${version}";
    RUSTFLAGS = with stdenv;
        lib.optional hostPlatform.isx86_64 "-Ctarget-cpu=x86-64-v3"
    ;
}
