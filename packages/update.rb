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
    vuetorrent
    dnscrypt
    adblocklist
    sing-box
].tsukify

packages << {
    attr: "tsuki.inori",
    unstable: true,

}

packages << {
    attr: "tsuki.hysteria",
    regex: %r{app/v(.*)},
}
