{
    lib,
    pkgs,
    newScope,
}:

lib.makeScope newScope ( self: let

    callPackage = self.newScope {};

in {

    scriptMaker = ./script-maker.nix;

    rubyMiner = callPackage self.scriptMaker {
        shebangProgram = pkgs.tsuki.ruby.with_preferred_gems;
    };

    nix-update-driver = self.rubyMiner {
        path = ./nix-update-driver.rb;
        runtimeDeps = with pkgs; [ nix-update ];
    };

} )
