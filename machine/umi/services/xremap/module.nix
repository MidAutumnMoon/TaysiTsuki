{
    services.xremap = {
        enable = true;
        withNiri = true;
        serviceMode = "user";
        userName = "teapot";
    };

    services.xremap.config = {
        keymap = [
            # Exclude apps where C-w has special meaning.
            {
                name = "C-w delete words";
                application.not = [
                    "foot"
                    # dolphin has embedded terminal.
                    # A bit leaky, but better than ruining C-w completely.
                    "org.kde.dolphin"
                    "dev.zed.Zed"
                ];
                remap = { "C-w" = "C-Backspace"; };
            }
            # C-w deletes words now, so A-w restores the original shortcut.
            {
                name = "A-w closes";
                application.only = [
                    "firefox"
                    "org.kde.dolphin"
                ];
                remap = {
                    "A-w" = "C-w";
                };
            }
        ];
    };
}
