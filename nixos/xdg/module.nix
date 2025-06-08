{ lib, ... }:

let

    variables = {
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
    };

in

{

    environment.variables = variables;

    environment.etc."pam/environment".text =
        variables
        |> lib.mapAttrs ( _: lib.replaceStrings ["$HOME"] ["@{HOME}"] )
        |> lib.mapAttrsToList ( n: v: ''${n} DEFAULT="${v}"'' )
        |> lib.concatStringsSep "\n"
        |> lib.mkAfter
    ;

}
