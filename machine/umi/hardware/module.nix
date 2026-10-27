{ pkgs, ... }:

let

    linuxFirmware = pkgs.compressFirmwareZstd pkgs.linux-firmware;

    firmware = pkgs.runCommand "linux-firmware-umi" {
        compressFirmware = false;
        meta = pkgs.linux-firmware.meta;
    } ''
        mkdir -p $out/lib/firmware/amdgpu $out/lib/firmware/rtl_nic

        cp -a ${linuxFirmware}/lib/firmware/amdgpu/renoir_*.bin.zst \
            ${linuxFirmware}/lib/firmware/amdgpu/green_sardine_*.bin.zst \
            $out/lib/firmware/amdgpu/

        cp -a ${linuxFirmware}/lib/firmware/rtl_nic/rtl8156*-2.fw.zst \
            $out/lib/firmware/rtl_nic/
    '';

in

{

    hardware = {
        cpu.amd.updateMicrocode = true;
        enableRedistributableFirmware = false;
        wirelessRegulatoryDatabase = true;
        firmware = [ firmware ];
    };

}
