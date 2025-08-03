{ pkgs, ... }:

{

    packages = with pkgs;
        let beam = beam28Packages; in
        [
            beam.elixir-ls
            beam.elixir_1_18
            inotify-tools
        ];

    envvars = {
        ERL_AFLAGS = "-kernel shell_history enabled";
    };

}
