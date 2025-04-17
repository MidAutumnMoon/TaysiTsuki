lib:

let

    inherit ( lib )
        mkOption
        types
    ;

in {

    # based on home-manager
    # TODO: incomplete types, some argument can repeat
    fishFunc = types.submodule ( { name, ... }: {
        options = {
            funcname = mkOption {
                type = types.str;
                default = name;
            };

            body = mkOption {
                type = types.lines;
                description = "Function content";
            };

            description = mkOption {
                type = types.str;
                description = "--description";
            };

            wraps = mkOption {
                type = types.str;
                description = "--wraps";
            };

            onEvent = mkOption {
                type = with types; either str (listOf str);
                description = "--on-event";
            };

            onVariable = mkOption {
                type = types.str;
                description = "--on-variable";
            };

            onJobExit = mkOption {
                type = with types; either str int;
                description = "--on-job-exit";
            };

            onProcessExit = mkOption {
                type = with types; either str int;
                description = "--on-process-exit";
            };

            onSignal = mkOption {
                type = with types; either str int;
                description = "--on-signal";
            };

            noScopeShadowing = mkOption {
                type = types.bool;
                default = false;
                description = "--no-scope-shadowing";
            };

            inheritVariable = mkOption {
                type = with types; either str (listOf str);
                description = "--inherit-variable";
            };
        };
    } );

}
