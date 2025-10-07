{ dots, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.zed
        package-version-server
    ];

    xdg_config."zed".src = dots.get "zed";

}
