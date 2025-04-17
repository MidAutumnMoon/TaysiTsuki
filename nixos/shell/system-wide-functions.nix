{

    # Some basic shell functions that everyone should have.

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

    };

}
