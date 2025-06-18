/*
 * Drop Down (Alike)
 *
 * Kwin script to make any terminal behaves like a drop down terminal.
 *
 * The skeleton implementation is from
 * https://github.com/DvdGiessen/kwin-toggleterminal
 * as long as the idea of launching program with dbus call.
 *
 * This script has several parts that cooperate.
 *
 *      1. Window add/remove signal listener for housekeeping the window
 *      we're working with.
 *
 *      2. Shortcut handler to show/hide the window.
 *
 * The add/remove listener:
 *
 *      1) When a new window is added by kwin, if its resource_class
 *      matches the config then capture it. (workspace.windowAdded)
 *
 *          1.1) This script only works with one window, as there's only
 *          one shortcut. Newly opened window with the same resource_class
 *          will be ignored.
 *
 *      2) Attach an handler to the captured window reacting to focus changes.
 *      (win.activeChanged). It then do something to track the focus status.
 *
 *      3) When a window is closed and removed by kwin, check if it is
 *      our window and reset the script if so.
 *
 * The shortcut handler:
 *
 *      This is the essential of the whole flow.
 *
 *      1) When hit, if no window is currently captured, then launch
 *      the command in config. Hopefully it will open the window we're expecting.
 *
 *          1.1) Newly opened window will be handled by the logic metioned above.
 *
 *      2) If a window is already captured...
 *
 *          2.1) If it's active(focused), then hide it.
 *
 *          2.2) If it's hidden(minimized), then bring it up front.
 *
 *          2.3) If it's not hidden, but doesn't have focus, then focus on it.
 *          This focus status is taken care by the activeChanged listened
 *          attched to the window.
 *
 *      Thus, launch/show/hide/focus in **one single key stroke**. Excellent!
 *
 */

"use strict";

/**
 * @typedef ConfigType
 * @type {object}
 * @property {string} resource_class - Capture window with this class
 * @property {string} shortcut - Shortcut to bind on
 * @property {string} command - The command to launch when no window matches
 * @property {string[]} command_args - Arguments to the command
 */

/**
 * The config JSON in string.
 *
 * Note "@config@" is placeholder for nix to substitute in real value
 * while building.
 *
 * Q: Why not KDE's native config system?
 * A: It sucks and not declarative.
 *
 * @type {string}
 * @see {ConfigType} Type of the parsed object.
 */
const CONFIG = `@config@` ;

const NAME = "Drop Down Alike";

// Fuck dbus
const SERVICE = "@service@";
const OBJECT_PATH = "@objectPath@";
const INTERFACE = "@interface@";
const METHOD = "ExecArgs"

// Prefix program name to log message
function loggy( msg ) {
    console.log( `[${NAME}]: ${msg}` );
}

// Log with window information
function loggy_win( msg, win ) {
    loggy( `${msg}`
        + ` [name: ${win.resourceName}, id: ${win.internalId}]`
    );
}

const assertion = {
    cond: ( cond, msg ) => {
        if ( !cond ) {
            throw new Error( `[${NAME} Assertion failed: ${msg}` );
        }
        return cond;
    },
    not_null: ( val, msg ) => {
        assertion.cond(
            ( val ?? null ) !== null,
            `NotNull assertion failed: ${msg}`
        );
        return val;
    }
};

const config = {
    /**
     * @return {ConfigType}
     */
    load: () => {
        const c = JSON.parse( CONFIG );
        assertion.cond(
            Object.values( c )
                .every( v => v != null ),
            "Invalid config, some property is null"
        );
        return c;
    }
};

const winops = {
    /**
     * @param {Window} win
     */
    hide: ( win ) => {
        win.minimized = true;
        // N.B. `hidden` prevents the window from being raised
        // win.hidden = true;
    },

    /**
     * @param {Window} win
     */
    show: ( win ) => {
        const saved_all_desktop = win.onAllDesktops;
        win.onAllDesktops = true;
        win.minimized = false;
        workspace.sendClientToScreen( win, workspace.activeScreen );
        winops.focus( win );
        win.onAllDesktops = saved_all_desktop;
    },

    focus: ( win ) => {
        workspace.activeWindow = win;
        // workspace.raiseWindow( win );
    },
};

(() => {

    try {

        let captured_win = null;
        let captured_win_focused = false;

        const cfg = config.load();

        // When a new window is connected, check if it matches the config
        // and capture the window instance accordingly.
        workspace.windowAdded.connect( ( win ) => {
            // early return
            if ( !win.resourceClass.includes(cfg.resource_class) ) {
                return
            }
            if ( ( win !== captured_win ) && ( captured_win !== null ) ) {
                loggy_win( "Another window is already captured", win );
                return
            }
            captured_win = win;
            captured_win_focused = true;
            loggy_win( "Captured", win )

            captured_win.activeChanged.connect( () => {
                if ( !captured_win?.active && !captured_win?.minimized ) {
                    captured_win_focused = false;
                    loggy( "Window lost focus" );
                } else {
                    captured_win_focused = true;
                    loggy( "Window gained focus" );
                }
            } );
        } );

        // When a window is released, check if it's the window that
        // captured is being released, and wipe the captured instance
        // accordingly.
        workspace.windowRemoved.connect( ( win ) => {
            if ( win.internalId === captured_win?.internalId ) {
                captured_win = null;
                captured_win_focused = false;
                loggy_win( "Released", win )
            }
        } );

        registerShortcut(
            NAME, `[${NAME}] Toggle`, cfg.shortcut,
            () => {
                if ( !captured_win ) {
                    loggy( "No currently captured window" );
                    loggy( "Launching using dbus" );
                    callDBus(
                        SERVICE, OBJECT_PATH, INTERFACE, METHOD,
                        cfg.command, cfg.command_args,
                        ( resp_data ) => {
                            const resp = JSON.parese( resp_data );
                            assertion.cond( resp.ok, resp.err_msg );
                        }
                    )
                } else {
                    if ( captured_win.minimized ) {
                        loggy_win( "Show window", captured_win );
                        winops.show( captured_win );
                    } else if ( !captured_win_focused ) {
                        loggy_win( "Focus", captured_win );
                        winops.focus( captured_win );
                    } else {
                        loggy_win( "Hide window", captured_win );
                        winops.hide( captured_win );
                    }
                }
            }
        )

    } catch ( e ) {
        loggy( `Exception raised: ${e}` );
        return;
    }

})()
