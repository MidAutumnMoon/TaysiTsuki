{
    lib,
    tsuki,

    runCommandNoCC,

    liburing,
}:

let

    ruby = tsuki.ruby.override {
        moreGemsConfig = {
            io-event = _: { buildInputs = [ liburing ]; };
        };
    };

    buildGemset = gemset:
        ruby.buildGems gemset
        |> lib.attrValues
        |> lib.filter lib.isDerivation
        |> map ( g: g.override { document = [ "ri" ]; } )
        |> ( gems: ruby.withPackages( _: gems ) )
    ;

in {

    with_preferred_gems = buildGemset ./gemset.nix;

    rubocop = let
        r = buildGemset ./gemset-rubocop.nix;
    in runCommandNoCC "rubocop" {} ''
        mkdir -pv "$out/bin"
        ln -sv "${lib.getBin r}/bin/rubocop" "$out/bin/rubocop"
    '';

}
