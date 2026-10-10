{ pkgs, ... }:

{

    environment.systemPackages = with pkgs; [ tsuki.helix ];

    environment.sessionVariables = {
        EDITOR = "hx";
    };

    environment.shellAliases = {
        "x" = "hx";
    };

}

