{ lib, config, ... }:

let

    machineId = config.boot.machineId;

in {
    options.boot.machineId = lib.mkOption {
        type = with lib.types; strMatching "[0-9a-f]+";
        description = "The content of /etc/machine-id";
    };

    config = {
        environment.etc."machine-id".text = machineId;
        boot.kernelParams = [ "systemd.machine_id=${machineId}" ];
        networking.hostId = lib.substring 0 8 machineId;
    };
}
