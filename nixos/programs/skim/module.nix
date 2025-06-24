{ lib, config, pkgs, ... }:

{

    # skim module's quality is concerningly low
    disabledModules = [ "programs/skim.nix" ];

    environment.systemPackages = [ pkgs.skim ];

    programs.fish = {
        functions."skim_complete_file".__raw =
            builtins.readFile ./skim_complete_file.fish;

        interactiveInit = /*fish*/ ''
            source '${pkgs.skim}/share/skim/completion.fish'
            bind ctrl-t skim_complete_file
        '';
    };

}
