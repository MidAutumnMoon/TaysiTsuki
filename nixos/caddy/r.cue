package sing
#listenPort: number & 7890

#hysteriaCert: string @tag( hysteriaCert )

// Some cue dark magic
// #geositePath & { _, #name: "ads" } evals to the path :)
#geositePath: {
    #name: string // input
    #pkg: "/nix/store/cyz5r9gir9ib1pdmwnzvijvjma3cjayj-sing-geosite-20250526033544"
    #rulesetDir: "\(#pkg)/share/sing-box/rule-set"
    "\(#rulesetDir)/geosite-\(#name).srs"
}

#noproxyDomains: [ "clash.418.im", "dnscrypt.418.im", "router.418.im", "qbit.418.im", "wpad.418.im", "in.418.im", "tailscale.418.im" ]

experimental: {
    cache_file: enabled: true
    clash_api: {
        external_controller: "127.0.0.1:9097"
        secret: ""
    }
}
