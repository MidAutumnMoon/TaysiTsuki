# frozen_string_literal: true

class Array
    def tsukify
        abort "Some item are not String" unless all? { it in String }
        map { "tsuki.#{it}" }
    end
end

{

    small_thing1:
        %w[
            metacubexd
            vuetorrent
            adblocklist
        ].tsukify + %w[
            fastfetchMinimal
            unrar
        ],

    small_thing2:
        %w[
            neovim
            ruby.with_preferred_gems
            ruby.rubocop
            rust.rust-analyzer
        ].tsukify + %w[
            nixd
        ],

    # Go programs are typically really fast to build
    go_things:
        %w[
            caddy
            mihomo
            dnscrypt
        ].tsukify + %w[
            sops-install-secrets
        ],

    prvn_bundle: %w[
        shadowsocks
        hysteria
        prvn-pkgs.ssserver
        prvn-pkgs.hysteria
        prvn-pkgs.dnscrypt
    ].tsukify,

    lix: %w[lix],

    # Some heavy rust things
    colmena: %w[colmena],
    inori: %w[inori].tsukify,

}
