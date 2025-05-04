lib:


let

    inherit ( builtins )
        isAttrs
    ;

    inherit ( lib.tsuki.module )
        flatMod
    ;

in

{

    # condMod :: bool -> attrset -> attrset
    #
    # Combined "mkIf" and "flatMod" to unclutter
    # modules futhermore.
    #
    # $cond will be passed to mkIf as-is
    # $body will go through "flatMod"
    #
    #
    # Usage:
    #
    #   condMod config.happy {
    #       programs.greeting.enable = true;
    #   }
    #
    #
    # One gotcha is that
    # when mixing "options" or "imports" etc.
    # non-"config" fields in condMod body yields
    #
    #   condMod $cond {
    #       options.rocks = ...;
    #       programs.vlc.volume = 100;
    #   }
    #
    # which may cause confusion where "options"
    # seems to be guarded by "cond" while it's not.
    #
    condMod = cond: body:
        assert isAttrs body;
        let unflattened = flatMod body; in
        unflattened // {
            config = lib.mkIf cond unflattened.config;
        };

}
