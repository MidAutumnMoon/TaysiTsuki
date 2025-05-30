{
    opentofu
}:

opentofu.withPlugins ( p: with p; [
    cloudflare
    sops
] )
