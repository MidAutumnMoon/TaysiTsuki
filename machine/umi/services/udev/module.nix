{

    # N.B. hwdb requires a *single* leading space.
    #
    # To add new hwdb rule, use `evtest`.
    # For debugging, use `udevadm info /dev/input/eventX` and `udevadm test-builtin keyboard /sys/class/input/eventX`.
    services.udev.extraHwdb = ''
        # USB HID keyboards.
        #
        # Caps -> Esc
        # Left Win <-> Left Ctrl
        evdev:input:b0003*
         KEYBOARD_KEY_70039=esc
         KEYBOARD_KEY_700e3=leftctrl
         KEYBOARD_KEY_700e0=leftmeta

        # Bluetooth HID keyboards.
        evdev:input:b0005*
         KEYBOARD_KEY_70039=esc
         KEYBOARD_KEY_700e3=leftctrl
         KEYBOARD_KEY_700e0=leftmeta

        evdev:atkbd:*
         KEYBOARD_KEY_3a=esc
         KEYBOARD_KEY_db=leftctrl
         KEYBOARD_KEY_1d=leftmeta

        # Mouse button 5 -> middle click.
        evdev:input:b0003v30FAp1701*
         KEYBOARD_KEY_90005=btn_middle
    '';

}
