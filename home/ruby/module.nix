{ tsukiObservatory, pkgs, ... }:

{

    packages = with pkgs; [
        tsuki.ruby.with_preferred_gems
        tsuki.ruby.rubocop
    ];

    xdg_config."irb/irbrc".text = /*ruby*/ ''
        begin
            require "amazing_print"
            AmazingPrint.irb!
        rescue LoadError
            warn "Can't load amazing_print"
        end
    '';

    xdg_config."rubocop/config.yml".src =
        "${tsukiObservatory}/.rubocop.yml";

}
