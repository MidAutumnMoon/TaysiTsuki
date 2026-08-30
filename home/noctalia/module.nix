# symlinks repo home/noctalia/settings.toml to .local/state/noctalia/settings.toml; managed purely using Noctalia GUI
{ dots, ... }:

{

    home.".local/state/noctalia/settings.toml".src =
        dots.get "noctalia/settings.toml";

}
