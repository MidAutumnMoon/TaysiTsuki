{

    programs.firefox = {
        enable = true;
        wrapperConfig = {
            speechSynthesisSupport = false;
        };
    };

    programs.firefox.policies = {
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;

        Cookies = {
            Behavior = "limit-foreign";
            BehaviorPrivateBrowsing = "limit-foreign";
        };

        EnableTrackingProtection = {
            Value = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
        };

        FirefoxHome = {
            Locked = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Stories = false;
            SponsoredStories = false;
        };

        FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
            Locked = true;
        };

        Homepage.StartPage = "previous-session";
        HttpsOnlyMode = "enabled";
        NetworkPrediction = false;
        NewTabPage = false;
        NoDefaultBookmarks = true;
        PopupBlocking.Default = true;
        Proxy.UseProxyForDNS = true;

        Permissions = {
            Camera.BlockNewRequests = true;
            Microphone.BlockNewRequests = true;
            Location.BlockNewRequests = true;
        };

        SanitizeOnShutdown = {
            Cache = true;
        };

        SearchSuggestEnabled = false;
        TranslateEnabled = false;

        UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            FirefoxLabs = false;
        };
    };

    programs.firefox.preferences = {
        "browser.aboutConfig.showWarning" = false;

        "accessibility.force_disabled" = true;
        "accessibility.typeaheadfind" = false;
        "accessibility.typeaheadfind.autostart" = false;

        "beacon.enabled" = false;
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        # 2GiB in KiB
        "browser.cache.memory.capacity" = 2097152;
        "browser.cache.memory.max_entry_size" = -1;
        "browser.contentblocking.category" = "strict";
        "browser.discovery.enabled" = false;
        "browser.display.auto_quality_min_font_size" = 0;
        # hit ctrl-q by accident and the browser quits is really annoying
        "browser.quitShortcut.disabled" = true;
        "browser.search.suggest.enabled" = false;
        # "browser.sessionstore.restore_pinned_tabs_on_demand" = true;
        "browser.tabs.insertAfterCurrent" = true;
        "browser.uitour.enabled" = false;
        "browser.urlbar.decodeURLsOnCopy" = true;
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.suggest.quickactions" = false;
        "browser.urlbar.suggest.addons" = false;
        "browser.urlbar.suggest.calculator" = false;
        "browser.urlbar.suggest.clipboard" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.remotetab" = false;
        "browser.urlbar.suggest.weather" = false;
        "browser.urlbar.suggest.yelp" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.urlbar.suggest.trending" = false;
        # make the "3-dot" after urlbar entries to not disturbe the tab key flow
        # ref: https://bugzilla.mozilla.org/show_bug.cgi?id=1813517
        "browser.urlbar.resultMenu.keyboardAccessible" = false;
        "browser.urlbar.autoFill.adaptiveHistory.enabled" = true;
        # Ref: https://superuser.com/questions/7327/
        # Google without AI summary & NCR
        # www.google.com/search?q=%s&udm=14&pws=0&gl=us&gws_rd=cr&safe=off
        "browser.urlbar.update2.engineAliasRefresh" = true;

        # enabled by default in 141; current 140
        "dom.ipc.forkserver.enable" = true;
        "dom.netinfo.enabled" = false;
        "dom.battery.enabled" = false;
        "dom.vr.enabled" = false;
        "dom.webshare.enabled" = false;
        "dom.security.https_only_mode_send_http_background_request" = false;
        # currently only enabled on nightly by default
        "dom.text_fragments.create_text_fragment.enabled" = true;

        "general.autoScroll" = true;
        # "general.smoothScroll.msdPhysics.enabled" = true;
        "geo.enabled" = false;
        "gfx.webrender.all" = true;

        "javascript.options.baselinejit.threshold" = 50;

        "media.autoplay.default" = 5;
        "media.autoplay.blocking_policy" = 2;
        # 16GiB in KiB
        "media.memory_cache_max_size" = 16777216;
        "media.peerconnection.enabled" = false;
        "media.webspeech.recognition.enable" = false;
        "media.webspeech.synth.enabled" = false;

        "network.cookie.thirdparty.sessionOnly" = true;
        "network.buffer.cache.size" = 65535;
        "network.IDN_show_punycode" = true;
        # may break sites, e.g. cdn which verifies origin to the path
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        "network.http.referer.trimmingPolicy" = 1;
        # WILL break sites
        # "network.http.referer.trimmingPolicy" = 2;
        # "network.http.referer.XOriginPolicy" = 2;
        # "network.http.referer.spoofSource" = true;

        "pdfjs.enableScripting" = false;
        "pdfjs.firstRun" = false;
        "privacy.userContext.enabled" = true;
        "privacy.userContext.ui.enabled" = true;

        "security.ssl.require_safe_negotiation" = true;
    };

    # Some preferences can't be controlled using policy.
    programs.firefox.autoConfig = /*js*/ ''
        lockPref( "app.normandy.enabled", false );
        lockPref( "app.normandy.api_url", "" );
        lockPref( "app.normandy.user_id", "" );
        lockPref( "app.shield.optoutstudies.enabled", false );

        lockPref( "extensions.getAddons.showPane", false );
        lockPref( "findbar.highlightAll", true );

        lockPref( "privacy.spoof_english", 2 );
        lockPref( "privacy.donottrackheader.enabled", false );
        lockPref( "privacy.trackingprotection.enabled", true );

        lockPref( "security.mixed_content.block_active_content", true );
        lockPref( "security.mixed_content.block_display_content", true );
        lockPref( "security.ssl.treat_unsafe_negotiation_as_broken", true );

        lockPref( "toolkit.telemetry.coverage.opt-out", true );
        lockPref( "toolkit.tabbox.switchByScrolling", true );
        lockPref( "toolkit.telemetry.enabled", false );
        lockPref( "toolkit.coverage.opt-out", true );
        lockPref( "toolkit.legacyUserProfileCustomizations.stylesheets", true );
    '';

}
