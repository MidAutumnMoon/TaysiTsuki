# Everything the stock ELF DT_NEEDs or dlopens.
ps: with ps; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXcursor
    # zcode dlopens libdbusmenu-glib.so.4 for StatusNotifierItem tray menus.
    libdbusmenu
    libgbm
    libnotify
    libpulseaudio
    libsecret
    libxcb
    libxkbcommon
    nspr
    nss
    pango
    pipewire
    systemdLibs
    wayland
    # GL/Vulkan loaders only; the hardware drivers come from
    # /run/opengl-driver.
    libglvnd
    vulkan-loader
    # For xdg-open inside the sandbox.
    xdg-utils
]
