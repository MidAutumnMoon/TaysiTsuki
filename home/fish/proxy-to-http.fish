function proxy-to-http --description 'Replace socks5h/socks5 in proxy env vars with http'
    for var in http_proxy https_proxy ftp_proxy all_proxy \
                       HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY
        if set -q $var
            set -l old_val $$var
            # socks5h (remote DNS) or socks5 (local DNS) → http
            set -l new_val (string replace -r '^socks5h?://' 'http://' -- $old_val)
            if test "$new_val" != "$old_val"
                set -gx $var $new_val
                echo "proxy-to-http: $var = $new_val"
            end
        end
    end
end
