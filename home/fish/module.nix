{ dots, pkgs, ... }:

{

    packages = [ pkgs.fish ];

    xdg_config."fish/functions".src = dots.get "fish";
    xdg_config."fish/conf.d/__moonstep.fish".src =
        dots.get "fish/conf.d/__moonstep.fish";

}
