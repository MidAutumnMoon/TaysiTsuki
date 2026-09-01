lib:

let

    inherit (lib)
        getExe
        getName
        attrNames
        concatStringsSep
    ;

    supportedShells = {
        fish = {
            ext = "fish";
            check = pkgs: out:
                "${getExe pkgs.fish} --no-execute ${out}";
        };
        bash = {
            ext = "sh";
            check = pkgs: out: "${getExe pkgs.bash} -n ${out}";
        };
        zsh = {
            ext = "zsh";
            check = pkgs: out: "${getExe pkgs.zsh} -n ${out}";
        };
    };

    assertSupportedShell = shell:
        let
            shellNames =
                attrNames supportedShells
                |> concatStringsSep ", ";
        in
        lib.assertMsg (supportedShells ? ${shell})
            "unsupported `${shell}`, expected one of: ${shellNames}";

in {

    # bakeInit :: pkgs -> drv -> string -> string -> string
    #
    # Capture an app's shell-init script at build time and return a
    # `source '<store-path>'` line, instead of running `<app> init <shell>`
    # on every shell startup.
    #
    # CAVEAT: the captured file has an empty nix closure — it does NOT
    # install the app. Keep the app in systemPackages / user packages so
    # it is on PATH at runtime.
    #
    bakeInit = pkgs: app: shellName: cmd:
        assert assertSupportedShell shellName;
        let
            shell = supportedShells.${shellName};
            script = pkgs.runCommand
                "${getName app}-init.${shell.ext}"
                { nativeBuildInputs = [ app ]; }
                ''
                    HOME="$TMPDIR" ${cmd} > "$out"
                    ${shell.check pkgs (placeholder "out")}
                '';
        in {
            inherit script;
            __toString = self: "source '${self.script}'";
        };

}
