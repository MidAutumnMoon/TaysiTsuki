{ lib, pkgs, ... }:

{

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

        # N.B. not use "command ls" on purpose because ls might also
        # be a function
        "l".body = /*fish*/ "ls --group-directories-first --long --all $argv";
    };

    programs.fish.abbrs = {
    };

    programs.fish.interactiveInit = /*fish*/ ''
    '';

}
