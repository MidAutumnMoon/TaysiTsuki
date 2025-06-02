#
# Policies Yes!
#

{

    DisableFirefoxStudies = true;
    DisablePocket         = true;
    DisableTelemetry      = true;

    DontCheckDefaultBrowser = true;
    RequestedLocales        = [ "en-US" ];

    Homepage = {
        StartPage = "previous-session";
    };

    FirefoxHome = {
        Locked            = true;
        TopSites          = false;
        SponsoredTopSites = false;
        Highlights        = false;
        Pocket            = false;
        SponsoredPocket   = false;
        Snippets          = false;
    };

    UserMessaging = {
        WhatsNew                 = false;
        FeatureRecommendations   = false;
        ExtensionRecommendations = false;
        UrlbarInterventions      = false;
        SkipOnboarding           = true;
    };

    Proxy = {
        UseProxyForDNS = true;
    };

    EnableTrackingProtection = {
        Value          = true;
        Cryptomining   = true;
        Fingerprinting = true;
    };

    Permissions = {
        Camera = {
            BlockNewRequests = true;
        };
        Microphone = {
            BlockNewRequests = true;
        };
        Location = {
            BlockNewRequests = true;
        };
    };

    NoDefaultBookmarks = true;

}
