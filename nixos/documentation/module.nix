{
    documentation.info.enable = false;
    documentation.nixos.enable = false;

    documentation.man.cache = {
        enable = true;
        generateAtRuntime = true;
    };

    environment.variables = {
        MANWIDTH = "80";
        MANROFFOPT="-P -c";
    };
}
