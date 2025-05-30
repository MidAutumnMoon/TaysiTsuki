output "namecrane_records" {
    value = [
        {
            type = "MX"
            content = "mx1.mxfilter.net",
            priority = 10
        },
        {
            type = "MX"
            content = "mx2.mxfilter.net",
            priority = 10
        },
        {
            type = "MX"
            content = "mx3.mxfilter.net",
            priority = 20
        },
        {
            type = "MX"
            content = "mx4.mxfilter.net",
            priority = 20
        },
        {
            type = "TXT",
            name = "_dmarc"
            content = "v=DMARC1; p=quarantine;"
            comment = "DMARC"
        },
        {
            type = "TXT"
            content = "v=spf1 include:_spf.workspace.org -all"
            comment = "SPF"
        },
        {
            type = "CNAME"
            name = "mail"
            content = "eu1.workspace.org"
            comment = "Webmail"
        },
        {
            type = "CNAME"
            name = "autodiscover"
            content = "eu1.workspace.org"
            comment = "Auto Configuration"
        },
    ]
}
