locals {
    ttl_auto = 1
}

provider "cloudflare" {
    api_token = local.secrets.cloudflare.api_token
}

module "namecrane" {
    source = "./modules/namecrane"
}

resource "cloudflare_zone" "im_418" {
    name = local.shared_nix.domains.im_418.name
    account = {
        id = local.secrets.cloudflare.account_id
    }
}

# A embarrassing domain for hosting burner emails which should only be used
# when the opponent is a jerkhole.
resource "cloudflare_zone" "shameful" {
    name = local.secrets.cloudflare.domain_spider
    account = {
        id = local.secrets.cloudflare.account_id
    }
}

#
# Normal DNS Records
#

resource "cloudflare_dns_record" "im_418_hidden_message" {
    zone_id = cloudflare_zone.im_418.id
    type = "TXT"
    ttl = local.ttl_auto
    name = cloudflare_zone.im_418.name
    content = "Wish you a delicious day."
}

#
# Records for Mail
#

locals {
    __domains_to_add_mail = [
        {
            display = "418.im"
            domain = cloudflare_zone.im_418.name
            zone_id = cloudflare_zone.im_418.id
        },
        {
            display = "shameful.tld"
            domain = cloudflare_zone.shameful.name
            zone_id = cloudflare_zone.shameful.id
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

locals {
    __dkim = nonsensitive(
        jsondecode( file( "./secrets/dkim.json" ) )
    )
}

resource "cloudflare_dns_record" "im_418_dkim" {
    zone_id = cloudflare_zone.im_418.id
    type = "TXT"
    name = "yq8dd991d8429b4e7._domainkey.${cloudflare_zone.im_418.name}"
    ttl = local.ttl_auto
    content = local.__dkim.im_418
}

resource "cloudflare_dns_record" "shameful_dkim" {
    zone_id = cloudflare_zone.shameful.id
    type = "TXT"
    name = "rk8dd99c9c108fd21._domainkey.${cloudflare_zone.shameful.name}"
    ttl = local.ttl_auto
    content = local.__dkim.shameful
}

#
# Tailscale Nodes
#

# Referring to this resource:
# cloudflare_dns_record.teapot_ts["ren"]
resource "cloudflare_dns_record" "im_418_ts" {
    for_each = local.ts_devices
    ttl = local.ttl_auto
    zone_id = cloudflare_zone.im_418.id
    type = "AAAA"
    # should look like "host.tailscale.418.im" if not changed in the future
    name = "${each.key}.${local.shared_nix.domains.im_418.tailscale_zone}.${cloudflare_zone.im_418.name}"
    content = each.value.ipv6
    proxied = false
}

#
# Services on tailscale
#

resource "cloudflare_dns_record" "im_418_music" {
    ttl = local.ttl_auto
    zone_id = cloudflare_zone.im_418.id
    type = "CNAME"
    name = "music.${cloudflare_zone.im_418.name}"
    content = cloudflare_dns_record.im_418_ts["ren"].name
    proxied = false
}

# vim: nowrap:
