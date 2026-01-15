{ lib, ... }:

{

    services.resolved = {
        enable = lib.mkDefault true;
        settings.Resolve = {
            LLMNR = false;
            MulticastDNS = "resolve";
        };
    };

}
