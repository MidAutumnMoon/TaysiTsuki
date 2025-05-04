{ pkgs, ... }:

{

    services.caddy.package = pkgs.tsuki.caddy;

}
