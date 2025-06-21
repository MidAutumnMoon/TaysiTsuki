{ lib, libavif, fetchpatch }:

libavif.overrideAttrs ( old: {

    patches = old.patches or [] ++ ( lib.singleton <|
        # wait for next release 1.3.0+
        fetchpatch {
            url = "https://github.com/AOMediaCodec/libavif/pull/2828.patch";
            hash = "sha256-9kPxS1QPtV6GlwoZ6WHeQq+qLfelTRNcKZQMg8W9Hwg=";
        }
    );

} )
