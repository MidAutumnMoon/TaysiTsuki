{ dots, pkgs, ... }:

{

    packages = [
        pkgs.zed-editor
        pkgs.package-version-server
    ];

    xdg_config."zed".src = dots.get "zed";

}
