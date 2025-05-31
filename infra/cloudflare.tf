locals {
    ttl_auto = 1
}

provider "cloudflare" {
    api_token = local.token.cloudflare.api_token
}

module "namecrane" {
    source = "./modules/namecrane"
}

resource "cloudflare_zone" "teapot" {
    name = local.token.cloudflare.domain_418_im
    account = {
        id = local.token.cloudflare.account_id
    }
}

resource "cloudflare_zone" "spider" {
    name = local.token.cloudflare.domain_spider
    account = {
        id = local.token.cloudflare.account_id
    }
}

#
# Normal DNS Records
#

resource "cloudflare_dns_record" "teapot_hidden_message" {
    zone_id = cloudflare_zone.teapot.id
    type = "TXT"
    ttl = local.ttl_auto
    name = cloudflare_zone.teapot.name
    content = "Wish you a delicious day."
}

#
# Records for Mail
#

locals {
    __domains_to_add_mail = [
        {
            display = "418.im"
            domain = cloudflare_zone.teapot.name
            zone_id = cloudflare_zone.teapot.id
        },
        {
            display = "spiderweb"
            domain = cloudflare_zone.spider.name
            zone_id = cloudflare_zone.spider.id
        },
    ]
}

resource "cloudflare_dns_record" "namecrane-mail" {
    for_each = {
        for v in [
            for _x in setproduct(
                local.__domains_to_add_mail,
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
    name = "yq8dd991d8429b4e7._domainkey.${cloudflare_zone.teapot.name}"
    ttl = local.ttl_auto
    content = trimspace( file( "./secrets/teapot_dkim" ) )
}

resource "cloudflare_dns_record" "spider_dkim" {
    zone_id = cloudflare_zone.spider.id
    type = "TXT"
    name = "rk8dd99c9c108fd21._domainkey.${cloudflare_zone.spider.name}"
    ttl = local.ttl_auto
    content = trimspace( file( "./secrets/spider_dkim" ) )
}

#
# Tailscale Nodes
#

locals {
    # teapot_tailscale_suffix =
    # "some.ts12.ts.net" = { machine = "...", address = "::::" }
    __tailscale_nodes = {
        for dev in data.tailscale_devices.all.devices:
        dev.name => {
            name = dev.name
            # machine name : some.ts12.ts.net => some
            machine = trimsuffix( dev.name, ".${local.tailnet}" )
            address = [
                for addr in dev.addresses:
                addr if provider::assert::ipv6( addr )
            ][0]
        }
    }
}

# Referring to this resource:
# cloudflare_dns_record.teapot_ts["ren"]
resource "cloudflare_dns_record" "teapot_ts" {
    for_each = {
        for name, val in local.__tailscale_nodes:
        "${val.machine}" => val
    }
    ttl = local.ttl_auto
    zone_id = cloudflare_zone.teapot.id
    type = "AAAA"
    name = "${each.value.machine}.tailscale.${cloudflare_zone.teapot.name}"
    content = each.value.address
    proxied = false
}
