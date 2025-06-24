{ lib, pkgs, ... }:

{

    environment.shellAliases = {
        "ll" = null;
        "-" = "cd -";
    };

    programs.fish.functions = {
        "cp".body = /* fish */ ''
            if status is-interactive
                set -f int "--interactive"
            end
            command cp $int $argv
        '';

        "mv".body = /* fish */ ''
            if status is-interactive
                set -f int "--interactive"
            end
            command mv $int $argv
        '';

        "ls".body = /*fish*/ ''
            command "${lib.getExe pkgs.eza}" \
                "--group-directories-first" \
                "--color=auto" \
                "--sort=name" \
                "--smart-group" \
                $argv
        '';

        "l".body = /*fish*/ "ls --group-directories-first --long --all $argv";

        # N.B. --tree is eza specific
        "lt".body = "l --tree $argv";
    };

    programs.fish = {
        init = /*fish*/ ''
            fish_add_path "$HOME/.local/bin"
        '';
    };

    programs.command-not-found.enable = lib.mkForce false;

}
