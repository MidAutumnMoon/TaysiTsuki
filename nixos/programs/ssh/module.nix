{ config, lib, ... }:

{

    programs.ssh =
        let
            sshdCfg = config.services.openssh.settings;
        in rec {
            macs = sshdCfg.Macs;
            ciphers = sshdCfg.Ciphers;
            hostKeyAlgorithms =
                sshdCfg.HostKeyAlgorithms |> lib.splitString ",";
            pubkeyAcceptedKeyTypes = hostKeyAlgorithms;
            kexAlgorithms = sshdCfg.KexAlgorithms;
        };

}

