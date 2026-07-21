{ lib, config, pkgs, ... }:

let

    inherit ( lib )
        mkOption
        types
    ;

    fishCfg = config.programs.fish;
    manCfg = config.documentation.man.man-db;

    # fish >= 4.8 no longer installs this script to disk; it is embedded
    # in the binary and retrieved via `status get-file`.
    generator = pkgs.runCommand "create_manpage_completions.py" { }
        ''
            ${lib.getExe fishCfg.package} --no-config \
                -c 'status get-file tools/create_manpage_completions.py' \
                > "$out"
        '';

    python =
        pkgs.python3.pythonOnBuildForHost.interpreter;

in

{

    options.programs.fish = {
        __generatedCompletion = mkOption {
            type = with types; nullOr package;
            description = ''
                Fish completion generated from manpages.
            '';
            default = null;
        };
    };

    config = lib.mkIf (fishCfg.enable && manCfg.enable) {

        # 1) find
        # - "-maxdepth" for excluding locale manpages because
        #   they are one level deeper than default English ones.
        #
        # 2) xargs
        # - $NIX_BUILD_CORES jobs with each job processing 100 pages
        #
        # 3) compGenerator
        # - "--keep" is important, otherwise later finished jobs
        #   will delete prio generated completion because they
        #   don't belong to it
        #
        # 4) dedupe
        # - fish 4.8+ embeds vendored completions in the binary; any
        #   external <cmd>.fish shadows them entirely (even an empty
        #   file). Drop generated files that would shadow a vendored
        #   one, in a single fish process to amortize startup.
        programs.fish.__generatedCompletion =
            pkgs.runCommand "fish-generated-completion"
            {}
            ''
                mkdir -pv "$out"
                find "${manCfg.manualPages}/share/man" \
                    -maxdepth 2 \
                    -path '*man[1,4-8]/*.gz' \
                | xargs --max-procs="$NIX_BUILD_CORES" \
                        --max-args="100" \
                    '${python}' '${generator}' \
                        --keep --directory "$out" 2>/dev/null

                ${lib.getExe fishCfg.package} --no-config -c '
                    for f in (find $argv[1] -name "*.fish")
                        if status get-file completions/(path basename "$f") >/dev/null 2>&1
                            rm -- "$f"
                        end
                    end
                ' "$out"
            '';

    };

}
