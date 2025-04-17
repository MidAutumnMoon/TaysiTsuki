{ lib, config, pkgs, ... }:

{

    disabledModules = [ "programs/fish.nix" ];

    imports = [
        ./parallel-compgen.nix
        ./system-wide-functions.nix

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
        moreopts = import ./options.nix lib;
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

        functions = lib.mkOption {
            type = with types; attrsOf moreopts.fishFunc;
            default = {};
            description = "fish functions";
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

        environment.systemPackages = [
            fishCfg.package
            config.passthru."fish-functions"
        ];

        # N.B. on purpose to not set shells
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

        passthru."fish-functions" = let
            inherit ( lib ) optionalString;
            inherit ( lib.nuran.module ) rejectUnset;

            strArg = n: v: ''${n}="${toString v}"'';
            boolArg = n: v: optionalString v "${n}";
            fmt = obj: field: argname: driver:
                optionalString ( obj ? ${field} ) ( driver argname obj.${field} );

            # TODO: not complete accurate types, e.g. list of argument
            genFuncArgs = def: [
                ( fmt def "wraps" "--wraps" strArg )
                ( fmt def "onEvent" "--on-event" strArg )
                ( fmt def "onVariable" "--on-variable" strArg )
                ( fmt def "onJobExit" "--on-job-exit" strArg )
                ( fmt def "onProcessExit" "--on-process-exit" strArg )
                ( fmt def "onSignal" "--on-signal" strArg )
                ( fmt def "noScopeShadowing" "--no-scope-shadowing" boolArg )
                ( fmt def "inheritVariable" "--inherit-variable" strArg )
            ] |> lib.filter ( v: v != "" ) |> lib.concatStringsSep " ";

            funcDefs =
                lib.attrValues fishCfg.functions
                |> map rejectUnset
                |> map ( it: {
                    name = it.funcname;
                    value = ''
                        function ${it.funcname} ${genFuncArgs it}
                            ${it.body}
                        end
                    '';
                } );
        in pkgs.runCommand "fish-functions" {
            __structuredAttrs = true;
            functions = funcDefs |> lib.listToAttrs;
            nativeBuildInputs = [
                fishCfg.package
                pkgs.writableTmpDirAsHomeHook
                pkgs.jq
            ];
        } ''
            # Put functions under vendor_functions.d
            # so that install this package will automatically
            # make this functions discoverable.
            dest="$out/share/fish/vendor_functions.d"
            mkdir -pv "$dest"
            ${
                funcDefs
                |> map ( it: /*sh*/ ''
                    jq -er ".functions.${it.name}" < "$NIX_ATTRS_JSON_FILE" \
                        | fish_indent > "$dest/${it.name}.fish"
                '' )
                |> lib.concatStringsSep "\n"
            }
        '';
    };

}
