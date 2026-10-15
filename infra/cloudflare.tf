locals {
  ttl_auto = 1
  # zones live in the Cloudflare dashboard, not in tofu; the ids
  # are pinned here after the cloudflare_zone resources were
  # dropped from state in the provider v5 migration.
  zone_id = {
    im_418 = "126377cf5883452246d38c7ae68d2c85"
    # A embarrassing domain for hosting burner emails which
    # should only be used when the opponent is a jerkhole.
    shameful = "11ec1d1dcd97506130b8e22811fc02b6"
  }
}

provider "cloudflare" {
  api_token = local.secrets.cloudflare.api_token
}

module "namecrane" {
  source = "./modules/namecrane"
}

#
# Normal DNS Records
#

resource "cloudflare_dns_record" "im_418_hidden_message" {
  zone_id = local.zone_id.im_418
  type    = "TXT"
  ttl     = local.ttl_auto
  name    = local.im_418
  content = "Wish you a delicious day."
}

resource "cloudflare_dns_record" "im_418_torrent_download" {
  zone_id = local.zone_id.im_418
  ttl     = local.ttl_auto
  type    = "AAAA"
  name    = "td.${local.im_418}"
  content = local.ip_addr["uk-01"]["ipv6"]
  proxied = true
}

resource "cloudflare_dns_record" "im_418_torrent_dashboard" {
  zone_id = local.zone_id.im_418
  ttl     = local.ttl_auto
  type    = "AAAA"
  name    = "2qbit.${local.im_418}"
  content = local.ip_addr["uk-01"]["ipv6"]
  proxied = true
}

#
# Records for Mail
#

locals {
  __domains_to_add_mail = [
    {
      display = "418.im"
      domain  = local.im_418
      zone_id = local.zone_id.im_418
    },
    {
      display = "shameful.tld"
      domain  = local.secrets.cloudflare.domain_spider
      zone_id = local.zone_id.shameful
    },
  ]
}

resource "cloudflare_dns_record" "namecrane-mail" {
  for_each = {
    for v in [
      for _x in setproduct(
        local.__domains_to_add_mail,
        module.namecrane.namecrane_records
      ) :
      merge(_x...)
    ] :
    # e.g. "teapot-TXT-SPF" or "teapot-MX-mx1..."
    "${v.display}-${v.type}-${lookup(v, "comment", v.content)}"
    => v
  }
  ttl     = local.ttl_auto
  zone_id = each.value.zone_id
  type    = each.value.type
  # if it doesn't have a name, set a record on apex instead
  # fuck hcl
  name = join(".", compact(
    [lookup(each.value, "name", null), each.value.domain]
  ))
  content  = each.value.content
  priority = lookup(each.value, "priority", null)
  comment  = lookup(each.value, "comment", null)
  proxied  = false
}

locals {
  __dkim = nonsensitive(
    jsondecode(file("./secrets/dkim.json"))
  )
}

resource "cloudflare_dns_record" "im_418_dkim" {
  zone_id = local.zone_id.im_418
  type    = "TXT"
  name    = "yq8dd991d8429b4e7._domainkey.${local.im_418}"
  ttl     = local.ttl_auto
  content = local.__dkim.im_418
}

resource "cloudflare_dns_record" "shameful_dkim" {
  zone_id = local.zone_id.shameful
  type    = "TXT"
  name    = "rk8dd99c9c108fd21._domainkey.${local.secrets.cloudflare.domain_spider}"
  ttl     = local.ttl_auto
  content = local.__dkim.shameful
}

#
# Resend
#

resource "cloudflare_dns_record" "im_418_resend_dkim" {
  zone_id = local.zone_id.im_418
  type    = "TXT"
  name    = "resend._domainkey.deliver.${local.im_418}"
  ttl     = local.ttl_auto
  content = local.__dkim.resend
}

resource "cloudflare_dns_record" "im_418_resend_mx" {
  zone_id  = local.zone_id.im_418
  type     = "MX"
  name     = "send.deliver.${local.im_418}"
  ttl      = local.ttl_auto
  proxied  = false
  priority = 10
  content  = "feedback-smtp.us-east-1.amazonses.com"
}

resource "cloudflare_dns_record" "im_418_resend_spf" {
  zone_id = local.zone_id.im_418
  type    = "TXT"
  name    = "send.deliver.${local.im_418}"
  ttl     = local.ttl_auto
  content = "v=spf1 include:amazonses.com ~all"
}
