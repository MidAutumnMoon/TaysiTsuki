{ pkgs, lib, ... }:

{

    environment.systemPackages = with pkgs; [
        zoxide
    ];

    programs.fish.interactiveInit = /* fish */ ''
        ${lib.bakeInit pkgs pkgs.zoxide "fish" "zoxide init fish"}
    '';

    programs.bash.interactiveShellInit = /* bash */ ''
        ${lib.bakeInit pkgs pkgs.zoxide "bash" "zoxide init bash"}
    '';

}
