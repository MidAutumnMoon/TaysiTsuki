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
    name = local.im_418
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

resource "cloudflare_dns_record" "im_418_torrent_download" {
    zone_id = cloudflare_zone.im_418.id
    ttl = local.ttl_auto
    type = "AAAA"
    name = "td.${cloudflare_zone.im_418.name}"
    content = local.ip_addr["uk-01"]["ipv6"]
    proxied = true
}

resource "cloudflare_dns_record" "im_418_torrent_dashboard" {
    zone_id = cloudflare_zone.im_418.id
    ttl = local.ttl_auto
    type = "AAAA"
    name = "2qbit.${cloudflare_zone.im_418.name}"
    content = local.ip_addr["uk-01"]["ipv6"]
    proxied = true
}


# resource "cloudflare_dns_record" "im_418_tangled_knot" {
#     zone_id = cloudflare_zone.im_418.id
#     ttl = local.ttl_auto
#     type = "AAAA"
#     name = "knot.${cloudflare_zone.im_418.name}"
#     content = local.ip_addr["sjc-01"]["ipv6"]
#     proxied = true
# }

#
# Bluesky PDS
#

locals {
    pds_handles = [
        {
            name = "tsuki"
            did = "did:plc:a4xfuo6ypcagbiiqocyhgklv"
        }
    ]
    pds_addr = {
        ipv4 = local.ip_addr["sjc-01"]["ipv4"]
        ipv6 = local.ip_addr["sjc-01"]["ipv6"]
    }
}

resource "cloudflare_dns_record" "im_418_pds" {
    for_each = local.pds_addr
    zone_id = cloudflare_zone.im_418.id
    ttl = local.ttl_auto
    type = each.key == "ipv4" ? "A" : "AAAA"
    proxied = true
    name = "pds.${cloudflare_zone.im_418.name}"
    content = each.value
}

resource "cloudflare_dns_record" "im_418_atproto_handles" {
    for_each = {
        for pair in setproduct(local.pds_handles, keys(local.pds_addr)) :
        "${pair[0].name}-${pair[1]}" => {
            name = "${pair[0].name}.${cloudflare_zone.im_418.name}"
            type = pair[1] == "ipv4" ? "A" : "AAAA"
            content = local.pds_addr[pair[1]]
        }
    }
    zone_id = cloudflare_zone.im_418.id
    ttl = local.ttl_auto
    proxied = true
    name = each.value.name
    type = each.value.type
    content = each.value.content
}

resource "cloudflare_dns_record" "im_418_atproto_verify" {
    for_each = {
        for handle in local.pds_handles : handle.name => handle
    }
    zone_id = cloudflare_zone.im_418.id
    ttl = local.ttl_auto
    type = "TXT"
    name = "_atproto.${each.key}.${cloudflare_zone.im_418.name}"
    content = "did=${each.value.did}"
}

#
# Tailscale Nodes
#

# Referring to this resource:
# cloudflare_dns_record.teapot_ts["ren"]
resource "cloudflare_dns_record" "im_418_ts" {
    for_each = local.__tailscale_devices
    ttl = local.ttl_auto
    zone_id = cloudflare_zone.im_418.id
    type = "AAAA"
    # should look like "host.tailscale.418.im" if not changed in the future
    name = "${each.key}.tailscale.${cloudflare_zone.im_418.name}"
    content = each.value.ipv6
    proxied = false
}

#
# Services on tailscale
#

locals {
    __im_418_ts_services = {
        "music" = "ren",
        "clash" = "ren",
    }
}

resource "cloudflare_dns_record" "im_418_ts_services" {
    for_each = local.__im_418_ts_services
    ttl = local.ttl_auto
    zone_id = cloudflare_zone.im_418.id
    type = "CNAME"
    name = "${each.key}.${cloudflare_zone.im_418.name}"
    content = cloudflare_dns_record.im_418_ts[each.value].name
    proxied = false
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
# Resend
#

resource "cloudflare_dns_record" "im_418_resend_dkim" {
    zone_id = cloudflare_zone.im_418.id
    type = "TXT"
    name = "resend._domainkey.deliver.${cloudflare_zone.im_418.name}"
    ttl = local.ttl_auto
    content = local.__dkim.resend
}

resource "cloudflare_dns_record" "im_418_resend_mx" {
    zone_id = cloudflare_zone.im_418.id
    type = "MX"
    name = "send.deliver.${cloudflare_zone.im_418.name}"
    ttl = local.ttl_auto
    proxied = false
    priority = 10
    content = "feedback-smtp.us-east-1.amazonses.com"
}

resource "cloudflare_dns_record" "im_418_resend_spf" {
    zone_id = cloudflare_zone.im_418.id
    type = "TXT"
    name = "send.deliver.${cloudflare_zone.im_418.name}"
    ttl = local.ttl_auto
    content = "v=spf1 include:amazonses.com ~all"
}
