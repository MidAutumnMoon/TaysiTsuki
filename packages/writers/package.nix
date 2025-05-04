{
    lib,
    writers,
    tsuki,
}:

rec {

    writeRuby = nameOrPath: { gemSelectFn ? null }:
        let rubyDrv =
            if gemSelectFn == null
            then tsuki.ruby.with_preferred_gems
            else tsuki.ruby.withPackages gemSelectFn; in
        nameOrPath |> writers.makeScriptWriter {
            interpreter = lib.getExe' rubyDrv "ruby";
        };

    writeRubyBin = name:
        assert lib.isString name;
        assert !lib.types.path.check name;
        writeRuby "/bin/${name}";

}
