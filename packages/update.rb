# frozen_string_literal: true

packages = %w[
    caddy_teapot
    rust-analyzer_teapot
    shadowsocks_teapot
    metacubexd
    mihomo

    fishPlugins.tide
]

packages << {
    attr: "fishPlugins.puffer-fish",
    unstable: true,
}

packages << {
    attr: "inori",
    unstable: true,

}

packages << {
    attr: "hysteria_teapot",
    regex: %r{app/v(.*)},
}
