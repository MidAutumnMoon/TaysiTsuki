{ lib, config, ... }:

{

    users.mutableUsers = lib.mkForce false;

    # sops.secrets."passwd--root" = {
    #     sopsFile = ./passwd--root.sops.yml;
    #     neededForUsers = true;
    # };

    users.users."root" = with config; {
        hashedPassword = lib.fileContents ./passwd;
        openssh.authorizedKeys.keys = [ lore.pubkeys.teapot ];
    };

}
