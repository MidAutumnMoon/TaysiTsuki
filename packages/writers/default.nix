{
    lib,
    writers,
    ruby_teapot,
}:

writers // rec {

    writeRubyTeapot = nameOrPath: { gemSelectFn ? null }:
        let rubyDrv =
            if gemSelectFn == null
            then ruby_teapot.with_preferred_gems
            else ruby_teapot.withPackages gemSelectFn; in
        nameOrPath |> writers.makeScriptWriter {
            interpreter = lib.getExe' rubyDrv "ruby";
        };

    writeRubyBinTeapot = name:
        assert lib.isString name;
        assert !lib.types.path.check name;
        writeRubyTeapot "/bin/${name}";

    test = writeRubyBinTeapot "hello" {} /* ruby */ ''
        puts "wow"
    '';

}
