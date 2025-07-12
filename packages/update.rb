# frozen_string_literal: true

class Array
    def tsukify
        abort "Some item are not String" unless all? { it in String }
        map { "tsuki.#{it}" }
    end
end

packages = []

packages.concat %w[
    caddy
    metacubexd
    rust.rust-analyzer
    shadowsocks
    dnscrypt
    adblocklist
    coredns
].tsukify

# 2025.07.12: beta.33 ssl bad mac regeression
packages << {
    attr: "tsuki.sing-box",
    unstable: true,
    pinned: true,
}

packages << {
    attr: "tsuki.inori",
    unstable: true,
}

packages << {
    attr: "tsuki.qimgv",
    unstable: true,
}

packages << {
    attr: "tsuki.hysteria",
    regex: %r{app/v(.*)},
}
