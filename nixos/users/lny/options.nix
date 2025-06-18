{ lib, config, pkgs, ... }:

let

    inherit ( lib )
        mkOption
        types
        mapAttrs
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

in

{

    options."__raw" = mkOption {
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

    # options."config" = mkOption {};

}

// {

    config.__raw =
        config.home
        |> mapAttrs ( _: val: val // {
            dst = "{{ home }}/${val.dst}";
            src = lib.mkForce val.src;
        } );

}
