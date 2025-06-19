{ nixosCfg, ... }:

{

    home = {
        ".ssh/id_teapot".src = nixosCfg.sops.secrets."key--ssh--teapot".path;
        ".ssh/config".src = nixosCfg.sops.secrets."conf--ssh".path;
        ".ssh/id_teapot.pub".text = nixosCfg.lore.pubkeys.teapot;
    };

}
