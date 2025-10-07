# N.B.
#
# 1) This module currently doesn't handle tier down,
# i.e. when a user completely removed lny by not setting the option,
# the existing symlinks won't be removed because the systemd service
# that handles symlink will not be generated in this case.

{ lib, config, pkgs, ... } @ outerMost:

let

    inherit ( lib )
        mkOption
        types
        filterAttrs
        mapAttrs
        attrValues
        listToAttrs
        nameValuePair
    ;

    lnyMod = lib.types.submoduleWith {
        specialArgs = {
            inherit lib;
        };
        modules = lib.singleton {
            imports = [ ./options.nix ];
            config._module.args = {
                pkgs = outerMost.pkgs;
                nixosCfg = outerMost.config;
            };
        };
        description = ''
            The core lny submodule.
            Few extra module args are passed
            - pkgs: pkgs
            - nixosCfg: nixos' config
            - lore: our lore
        '';
    };

    lnyPrevGenFile = "/var/lib/lny-prev-gen";

    blueprintNameOf =
        username: "lny-blueprint-${username}.json";

in

{

    options.users.users = mkOption {
        type = types.attrsOf <| types.submodule
            <| ( { config, ... }: {
                options.lny = mkOption {
                    type = types.nullOr lnyMod;
                    default = null;
                };
                config.packages =
                    lib.mkIf ( config.lny != null ) config.lny.packages;
            } );
    };

    # put blueprint into a well known location
    config.environment.etc = let
        toBlueprint = lnyCfg:
            lnyCfg
            |> ( it: it.__rawFiles )
            |> attrValues
            |> map ( val: { inherit ( val ) src dst; } )
            |> ( it: { version = 1; symlinks = it; } )
            |> builtins.toJSON;
    in config.users.users
        # 1. select users which configured lny
        |> filterAttrs ( _: val: val.lny != null )
        # 2. only interested in user's uid and lny
        |> mapAttrs ( name: val: {
            inherit ( val ) uid lny;
            username = name;
        } )
        |> attrValues
        # 3. turn config into blueprint
        |> map ( val: val // { blueprint = toBlueprint val.lny; } )
        # 4. turn these into environment.etc config
        |> map ( val: nameValuePair
            ( blueprintNameOf val.username )
            { text = val.blueprint; uid = val.uid; }
        )
        |> listToAttrs
    ;

    # record the abosulte path of previous generation
    config.system.activationScripts."lny-prev-generation" = {
        deps = [ "etc" ];
        text = /*bash*/ ''
            cursysPath="/run/current-system"
            if [[
                -d "$( dirname '${lnyPrevGenFile}' )" \
                && -L "$cursysPath"
            ]]; then
                printf "%s" "$( readlink -f $cursysPath )" \
                    > '${lnyPrevGenFile}'
            fi
        '';
    };

    # generate systemd service to run lny
    config.systemd.services =
    # config.passthru.wattt =
        config.users.users
        # 1. select users who configured lny
        |> filterAttrs ( _: val: val.lny != null )
        # 2. only interested in their name and homedir
        |> mapAttrs ( name: val: { username = name; home = val.home; } )
        |> attrValues
        # 3. generate systemd service
        |> map ( val: val // rec {
            runner = let
                blueprintName = blueprintNameOf val.username;
                lnyBin =
                    lib.getOutput "lny" pkgs.tsuki.inori
                    |> ( it: lib.getExe' it "lny" );
            in ''
                # derived from home-manager
                eval "$( XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$UID} \
                    systemctl --user show-environment 2> /dev/null \
                    | sed -n '/^XDG/p' \
                    | sed 's/^/export /g' )"

                if [[ -f '${lnyPrevGenFile}' ]]; then
                    prevGen="$( < '${lnyPrevGenFile}' )"
                    if [[ -n "$prevGen" ]]; then
                        oldBlueprint="$prevGen/etc/${blueprintName}"
                    else
                        echo "prevGen file is empty"
                        exit 1
                    fi
                fi

                newBlueprint="${config.environment.etc.${blueprintName}.source}"

                if [[ -n "$oldBlueprint" && -f "$oldBlueprint" ]]; then
                    '${lnyBin}' \
                        --new-blueprint "$newBlueprint" \
                        --old-blueprint "$oldBlueprint"
                else
                    '${lnyBin}' --new-blueprint "$newBlueprint"
                fi
            '';
            service = {
                description = "lny for ${val.username}";
                environment = { RUST_LOG="trace"; };
                script = runner;
                before = [ "systemd-user-sessions.service" ];
                stopIfChanged = false;
                path = [
                    pkgs.gnused
                    config.systemd.package
                ];
                unitConfig = {
                    RequiresMountsFor = val.home;
                };
                serviceConfig = {
                    Type = "oneshot";
                    WorkingDirectory = val.home;
                    TimeoutStartSec = "1m";
                    User = val.username;
                };
                wantedBy = [ "multi-user.target" ];
            };
        } )
        # 4. generate systemd service config
        |> map ( val: nameValuePair "lny-${val.username}" val.service )
        |> listToAttrs
    ;

}
