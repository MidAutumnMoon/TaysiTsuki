{
    systemd.user.sockets.foot-server = {
        overrideStrategy = "asDropin";
        wantedBy = [ "graphical-session.target" ];
    };
}
