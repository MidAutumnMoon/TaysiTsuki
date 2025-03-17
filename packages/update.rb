# frozen_string_literal: true

packages = %w[
    caddy_teapot
    rust-analyzer_teapot
    shadowsocks_teapot
    zhudou-sans
    metacubexd

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
    attr: "libyuv_teapot",
    unstable: true,
    pinned: true,
}

packages << {
    attr: "hysteria_teapot",
    regex: %r{app/v(.*)},
}

packages
