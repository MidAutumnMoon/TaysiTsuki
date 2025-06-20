{ lib, pkgs, ... }:

{

    environment.systemPackages = with pkgs; [
        zoxide
    ];

    programs.fish.interactiveInit = /* fish */ ''
        zoxide init fish | source
    '';

    programs.bash.interactiveShellInit = /* bash */ ''
        eval "$( zoxide init bash )"
    '';

}
