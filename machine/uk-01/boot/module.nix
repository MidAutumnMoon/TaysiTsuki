{ pkgs, ... }:

{

    boot = {
        loader.grub.enable = true;
        kernelPackages = pkgs.tsuki.cachyos.kernel.packages;
    };

    boot.kernelParams = [
        "possible_cpus=0"
    ];

}
