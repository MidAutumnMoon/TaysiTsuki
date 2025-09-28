{ config, lib, ... }:

{

    programs.ssh =
        let
            sshdCfg = config.services.openssh;
            sshdSettings = sshdCfg.settings;
        in rec {
            package = sshdCfg.package;
            macs = sshdSettings.Macs;
            ciphers = sshdSettings.Ciphers;
            hostKeyAlgorithms =
                sshdSettings.HostKeyAlgorithms |> lib.splitString ",";
            pubkeyAcceptedKeyTypes = hostKeyAlgorithms;
            kexAlgorithms = sshdSettings.KexAlgorithms;
        };

}
