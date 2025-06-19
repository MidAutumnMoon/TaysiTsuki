vim.filetype.add {

    extension = {
        service = "systemd",
        target = "systemd",
        path = "systemd",
        timer = "systemd",

        opml = "xml",
        mobileconfig = "xml",

        mdx = "markdown",

        pro = "prolog",
    },

    filename = {
        [".envrc"] = "bash",
        ["flake.lock"] = "json",
        ["justfile"] = "just"
    }

}
