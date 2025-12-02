{ config, ... }:

let

    persistDir = config.fileSystems."/var".mountPoint;

in {

    services.userborn = {
        passwordFilesLocation = "${persistDir}/lib";
    };

}
