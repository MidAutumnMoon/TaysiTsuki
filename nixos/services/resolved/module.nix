{ lib, ... }:

{

    services.resolved = {
        enable = lib.mkDefault true;
        llmnr = "false";
        extraConfig = ''
            MulticastDNS = resolve
        '';
    };

}
