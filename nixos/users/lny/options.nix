{ lib, config, pkgs, ... }:

let

    inherit ( lib )
        mkOption
        types
        attrValues
        nameValuePair
        listToAttrs
        mapAttrsToList
        concatStringsSep
    ;

    fileMod = types.submodule
        ( { name, options, config, ... }: {
            options.dst = mkOption {
                type = types.str;
                default = name;
            };
            options.src = mkOption {
                type = with types; coercedTo path toString str;
            };
            options.text = mkOption {
                type = with types; nullOr lines;
                default = null;
            };
            options.exe = mkOption {
                type = types.bool;
                default = false;
            };
            config.src = lib.mkIf ( config.text != null ) <|
                lib.mkDerivedConfig options.text ( it:
                    pkgs.writeTextFile {
                        name = "lny-${config.dst}";
                        text = it;
                        executable = config.exe;
                    }
                );
        } );

    withPrefix = prefix: fileCfg:
        fileCfg
        |> attrValues
        |> map ( val: nameValuePair
            "${prefix}/${val.dst}"
            { src = lib.mkDefault val.src; }
        )
        |> listToAttrs;

in

{

    # File related options

    options."__rawFiles" = mkOption {
        type = types.attrsOf fileMod;
        default = {};
        description = ''
            Raw symlinks, with no template added.
            Remeber to use abosulte paths!
        '';
    };

    options."home" = mkOption {
        type = types.attrsOf fileMod;
        default = {};
        description = ''
            Files to placed under home, relatived to $HOME.
            The "{{ home }}" template is automatically applied.
        '';
    };

    options."xdg_config" = mkOption {
        type = types.attrsOf fileMod;
        default = {};
        description = ''
            Files to be placed relative to $XDG_CONFIG_HOME.
            The "{{ config }}" template is automatically applied.
        '';
    };

    # Packages options

    options."packages" = mkOption {
        type = with types; listOf package;
        default = [];
        description = ''
            Packages to install to user's profile
        '';
    };

    # Environment variable options

    options."envvars" = mkOption {
        type = with types;
            attrsOf <| coercedTo anything toString str;
        default = {};
        description = ''
            User environemtn variables. Implemented using `environment.d`
        '';
    };

    # Support options

    options."passthru" = mkOption {
        type = with types; attrsOf anything;
    };

    config.__rawFiles = lib.mkMerge [
        ( config.home |> withPrefix "{{ home }}" )
        ( config.xdg_config |> withPrefix "{{ config }}" )
    ];

    config.xdg_config."environment.d/10-lny.conf".text =
        config.envvars
        |> mapAttrsToList ( n: v: "${n}=${toString v}" )
        |> concatStringsSep "\n"
        # Add trailing newline, # otherwise the conf file
        # is considered malformed :\
        |> ( val: "${val}\n" );

}
