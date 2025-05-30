locals {
    ttl_auto = 1

    teapot = {
        domain = nonsensitive( local.token.cloudflare.domain_418_im )
        zone_id = local.token.cloudflare.zoneid_418_im
    }

    spider = {
        domain = local.token.cloudflare.domain_spider
        zone_id = local.token.cloudflare.zoneid_spider
    }

    __namecrane = [
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

    __domains = [
        {
            display = "418.im"
            domain = local.teapot.domain
            zone_id = local.teapot.zone_id
        },
        {
            display = "spiderweb"
            domain = local.spider.domain
            zone_id = local.spider.zone_id
        },
    ]
}

resource "cloudflare_dns_record" "namecrane-mail" {
    for_each = {
        for v in [
            for _x in setproduct( local.__domains, local.__namecrane ):
            merge( _x... )
        ]:
        # e.g. "teapot-TXT-SPF" or "teapot-MX-mx1..."
        "${v.display}-${v.type}-${ lookup(v, "comment", v.content) }"
            => v
    }
    ttl = local.ttl_auto
    zone_id = each.value.zone_id
    type = each.value.type
    # if it doesn't have a name, set a record on apex instead
    # fuck hcl
    name = join( ".", compact(
        [ lookup( each.value, "name", null ), each.value.domain ]
    ) )
    content = each.value.content
    priority = lookup( each.value, "priority", null )
    comment = lookup( each.value, "comment", null )
    proxied = false
}

resource "cloudflare_dns_record" "teapot_dkim" {
    zone_id = local.teapot.zone_id
    type = "TXT"
    name = "yq8dd991d8429b4e7._domainkey.${local.teapot.domain}"
    ttl = local.ttl_auto
    content = trimspace( file( "./secrets/teapot_dkim" ) )
}

resource "cloudflare_dns_record" "spider_dkim" {
    zone_id = local.spider.zone_id
    type = "TXT"
    name = "rk8dd99c9c108fd21._domainkey.${local.spider.domain}"
    ttl = local.ttl_auto
    content = trimspace( file( "./secrets/spider_dkim" ) )
}
