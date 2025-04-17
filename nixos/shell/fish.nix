{ lib, config, pkgs, ... }:

{

    disabledModules = [ "programs/fish.nix" ];

    imports = [
        ./parallel-compgen.nix

        ( lib.mkAliasOptionModule
            [ "programs" "fish" "interactiveShellInit" ]
            [ "programs" "fish" "interactiveInit" ]
        )

        ( lib.mkAliasOptionModule
            [ "programs" "fish" "promptInit" ]
            [ "programs" "fish" "interactiveInit" ]
        )
    ];

    options.programs.fish = let
        inherit ( lib ) mkOption types ;
    in {
        enable = lib.mkEnableOption "Enable fish shell";
        package = lib.mkPackageOption pkgs "fish" { };

        # TODO: fish has a more powerful abbr system
        # that a simple cannot represent
        abbrs = lib.mkOption {
            default = { };
            type = with lib.types; attrsOf str;
            description = "fish abbreviations";
        };

        init = lib.mkOption {
            default = "";
            description = "fish code to run on init";
            type = lib.types.lines;
        };

        interactiveInit = lib.mkOption {
            default = "";
            description = "fish code to run on interactive init";
            type = lib.types.lines;
        };

        # compatibility

        shellAliases = mkOption { type = types.anything; };
    };

    config = let

        fishCfg = config.programs.fish;

    in lib.mkIf fishCfg.enable {

        assertions = let
            # shellIsFish :: drv | path -> bool
            shellIsFish = userShell:
                let hasInfix= lib.strings.hasInfix; in
                if lib.isDerivation userShell then
                    lib.getName userShell |> hasInfix "fish"
                else if lib.isPath userShell then
                    hasInfix "fish" userShell
                else
                    false;
        in [ {
            assertion = config.users.users
                |> lib.attrValues
                |> lib.all ( u: !shellIsFish u.shell )
            ;
            message = ''
                The fish module from nixpkgs has been disabled and
                reimplemented in a saner manner. However it is designed around
                the scenario that fish is launched by another posix shell
                such as bash, so that fish itself won't need to source scripts.
                With such design in mind, fish shouldn't be used as user shell,
                otherwise thing WILL break.
            '';
        } ];

        environment.systemPackages = [ fishCfg.package ];

        # N.B. Not setting fish as shell so that it can't
        # because this module
        # is designed around launching fish by bash so that fish
        # does not need to source
        environment.shells = [
            # "/run/current-system/sw/bin/fish"
            # ( lib.getExe fishCfg.package )
        ];

        environment.pathsToLink = [
            "/share/fish/vendor_conf.d"
            "/share/fish/vendor_completions.d"
            "/share/fish/vendor_functions.d"
        ];

        environment.etc."fish/config.fish".text = let

            abbrs = fishCfg.abbrs
                |> lib.mapAttrs ( _: v: lib.escapeShellArg v )
                |> lib.mapAttrsToList ( n: v: "abbr -ag ${n} ${v}" )
                |> lib.concatStringsSep "\n"
            ;

        in /* fish */ ''
            # Managed by NixOS

            set -xg fish_greeting ""

            ${fishCfg.init}

            if status is-interactive
                ${abbrs}
                ${fishCfg.interactiveInit}
            end

            # vim: ft=fish:
        '';

        passthru."fish-config" =
            pkgs.writeText "fish-config"
            config.environment.etc."fish/config.fish".text;
    };

}
