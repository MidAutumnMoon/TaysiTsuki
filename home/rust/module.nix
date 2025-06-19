{ pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.rust.rust-analyzer
        tsuki.rust.toolchainForDev
        # for lld
        ( clang.override { inherit ( llvmPackages ) bintools; } )
    ];

    envvars = {
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
    };

}
