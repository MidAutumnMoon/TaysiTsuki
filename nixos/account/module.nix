{ lib, config, ... }:

{

    users.mutableUsers = lib.mkForce false;

    sops.secrets."passwd--root" = {
        sopsFile = ./passwd--root.sops.yml;
        neededForUsers = true;
    };

    users.users."root" = with config; {
        hashedPasswordFile = sops.secrets."passwd--root".path;
        openssh.authorizedKeys.keys = [ lore.pubkeys.teapot ];
    };

}
