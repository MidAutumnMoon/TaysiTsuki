{
    services.tailscale = {
        enable = true;
        openFirewall = true;
        # the tailnet's global resolver is umi's dnscrypt; routing this
        # VPS's DNS through it would detour every lookup across the
        # GFW, so keep the system resolvers
        extraSetFlags = [ "--accept-dns=false" ];
    };
}
