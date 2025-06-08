{ lib, ... }:

{

    programs.bash = {
        enable = true;
        # Be the last since it uses "exec" to run fish
        initExtra =
            lib.mkOrder 5000 ( builtins.readFile ./bashrc.bash );
    };

}
