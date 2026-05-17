{ pkgs, ... }:

let

    llvm = pkgs.llvmPackages_latest;

in

{

    packages = with pkgs; [
        tsuki.rust.rust-analyzer
        tsuki.rust.toolchainForDev
        # for lld
        (llvm.clang.override { inherit (llvm) bintools; })
        llvm.lldb
        cargo-bloat
        cargo-outdated
        # cargo-llvm-cov
    ];

    envvars = {
        CARGO_HOME = "$XDG_DATA_HOME/cargo";
    };

}
