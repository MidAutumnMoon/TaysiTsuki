{
    opentofu,
    terraform-providers,
    tp ? terraform-providers,
}:

let

    # Wait for https://github.com/NixOS/nixpkgs/pull/412619
    _assert = tp.mkProvider {
        owner = "hashicorp";
        repo = "terraform-provider-assert";
        rev = "v0.16.0";
        hash = "sha256-ngHxzV7lRg6pOtyNTdCv3ToRK/vO016Vp2mlh7QT8Rc=";
        vendorHash = "sha256-nHaBNYCKfTvaDnz2SeexM2cyNVK5ThPYn4rnGEw7Wi0=";
        homepage = "https://registry.terraform.io/providers/hashicorp/assert";
        spdx = "MPL-2.0";
    };

in

opentofu.withPlugins ( p: with p; [
    cloudflare
    sops
    _assert
] )
