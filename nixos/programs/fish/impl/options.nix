{ lib, config, pkgs, ... }:

let

    inherit ( lib )
        mkOption
        types
        literalMD
        concatStringsSep
        optional
        attrValues
        mapAttrs
        mapAttrsToList
    ;

    inherit ( pkgs )
        runCommand
    ;

    fishCfg = config.programs.fish;

    funcSubmod = types.submodule ( { name, config, options, ... }: {
        options.name = mkOption {
            type = types.str;
            default = name;
        };

        options.args = mkOption {
            type = with types; listOf str;
            description = ''
                Argument for "function" command when declaring
                the command. Be careful with escaping as this module
                doesn't do that.
            '';
            example = literalMD ''
                [ "--on-event 'fish_prompt'" "--inherit-variable" ]
            '';
            default =
                optional ( config.desc != options.desc.default )
                "--description '${config.desc}'";
        };

        options.desc = mkOption {
            type = types.str;
            default = "";
            description = "Function description";
        };

        options.body = mkOption {
            type = types.lines;
            description = "Function content";
        };

        options.__raw = mkOption {
            type = types.lines;
            internal = true;
            description = ''
                Raw text of the function, should include
                "function name ... end".
            '';
            default = with config; ''
                function ${name} ${concatStringsSep " " args}
                    ${body}
                end
            '';
        };

        options.__built = mkOption {
            type = types.package;
            internal = true;
            description = literalMD ''
                `__raw` but indented using `fish_indent` and syntax checked
            '';
            default = writeFishIndented
                "fishfn-${config.name}.fish" config.__raw;
        };
    } );

    writeFishIndented = name: content:
        pkgs.runCommand name
        {
            nativeBuildInputs = with pkgs; [
                fishCfg.package jq
                writableTmpDirAsHomeHook
            ];
            __structuredAttrs = true;
            inherit content;
        }
        ''
            jq -er ".content" < "$NIX_ATTRS_JSON_FILE" | fish_indent > "$out"
            fish --no-execute "$out"
        '';

in {

    # Compatibility layer. Not all options are shimed but they are not used
    # by anyone anyway (backed by Github code search).
    imports = with lib; [
        ( mkAliasOptionModule
            [ "programs" "fish" "interactiveShellInit" ]
            [ "programs" "fish" "interactiveInit" ]
        )

        ( mkAliasOptionModule
            [ "programs" "fish" "promptInit" ]
            [ "programs" "fish" "interactiveInit" ]
        )

        ( mkAliasOptionModule
            [ "programs" "fish" "shellAliases" ]
            [ "programs" "fish" "abbrs" ]
        )
    ];

    options.programs.fish = {
        enable = lib.mkEnableOption "Enable fish shell";
        package = lib.mkPackageOption pkgs "fish" { };

        init = mkOption {
            type = types.lines;
            default = "";
            description = literalMD ''
                Code to run on shell initialization.
            '';
        };

        interactiveInit = mkOption {
            type = types.lines;
            default = "";
            description = literalMD ''
                Code run on interactive shell initialization.
            '';
        };

        __configFish = mkOption {
            type = types.package;
            description = ''
                Fish config.fish indented and written to file.
            '';
        };

        # TODO: fish abbr is more powerful that a string
        # consider using a submodule like functions
        abbrs = mkOption {
            type = with types; attrsOf str;
            default = { };
            description = literalMD ''
                abbrs
            '';
        };

        functions = mkOption {
            type = with types; attrsOf funcSubmod;
            default = {};
            description = ''
                Fish functions.
            '';
        };

        __functionsBundle = mkOption {
            type = types.package;
            internal = true;
            description = ''
                All fish functions in one package.
            '';
        };
    };

    config = lib.mkIf fishCfg.enable {

        programs.fish.__functionsBundle =
            runCommand "fish-functions" {} /*bash*/ ''
                # vendor_functions.d will be linked to system profile
                dest="$out/share/fish/vendor_functions.d"
                mkdir -pv "$dest"
                ${ fishCfg.functions
                    |> attrValues
                    |> map ( val:
                        "cp -v '${val.__built}' \"$dest/${val.name}.fish\""
                    )
                    |> concatStringsSep "\n" }
            '';

        # Turn abbrs into `abbr` command
        programs.fish.interactiveInit =
            fishCfg.abbrs
            |> mapAttrs ( _: v: lib.escapeShellArg v )
            |> mapAttrsToList ( n: v: "abbr -ag ${n} ${v}" )
            |> concatStringsSep "\n"
            |> lib.mkBefore;

        programs.fish.__configFish =
            writeFishIndented "config.fish"
            ''
                # Generated with TaysiTsuki fish module
                set -g fish_greeting ""
                ${fishCfg.init}
                if status is-interactive
                    ${fishCfg.interactiveInit}
                end
            '';

    };

}
