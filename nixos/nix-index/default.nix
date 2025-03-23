{ pkgs, flakes, ... }:

let

    indexDb =
        import "${flakes.nix-index-database}/generated.nix"
        |> ( it:
            let system = pkgs.system; in
            pkgs.fetchurl {
                name = "nix-index-db-small-${system}";
                url = "${it.url}${system}-small";
                hash = it.hashes."${system}-small";
            } )
        |> ( it: it.overrideAttrs {
                __structuredAttrs = true;
                unsafeDiscardReferences."out" = true;
            } )
    ;

    nixLocate =
        pkgs.runCommand "nix-locate"
        { nativeBuildInputs = [ pkgs.buildPackages.makeBinaryWrapper ]; }
        ''
            mkdir -pv "$out/bin" "$out/db"
            # Idoit nix-locate looks for "files" under the specified
            # db path, what? What idoit designed the cli?
            cp -v "${indexDb}" "$out/db/files"
            cp -v "${pkgs.nix-index}/bin/nix-locate" "$out/bin"
            wrapProgram "$out/bin/nix-locate" \
                --set "NIX_INDEX_DATABASE" "${placeholder "out"}/db"
        ''
    ;

in {

    environment.systemPackages = [ nixLocate ];

    passthru = {
        inherit indexDb nixLocate;
    };

}
