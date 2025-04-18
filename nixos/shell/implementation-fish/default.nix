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

        ( lib.mkAliasOptionModule
            [ "programs" "fish" "shellAliases" ]
            [ "programs" "fish" "abbrs" ]
        )
    ];

    options.programs.fish = let
        inherit ( lib ) mkOption types ;
        moreopts = import ./options.nix lib;
    in {
        enable = lib.mkEnableOption "Enable fish shell";
        package = lib.mkPackageOption pkgs "fish" { };

        # TODO: fish has a more powerful abbr system
        # which a simple string cannot represent
        abbrs = mkOption {
            default = { };
            type = with types; attrsOf ( nullOr ( either str path ) );
            description = "Fish abbreviations";
        };

        functions = mkOption {
            type = with types; attrsOf moreopts.fishFunc;
            default = {};
            description = ''
                Shell functions. Ideas and part of the implementation is
                copied from home-manager.
                Due to fish's design, abbrs will have higher priority over
                functions with the same name in interactive shell.
            '';
        };

        init = mkOption {
            default = "";
            description = "fish code to run on init";
            type = lib.types.lines;
        };

        interactiveInit = mkOption {
            default = "";
            description = "fish code to run on interactive init";
            type = lib.types.lines;
        };
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

        programs.fish.abbrs = config.environment.shellAliases
            |> lib.filterAttrs ( _: v: v != null )
            |> lib.filterAttrs ( n: v: !fishCfg.functions ? ${n} )
            |> lib.mapAttrs ( _: lib.mkDefault );

        environment = {
            # N.B. on purpose to not set shells
            shells = [ ];
            systemPackages = [
                fishCfg.package
                config.passthru."fish-functions"
            ];
            pathsToLink = [
                "/share/fish/vendor_conf.d"
                "/share/fish/vendor_completions.d"
                "/share/fish/vendor_functions.d"
            ];
            etc."fish/config.fish".source = config.passthru."fish-config_fish";
        };

        #
        # Warning: pill of mess below!
        #

        # /etc/fish/config.fish
        passthru."fish-config_fish" = pkgs.runCommand "etc-fishcfg" {
            configText = config.passthru."fish-config-text";
            passAsFile = [ "configText" ];
            nativeBuildInputs = with pkgs; [
                fishCfg.package writableTmpDirAsHomeHook
            ];
        } ''
            fish_indent < "$configTextPath" > "$out"
        '';

        # The text content of config.fish
        # Split the two step to make this file a bit cleaner :/
        passthru."fish-config-text" = let
            genOneLineCmd = prefix: obj:
                obj
                |> lib.filterAttrs ( _: v: v != null )
                |> lib.mapAttrs ( _: val: lib.escapeShellArg val )
                |> lib.mapAttrsToList ( nm: val: "${prefix} ${nm} ${val}" )
                |> lib.concatStringsSep "\n";
        in /* fish */ ''
            # Managed by NixOS

            set -xg fish_greeting ""

            ${fishCfg.init}

            if status is-interactive
                ${fishCfg.abbrs |> genOneLineCmd "abbr -ag"}
                ${fishCfg.interactiveInit}
            end
        '';

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
                |> map ( it: rec {
                    name = it.funcname;
                    value = "function ${name} ${genFuncArgs it}\n${it.body}\nend";
                } );
        in pkgs.runCommand "fish-functions" {
            __structuredAttrs = true;
            functions = funcDefs |> lib.listToAttrs;
            nativeBuildInputs = with pkgs; [
                fishCfg.package
                writableTmpDirAsHomeHook
                jq
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
