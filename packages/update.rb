# frozen_string_literal: true

class Array
    def tsukify
        abort "Some item are not String" unless all? { it in String }
        map { "tsuki.#{it}" }
    end
end

packages = []

packages << %w[
    caddy
    metacubexd
    mihomo
    rust-analyzer
    shadowsocks
    vuetorrent
].tsukify

packages << %w[
    fishPlugins.tide
]

packages << {
    attr: "fishPlugins.puffer-fish",
    unstable: true,
}

packages << {
    attr: "tsuki.inori",
    unstable: true,

}

packages << {
    attr: "tsuki.hysteria",
    regex: %r{app/v(.*)},
}
