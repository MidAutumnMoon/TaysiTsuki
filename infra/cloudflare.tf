provider "cloudflare" {
    api_token = local.token.cloudflare.api_token
}

module "namecrane" {
    source = "./modules/namecrane"
}

locals {
    ttl_auto = 1

    account_id = local.token.cloudflare.account_id

    # shorter
    __teapot = nonsensitive( cloudflare_zone.teapot.name )
    __spider = cloudflare_zone.spider.name
}

resource "cloudflare_zone" "teapot" {
    name = local.token.cloudflare.domain_418_im
    account = {
        id = local.account_id
    }
}

resource "cloudflare_zone" "spider" {
    name = local.token.cloudflare.domain_spider
    account = {
        id = local.account_id
    }
}

#
# Normal DNS Records
#

resource "cloudflare_dns_record" "teapot_hidden_message" {
    zone_id = cloudflare_zone.teapot.id
    type = "TXT"
    ttl = local.ttl_auto
    name = local.__teapot
    content = "Wish you a delicious day."
}

#
# Records for Mail
#

locals {
    __domains = [
        {
            display = local.__teapot
            domain = local.__teapot
            zone_id = cloudflare_zone.teapot.id
        },
        {
            display = "spiderweb"
            domain = local.__spider
            zone_id = cloudflare_zone.spider.id
        },
    ]
}

resource "cloudflare_dns_record" "namecrane-mail" {
    for_each = {
        for v in [
            for _x in setproduct(
                local.__domains,
                module.namecrane.namecrane_records
            ):
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
    zone_id = cloudflare_zone.teapot.id
    type = "TXT"
    name = "yq8dd991d8429b4e7._domainkey.${local.__teapot}"
    ttl = local.ttl_auto
    content = trimspace( file( "./secrets/teapot_dkim" ) )
}

resource "cloudflare_dns_record" "spider_dkim" {
    zone_id = cloudflare_zone.spider.id
    type = "TXT"
    name = "rk8dd99c9c108fd21._domainkey.${local.__spider}"
    ttl = local.ttl_auto
    content = trimspace( file( "./secrets/spider_dkim" ) )
}
