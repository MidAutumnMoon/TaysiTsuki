{
    services.xremap = {
        enable = true;
        withNiri = true;
        serviceMode = "user";
        userName = "teapot";
    };

    services.xremap.config = {
        keymap = [
            {
                # N.B. Don't forget to unbind or remap "Close Tab"
                # to keys other than Ctrl+W in `about:keyboard`
                name = "Firefox Vim-style word delete";
                application.only = [ 
                    "firefox"
                    "org.telegram.desktop" 
                    "CherryStudio"
                    "zcode"
                ];
                remap = {
                    "C-w" = "C-Backspace";
                };
            }
        ];
    };
}
