{ config, ... }:

let

    persistDir = config.fileSystems."/persist".mountPoint;

in

{

    services.userborn = {
        passwordFilesLocation = "${persistDir}/etc";
    };

}
