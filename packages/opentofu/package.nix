{
    opentofu,
}:

opentofu.withPlugins ( p: with p; [
    cloudflare_cloudflare
    carlpett_sops
    tailscale_tailscale
] )
