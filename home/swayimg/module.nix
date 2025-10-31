{ dots, pkgs, ... }:

let

    # wait for v4.6+
    # scroll at cursor's position
    newSwayimg = pkgs.swayimg.overrideAttrs {
        src = pkgs.fetchFromGitHub {
            owner = "artemsen";
            repo = "swayimg";
            rev = "ac21e8c9a8385e49985fca6f2f03469231db0b75";
            hash = "sha256-+DOPX9wrS3367u6STbrOWzUcZR1T0zz8N7jHNh9K3tc=";
        };
    };

in

{

    packages = with pkgs; [
        newSwayimg
    ];

    xdg_config."swayimg/config".src = dots.get "swayimg/swayimgrc.ini";

}
