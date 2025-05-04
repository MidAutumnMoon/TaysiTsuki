{
    lib,
    callPackage,
    makeBinaryWrapper,

    ruby_3_4,
    glibcLocalesUtf8,

    defaultGemConfig,
    moreGemsConfig ? {},
}:

lib.onceride ruby_3_4

( _: {
    defaultGemConfig = defaultGemConfig // moreGemsConfig;
    jemallocSupport = true;
    gdbmSupport = false;
} )

( old: {

    nativeBuildInputs = old.nativeBuildInputs ++ [
        makeBinaryWrapper
    ];

    buildInputs = old.buildInputs ++ [
        glibcLocalesUtf8
    ];

    postFixup = ( old.postFixup or "" ) + /* bash */ ''
        wrapProgram "$out/bin/ruby" \
            --prefix "RUBYLIB" ":" "${placeholder "devdoc"}/lib/ruby/site_ruby" \
            --prefix "MALLOC_CONF" "," "background_thread:true" \
            --set-default "RUBY_YJIT_ENABLE" "1" \
            --set-default "LOCALE_ARCHIVE" "$LOCALE_ARCHIVE"
    '';

    passthru = old.passthru // ( callPackage ./with_gems.nix {} );

} )
