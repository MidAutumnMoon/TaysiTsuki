{

    systemd.oomd.enableUserSlices = true;

    systemd.user.units."session.slice" = {
        text = ''
            [Slice]
            ManagedOOMPreference=omit
        '';
        overrideStrategy = "asDropin";
    };

    systemd.sleep.settings.Sleep = {
        AllowSuspend = false;
        AllowHibernation = false;
        AllowHybridSleep = false;
        AllowSuspendThenHibernate = false;
    };

}
