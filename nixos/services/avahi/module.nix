{ lib, config, ... }:

let

    tailscaleIface = config.services.tailscale.interfaceName;

in {

    services.avahi =
        lib.mkIf config.services.avahi.enable {
            openFirewall = true;
            nssmdns4 = true;
            nssmdns6 = true;
            publish.enable = true;
            publish.addresses = true;
            publish.userServices = true;
            publish.domain = true;
            denyInterfaces = [ tailscaleIface ];
        };

    systemd.services.avahi-daemon = {
        after = [ "network.target" ];
        wants = [ "network.target" ];
        # Conflict with RO etc overlay
        serviceConfig.ConfigurationDirectory = lib.mkForce [];
    };

    systemd.services.restart-avahi = {
        description = "Restart Avahi Daemon";
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart =
            let ctl = lib.getExe' config.systemd.package "systemctl"; in
            let avahi = config.systemd.services.avahi-daemon.name; in
            "${ctl} restart ${avahi}";
    };

    systemd.timers.restart-avahi = {
        description = "Hourly Timer for Avahi Restart";
        timerConfig = {
            OnCalendar = "hourly";
            Persistent = true;
            Unit = "restart-avahi.service";
        };
        wantedBy = [ "timers.target" ];
    };

}
