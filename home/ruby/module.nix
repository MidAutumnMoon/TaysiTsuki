{ tsukiObservatory, pkgs, ... }:

{

    packages = with pkgs; [
        ruby_3_4
        #rubocop
    ];

    xdg_config."rubocop/config.yml".src =
        "${tsukiObservatory}/.rubocop.yml";

}
