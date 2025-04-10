/*
 * MidAutumnMoon's Firefox preferences!
 */


////
//// Meta stuff
////
pref( 'browser.aboutConfig.showWarning', false );



////
//// Performanc tuning
////
pref( 'browser.cache.disk.enable',           false );
pref( 'browser.cache.disk_cache_ssla',       false );
pref( 'media.memory_cache_max_size',         32768 );;
pref( 'browser.cache.memory.max_entry_size', -1 );
pref( 'browser.cache.max_shutdown_io_lag',   3 );

pref( 'browser.privatebrowsing.forceMediaMemoryCache', true );

pref( 'gfx.webrender.all',                 true );
pref( 'gfx.webrender.compositor',          true );
pref( 'gfx.webrender.enabled',             true );
pref( 'gfx.webrender.precache-shaders',    true );
pref( 'gfx.canvas.accelerated',            true );
pref( 'gfx.canvas.accelerated.gpu-path-size', 8 );
pref( 'gfx.color_management.enablev4',     true );
pref( 'gfx.color_management.native_srgb',  true );
pref( 'gfx.offscreencanvas.enabled',       true );

pref( 'layers.acceleration.force-enabled', true );
pref( 'layers.gpu-process.enabled',        true );
pref( 'layers.gpu-process.force-enabled',  true );

pref( 'media.ffvpx.enabled',                         false );
pref( 'media.ffmpeg.vaapi.enabled',                  true );
pref( 'media.hardware-video-decoding.force-enabled', true );

pref( 'network.http.max-persistent-connections-per-server',  8 );
pref( 'network.http.max-persistent-connections-per-proxy',  64 );
pref( 'network.buffer.cache.size',  65536 );

pref( 'browser.sessionhistory.max_entries', 8 );
pref( 'browser.tabs.min_inactive_duration_before_unload', 24000 );

pref( 'accessibility.force_disabled', 1 );
pref( 'dom.ipc.forkserver.enable', true );

pref( 'javascript.options.blinterp.threshold', 5 );
pref( 'javascript.options.baselinejit.threshold', 50 );
pref( 'javascript.options.ion.threshold', 5000 );



////
//// UI & UX
////
pref( 'browser.preferences.experimental',                 true );
pref( 'browser.protections_panel.infoMessage.seen',       true );
pref( 'browser.discovery.enabled',                        false );
pref( 'browser.urlbar.quicksuggest.scenario',             'history' );
pref( 'browser.urlbar.suggest.quicksuggest.nonsponsored', false );
pref( 'browser.urlbar.suggest.quicksuggest.sponsored',    false );
pref( 'browser.urlbar.decodeURLsOnCopy',                  true );

pref( 'browser.urlbar.keepPanelOpenDuringImeComposition', true );

pref( 'browser.urlbar.trimURLs',            false );
pref( 'browser.urlbar.suggest.searches',    false );
pref( 'browser.urlbar.suggest.engines',     false );
pref( 'browser.urlbar.suggest.openpage',    false );
pref( 'browser.urlbar.suggest.topsites',    false );
pref( 'browser.urlbar.suggest.calculator',  false );
pref( 'browser.search.suggest.enabled',     false );
pref( 'browser.urlbar.groupLabels.enabled', false );

pref( 'browser.urlbar.resultMenu.keyboardAccessible', false );

pref( 'toolkit.tabbox.switchByScrolling', true );
pref( 'browser.tabs.insertAfterCurrent',  true );
pref( 'findbar.highlightAll',             true );

pref( 'general.autoScroll',                      true );
pref( 'general.smoothScroll.msdPhysics.enabled', true );
pref( 'mousewheel.default.delta_multiplier_x',   92 )
pref( 'mousewheel.default.delta_multiplier_y',   92 )

pref( 'media.videocontrols.picture-in-picture.audio-toggle.enabled',     true );
pref( 'media.videocontrols.picture-in-picture.video-toggle.always-show', true );
pref( 'media.videocontrols.picture-in-picture.video-toggle.has-used',    true );

pref( 'general.disable_button.default_browser', true );

pref( 'widget.non-native-theme.gtk.scrollbar.allow-buttons', true );

pref( 'security.insecure_password.ui.enabled',              true );
pref( 'security.insecure_field_warning.contextual.enabled', true );

pref( 'browser.fixup.hide_user_pass',    true )
pref( 'browser.fixup.alternate.enabled', false )

