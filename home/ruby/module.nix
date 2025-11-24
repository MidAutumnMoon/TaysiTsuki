{ pkgs, ... }:

{

    packages = with pkgs; [
        ruby_3_4
        #rubocop
    ];

}
