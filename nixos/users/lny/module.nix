# N.B.
#
# 1) This module currently doesn't handle tier down,
# i.e. when a user completely removed lny by not setting the option,
# the existing symlinks won't be removed because the systemd service
# that handles symlink will not be generated in this case.
# lny keeps its state at /var/lib/lny/<user>/state.json
# (the last applied blueprint), which a future teardown could diff
# against to remove stale symlinks; not implemented yet.

{ lib, config, pkgs, flakes, ... } @ outerMost:

let

    inherit ( lib )
        mkOption
        types
        filterAttrs
        mapAttrs
        mapAttrsToList
        attrValues
        listToAttrs
        nameValuePair
    ;

    lnyMod = lib.types.submoduleWith {
        specialArgs = {
            inherit lib flakes;
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

    blueprintNameOf =
        username: "lny-blueprint-${username}.json";

    lnyExe = "${pkgs.tsuki.inori}/bin/lny";

    usersWithLny =
        config.users.users
        |> filterAttrs (_: v: v.lny != null);

in {

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
        toBlueprint = lnyCfg: lnyCfg
            |> (it: it.__rawFiles)
            |> attrValues
            |> map (val: { inherit (val) src dst; })
            |> (it: { version = 1; symlinks = it; })
            |> builtins.toJSON;
    in usersWithLny
        # 1. only interested in user's uid, name and lny
        |> mapAttrs (_: val: { inherit (val) uid lny name; })
        |> attrValues
        # 3. turn config into blueprint
        |> map ( val: val // { blueprint = toBlueprint val.lny; } )
        # 4. turn these into environment.etc config
        |> map ( val: nameValuePair
            (blueprintNameOf val.name)
            { text = val.blueprint; uid = val.uid; }
        )
        |> listToAttrs;

    config.systemd.services."lny@" = {
        description = "lny service for user %i";
        before = [ "systemd-user-sessions.service" ];
        partOf = [ "lny-activate.target" ];
        stopIfChanged = false;
        path = [
            pkgs.gnused
            config.systemd.package
        ];
        serviceConfig = {
            Type = "oneshot";
            User = "%i";
            WorkingDirectory = "~";
            StateDirectory = "lny/%i";
            StateDirectoryMode = "0700";
            TimeoutStartSec = "1m";
            RemainAfterExit = true;
        };
        environment = {
            RUST_LOG = "debug";
            BLUEPRINT_NAME="lny-blueprint-%i.json";
            STATE_PATH = "/var/lib/lny/%i/state.json";
        };
        script = ''
            # derived from home-manager
            export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$UID}
            if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
                eval "$(systemctl --user show-environment 2> /dev/null \
                    | sed -n '/^XDG/p' | sed 's/^/export /g')"
            fi

            exec "${lnyExe}" \
                --new-blueprint "/etc/$BLUEPRINT_NAME" \
                --state "$STATE_PATH"
        '';
    };

    config.systemd.targets."lny-activate" = {
        wantedBy = [ "multi-user.target" ];
        wants = usersWithLny
            # 1. Get usernames
            |> mapAttrsToList (_: v: v.name)
            # 2. Template
            |> map (name: "lny@${name}.service");
        partOf = [ "sysinit-reactivation.target" ];
    };

}
