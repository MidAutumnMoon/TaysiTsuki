{ lib, config, pkgs, ... }:

let

    inherit ( lib )
        hasInfix
        filterAttrs
        mapAttrs
    ;

    fishCfg = config.programs.fish;

in

{

    disabledModules = [ "programs/fish.nix" ];

    imports = [
        ./options.nix
        ./parallelCompletionGen.nix
    ];

    config = lib.mkIf fishCfg.enable {

        assertions =
            lib.singleton {
                assertion = config.users.users
                    |> lib.attrValues
                    |> lib.all ( u:
                        !( hasInfix "fish" <| toString u.shell )
                    );
                message = ''
                    Don't set user shell to fish!
                    The in-house fish module works with the assumption
                    that user's fish shell is chain-launched using bash
                    so that it won't need to deal with converting environment
                    variables. Things will break if fish is user shell!
                '';
            };

        environment = {
            # N.B. on purpose to not add fish to shells
            shells = [ ];
            systemPackages = [
                fishCfg.package
                fishCfg.__functionsBundle
            ];
            pathsToLink = [
                "/share/fish/completions"
                "/share/fish/functions"
                "/share/fish/vendor_conf.d"
                "/share/fish/vendor_completions.d"
                "/share/fish/vendor_functions.d"
            ];
            etc."fish/config.fish".source = fishCfg.__configFish;
        };

        programs.fish.abbrs =
            config.environment.shellAliases
            |> filterAttrs ( _: val: val != null )
            # If a system alias have the same name as a fish function,
            # the function is usally what the user wants. The alias
            # should be ignored (maybe not silently?).
            |> filterAttrs ( name: _:
                # TODO: check submod name instead of attr name
                !fishCfg.functions ? ${name}
            )
            |> mapAttrs ( _: lib.mkDefault );

        programs.fish.init =
            let comp = toString fishCfg.__generatedCompletion; in
            lib.mkBefore ''
                if not contains "${comp}" $fish_complete_path
                    # Append because auto generated completions have
                    # lower quality than fish vendored ones.
                    set --append fish_complete_path "${comp}"
                end
                # Workaround for fish not adding "/share/fish/completions" from
                # XDG_DATA_DIRS
                set --prepend fish_complete_path \
                    "${fishCfg.package}/share/fish/completions"
                set --append fish_function_path \
                    "${fishCfg.package}/share/fish/functions"
            '';

    };

}
