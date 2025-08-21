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
    monaspace
    peerbanhelper
].tsukify

packages << {
    attr: "tsuki.inori",
    unstable: true,
    pinned: true,
}

packages << {
    attr: "tsuki.sing-box",
    unstable: true,
    preview: true,
}

packages << {
    attr: "tsuki.qimgv",
    unstable: true,
}

packages << {
    attr: "tsuki.hysteria",
    regex: %r{app/v(.*)},
}
