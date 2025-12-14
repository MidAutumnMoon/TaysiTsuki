{
    callPackage,
    fetchFromGitHub,
    stdenv,

    linux_latest,
}:

rec {

    kernelVariant = "linux-cachyos";

    kernelPatches = fetchFromGitHub {
        owner = "CachyOS";
        repo = "kernel-patches";
        rev = "8a5e89d346af4221d7426b45da65a677a1ff5582";
        sha256 = "sha256-y+JyvbAb/vyGAOSHU7CdCYypNMFaEFV8K0dYY8nO3gM=";
        postFetch = ''
            find "$out" -type f ! -name "0001-cachyos-base-all.patch" -delete
            find "$out" -type d -empty -delete
        '';
    };

    kernelConfig = fetchFromGitHub {
        owner = "CachyOS";
        repo = "linux-cachyos";
        rev = "278762fc5eb743b8bf9f819fdf6506306685b101";
        sha256 = "sha256-LgoguRNeGJjKQ5SSYF3ljk8CCudkSRbRyWGy0rFDGPk=";
        postFetch = ''
            hold="$(mktemp -d)"
            conf="$hold/conf"
            cp "$out/${kernelVariant}/config" "$conf"
            rm -rfv "$out"
            cp -v "$conf" "$out"
        '';
    };

    kernel = callPackage ./kernel.nix {
        inherit kernelPatches kernelConfig;
        baseKernel = linux_latest;
    };

    # TODO: implement subpackages in maintainance tool
    kernel-patches-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-patches";
        version = "0-unstable-2025-12-13";
        src = kernelPatches;
        buildCommand = "ls $src > $out";
    };
    kernel-config-updater = stdenv.mkDerivation {
        pname = "cachyos-kernel-config";
        version = "6.17.9-unstable-2025-12-13";
        src = kernelConfig;
        buildCommand = "cat $src > $out";
    };

}
