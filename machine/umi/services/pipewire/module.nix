{ lib, ... }:

{

    security.rtkit.enable = true;

    services.pipewire = {
        extraConfig.pipewire."10-hires" = {
            "context.properties" = {
                "default.clock.allowed-rates" = [
                    44100 48000 88200
                    96000 192000 384000
                ];
                "rules" = lib.singleton {
                    "matches" = lib.singleton {
                        "node.name" = "~alsa_output\\.usb-.*";
                    };
                    "actions".update-props = {
                        "node.suspend-on-idle" = true;
                    };
                };
            };
        };
        extraConfig.client."10-hires" = {
            "stream.properties" = {
                "resample.quality" = 10;
                # "resample.disable" = true;
            };
        };
        extraConfig.pipewire-pulse."10-hires" = {
            "stream.properties" = {
                "resample.quality" = 10;
                # "resample.disable" = true;
            };
        };
    };

}