pref( 'devtools.theme', 'dark' );

pref( 'browser.urlbar.autoFill.adaptiveHistory.enabled', true );



////
//// Security & Privacy?
////
lockPref( 'browser.safebrowsing.downloads.enabled', false );
lockPref( 'browser.safebrowsing.malware.enabled',   false );
lockPref( 'browser.safebrowsing.downloads.remote.block_potentially_unwanted', false );

pref( 'privacy.partition.serviceWorkers', true )

pref( 'dom.event.clipboardevents.enabled', true );
pref( 'dom.security.featurePolicy.experimental.enabled', true );

lockPref( 'geo.enabled',            false );
lockPref( 'beacon.enabled',         false );
lockPref( 'device.sensors.enabled', false );
lockPref( 'browser.send_pings',     false );
lockPref( 'browser.send_pings.require_same_host', true );

// Modern websites suck
pref( 'dom.enable_performance',                   false );
pref( 'dom.enable_performance_navigation_timing', false );
pref( 'dom.enable_performance_observer',          false );
pref( 'dom.battery.enabled',        false );
pref( 'dom.enable_user_timing',     false );
pref( 'dom.enable_event_timing',    false );
pref( 'dom.enable_resource_timing', false );
pref( 'dom.netinfo.enabled',        false );
pref( 'dom.network.enabled',        false );
pref( 'dom.telephony.enabled',      false );
pref( 'dom.vr.enabled',             false );
pref( 'dom.webaudio.enabled',       true );
pref( 'dom.allow_cut_copy',         true );
pref( 'dom.webshare.enabled',       false );

pref( 'media.webspeech.recognition.enable', false );
pref( 'media.webspeech.synth.enabled',      false );

pref( 'intl.accept_languages', 'en-US, en' );
pref( 'intl.locale.requested', 'en-US' );
pref( 'intl.locale.matchOS',   false )

pref( 'media.eme.enabled',             false );
pref( 'media.autoplay.default',        5 );
pref( 'media.navigator.enabled',       false );
pref( 'media.navigator.video.enabled', false );
pref( 'media.peerconnection.enabled',  false );
pref( 'media.video_stats.enabled',     false )

pref( 'media.navigator.mediadatadecoder_vpx_enabled', false );
pref( 'media.getusermedia.screensharing.enabled',     false );
pref( 'media.getusermedia.audiocapture.enabled',      false );

pref( 'network.dns.disablePrefetch',    true );
pref( 'network.predictor.enabled',      false );
pref( 'network.prefetch-next',          false );
pref( 'network.proxy.socks_remote_dns', true );
pref( 'network.manage-offline-status',  false );

pref( 'pdfjs.enableScripting', false );
pref( 'pdfjs.firstRun',        false );

pref( 'privacy.spoof_english',                             1 );
pref( 'privacy.trackingprotection.enabled',                true );
pref( 'privacy.trackingprotection.pbmode.enabled',         true );
pref( 'privacy.trackingprotection.socialtracking.enabled', true );
pref( 'privacy.donottrackheader.enabled',                  false );

pref( 'security.mixed_content.block_active_content',  true );
pref( 'security.mixed_content.block_display_content', true );

pref( 'network.cookie.thirdparty.sessionOnly', true );
pref( 'network.cookie.cookieBehavior.pbmode',  2 );
pref( 'network.cookie.lifetimePolicy',         2 )

pref( 'network.IDN_show_punycode', true );

pref( 'dom.security.https_only_mode', true );
pref( 'dom.security.https_only_mode_send_http_background_request', false );

pref( 'security.OCSP.enabled', 1 );
pref( 'security.OCSP.require', true );

pref( 'security.ssl.enable_ocsp_stapling',               true );
pref( 'security.ssl.require_safe_negotiation',           true );
pref( 'security.ssl.treat_unsafe_negotiation_as_broken', true );

pref( 'security.security.cert_pinning.enforcement_level', 2 );
pref( 'security.pki.sha1_enforcement_level',              1 );

// set it to "true" to unleash the ultimate power
pref( 'network.http.referer.spoofSource', false );
pref( 'network.http.referer.trimmingPolicy',        2 );
pref( 'network.http.referer.XOriginTrimmingPolicy', 2 );

pref( 'browser.search.countryCode', 'US' );
pref( 'browser.search.region',      'US' );
pref( 'browser.search.geoip.url',   '' );

