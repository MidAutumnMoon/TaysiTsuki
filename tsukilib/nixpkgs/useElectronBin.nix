lib:

{

    # Override the input of `app` to use electron binary package
    # of the same version (for avoiding building electron from source).
    useElectronBin = pkgs: app:
        # { electron_39 = true; }
        app.override.__functionArgs
        # [ "electron_39" ]
        |> lib.attrNames
        |> lib.findFirst (lib.hasPrefix "electron") null
        |> (ev:
            assert ev != null;
            app.override {
                ${ev} = pkgs.${ev + "-bin"};
            }
        );

}
