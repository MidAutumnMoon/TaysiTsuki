# lny module — installs ssh keys/config from sops; pub key from lore
# symlinks $HOME/.ssh/{id_teapot,config,id_teapot.pub}
{ nixosCfg, ... }:

{

    home = {
        ".ssh/id_teapot".src = nixosCfg.sops.secrets."key--ssh--teapot".path;
        ".ssh/config".src = nixosCfg.sops.secrets."conf--ssh".path;
        ".ssh/id_teapot.pub".text = nixosCfg.lore.pubkeys.teapot;
    };

}