pref( 'browser.newtabpage.activity-stream.default.sites', '' );
pref( 'browser.newtabpage.activity-stream.discoverystream.enabled', false );
pref( 'browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons',   false );
pref( 'browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features', false );

lockPref( 'privacy.userContext.enabled', true );
pref( 'privacy.userContext.ui.enabled',  true );

pref( 'font.system.whitelist', '' );

pref( 'browser.region.network.url',    '' )
pref( 'browser.region.update.enabled', false )
pref( 'browser.region.update.region',  'JP' )

pref( 'browser.places.speculativeConnect.enabled', false );
pref( 'browser.urlbar.speculativeConnect.enabled', false );

pref( 'middlemouse.contentLoadURL', false );



////
//// Telemetry etc.
////
lockPref( 'browser.ping-centre.telemetry', false );

lockPref( 'toolkit.telemetry.enabled',                       false );
lockPref( 'toolkit.telemetry.bhrPing.enabled',               false );
lockPref( 'toolkit.telemetry.newProfilePing.enabled',        false );
lockPref( 'toolkit.telemetry.firstShutdownPing.enabled',     false );
lockPref( 'toolkit.telemetry.reportingpolicy.firstRun',      false );
lockPref( 'toolkit.telemetry.updatePing.enabled',            false );
lockPref( 'toolkit.telemetry.archive.enabled',               false );
lockPref( 'toolkit.telemetry.shutdownPingSender.enabled',    false );
lockPref( 'toolkit.telemetry.pioneer-new-studies-available', false );

lockPref( 'toolkit.coverage.opt-out', true );

lockPref( 'app.normandy.enabled',                    false );
lockPref( 'app.normandy.api_url',                    '' );
lockPref( 'app.shield.optoutstudies.enabled',        false );
lockPref( 'extensions.shield-recipe-client.enabled', false );

lockPref( 'network.allow-experiments',      false );

pref( 'breakpad.reportURL', '' );
pref( 'browser.tabs.crashReporting.sendReport', false );
pref( 'browser.crashReports.unsubmittedCheck.enabled', false );

pref( 'privacy.sanitize.timeSpan',           0 );
pref( 'privacy.sanitize.sanitizeOnShutdown', false );
pref( 'privacy.clearOnShutdown.cache',       true );
pref( 'privacy.clearOnShutdown.cookies',     true );
pref( 'privacy.clearOnShutdown.downloads',   true );
pref( 'privacy.clearOnShutdown.formdata',    false );
pref( 'privacy.clearOnShutdown.history',     false );
pref( 'privacy.clearOnShutdown.offlineApps', true );
pref( 'privacy.clearOnShutdown.sessions',    true );
pref( 'privacy.clearOnShutdown.openWindows', false );

pref( 'privacy.cpd.offlineApps', true );
pref( 'privacy.cpd.cache',       true );
pref( 'privacy.cpd.cookies',     false );
pref( 'privacy.cpd.downloads',   true );
pref( 'privacy.cpd.formdata',    true );
pref( 'privacy.cpd.history',     true );
pref( 'privacy.cpd.sessions',    true );



////
//// Whatever
////
pref( 'browser.uitour.enabled', false );
pref( 'browser.shell.checkDefaultBrowser', false );
pref( 'browser.shell.shortcutFavicons',    false );

pref( 'browser.quitShortcut.disabled', true );
pref( 'browser.warnOnQuit', true );
pref( 'browser.warnOnQuitShortcut', true );

pref( 'accessibility.typeaheadfind',           false );
pref( 'accessibility.typeaheadfind.autostart', false );
pref( 'accessibility.typeaheadfind.manual',    false );

pref( 'accessibility.browsewithcaret_shortcut.enabled', false );

// Ref: https://superuser.com/questions/7327/how-to-add-a-custom-search-engine-to-firefox
// Google without AI summary & NCR
// https://www.google.com/search?q=%s&udm=14&pws=0&gl=us&gws_rd=cr&safe=off
pref( "browser.urlbar.update2.engineAliasRefresh", true );

// Prevent pinned tabs from autoloading on startup
pref( "browser.sessionstore.restore_pinned_tabs_on_demand", true );

// Add copy highlight (text fragment) to right click menu
pref( "dom.text_fragments.create_text_fragment.enabled", true );
