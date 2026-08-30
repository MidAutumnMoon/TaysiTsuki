{
    lib,
    kdePackages,
    ...
}:

let

    slimeKdeDrv = args:
        let
            excludes = [
                "plasma-workspace"
                "libksysguard"
            ];
        in
        kdePackages.mkKdeDerivation (args // {
            excludeDependencies =
                args.excludeDependencies or []
                ++ excludes;
        });

in

kdePackages.overrideScope (_self: kdePrev: {

    # qtwebengine is only used for the stupid sougo online dict
    fcitx5-chinese-addons =
        lib.onceride kdePrev.fcitx5-chinese-addons
        { qtwebengine = null; }
        (old: {
            cmakeFlags = (old.cmakeFlags or []) ++ [ "-DENABLE_BROWSER=Off" ];
        });

    # I removed kde portal from system, leave it here for a reference
    # xdg-desktop-portal-kde =
    #     kdePrev.xdg-desktop-portal-kde.override {
    #         mkKdeDerivation = slimeKdeDrv;
    #     };

})
