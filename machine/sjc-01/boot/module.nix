{ pkgs, ... }:

{

    boot = {
        loader.grub.enable = true;
        loader.timeout = 3 * 60; # the vnc is shit
    };

    boot.kernelParams = [
        "possible_cpus=0-1"
        "iommu=off"
        "intel_iommu=off"
        "amd_iommu=off"
    ];

}
