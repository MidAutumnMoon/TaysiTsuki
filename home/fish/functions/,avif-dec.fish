function ,avif-dec
    for avif in (fd --type f --extension avif)
        command avifdec $avif (path change-extension png $avif)
    end
end
