function ,webp-dec
    for webp in (fd --type f --extension webp)
        command dwebp $webp -o (path change-extension png $webp)
    end
end
