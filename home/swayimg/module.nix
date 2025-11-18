{ dots, pkgs, ... }:

let

    # wait for v4.6+
    # scroll at cursor's position
    newSwayimg = pkgs.swayimg.overrideAttrs {
        src = pkgs.fetchFromGitHub {
            owner = "artemsen";
            repo = "swayimg";
            rev = "fc562799131d3e962a6c14e4a78e8c820953c6e3";
            hash = "sha256-Q5TqY5UgSGZVVoARcz1ig0UkZBKgRoT9Ndvg/f1T38Q=";
        };
    };

in

{

    packages = with pkgs; [
        newSwayimg
    ];

    xdg_config."swayimg/config".src = dots.get "swayimg/swayimgrc.ini";

}
