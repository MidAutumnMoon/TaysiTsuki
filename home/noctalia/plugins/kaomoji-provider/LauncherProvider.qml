import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  // Plugin API provided by PluginService
  property var pluginApi: null

  // Provider metadata
  property string name: "Kaomoji"
  property var launcher: null
  property bool handleSearch: false
  property string supportedLayouts: "list"  // Only list layout for kaomoji
  property bool supportsAutoPaste: true

  // Browsing state
  property string selectedCategory: "all"
  property bool isBrowsingMode: false

  // Database
  property var database: ({})
  property bool loaded: false
  property bool loading: false

  // Categories based on most common tags
  property var categories: ["all", "smiling", "heart", "blush", "kiss", "bear", "cat", "sad", "crying", "anger", "music", "hug", "surprised"]

  property var categoryIcons: ({
    "all": "list",
    "smiling": "mood-smile",
    "heart": "heart",
    "blush": "mood-heart",
    "kiss": "mood-tongue",
    "bear": "paw",
    "cat": "cat",
    "sad": "mood-sad",
    "crying": "mood-cry",
    "anger": "mood-angry",
    "music": "music",
    "hug": "friends",
    "surprised": "mood-surprised"
  })

  function getCategoryName(category) {
    const names = {
      "all": "All",
      "smiling": "Happy",
      "heart": "Love",
      "blush": "Blush",
      "kiss": "Kiss",
      "bear": "Bear",
      "cat": "Cat",
      "sad": "Sad",
      "crying": "Crying",
      "anger": "Angry",
      "music": "Music",
      "hug": "Hug",
      "surprised": "Surprised"
    };
    return names[category] || category;
  }

  // Load database on init
  function init() {
    Logger.i("KaomojiProvider", "init called, pluginDir:", pluginApi?.pluginDir);
    if (pluginApi && pluginApi.pluginDir && !loading && !loaded) {
      loading = true;
      databaseLoader.path = pluginApi.pluginDir + "/database.json";
    }
  }

  // File loader for database
  FileView {
    id: databaseLoader
    path: ""
    watchChanges: false

    onLoaded: {
      try {
        root.database = JSON.parse(text());
        root.loaded = true;
        root.loading = false;
        Logger.i("KaomojiProvider", "Database loaded,", Object.keys(root.database).length, "entries");
        if (root.launcher) {
          root.launcher.updateResults();
        }
      } catch (e) {
        Logger.e("KaomojiProvider", "Failed to parse database:", e);
        root.loading = false;
      }
    }
  }

  function selectCategory(category) {
    selectedCategory = category;
    if (launcher) {
      launcher.updateResults();
    }
  }

  function onOpened() {
    selectedCategory = "all";
  }

  // Check if this provider handles the command
  function handleCommand(searchText) {
    return searchText.startsWith(">kaomoji");
  }

  // Return available commands when user types ">"
  function commands() {
    return [{
      "name": ">kaomoji",
      "description": "Browse and search kaomoji emoticons",
      "icon": "mood-wink",
      "isTablerIcon": true,
      "isImage": false,
      "onActivate": function() {
        launcher.setSearchText(">kaomoji ");
      }
    }];
  }

  // Get search results
  function getResults(searchText) {
    if (!searchText.startsWith(">kaomoji")) {
      return [];
    }

    if (loading) {
      return [{
        "name": "Loading...",
        "description": "Loading kaomoji database...",
        "icon": "refresh",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {}
      }];
    }

    if (!loaded) {
      return [{
        "name": "Database not loaded",
        "description": "Try reopening the launcher",
        "icon": "alert-circle",
        "isTablerIcon": true,
        "isImage": false,
        "onActivate": function() {
          root.init();
        }
      }];
    }

    var query = searchText.slice(8).trim().toLowerCase();
    var results = [];

    if (query === "") {
      // Browse mode - show kaomoji by category
      isBrowsingMode = true;
      var keys = Object.keys(database);

      if (selectedCategory === "all") {
        // Show first 100 kaomoji
        for (var i = 0; i < Math.min(keys.length, 100); i++) {
          results.push(formatKaomojiEntry(keys[i], database[keys[i]]));
        }
      } else {
        // Filter by category
        var count = 0;
        for (var j = 0; j < keys.length && count < 100; j++) {
          var entry = database[keys[j]];
          var tags = (entry.new_tags || []).concat(entry.original_tags || []);
          if (tags.indexOf(selectedCategory) !== -1) {
            results.push(formatKaomojiEntry(keys[j], entry));
            count++;
          }
        }
      }
    } else {
      // Search mode
      isBrowsingMode = false;
      var keys = Object.keys(database);
      var count = 0;

      for (var k = 0; k < keys.length && count < 50; k++) {
        var kaomoji = keys[k];
        var entry = database[kaomoji];
        var tags = (entry.new_tags || []).concat(entry.original_tags || []);
        var tagString = tags.join(" ").toLowerCase();

        if (tagString.indexOf(query) !== -1) {
          results.push(formatKaomojiEntry(kaomoji, entry));
          count++;
        }
      }
    }

    return results;
  }

  // Format a kaomoji entry for the results list
  function formatKaomojiEntry(kaomoji, entry) {
    var tags = entry.new_tags || [];
    var description = tags.length > 0 ? tags.slice(0, 5).join(", ") : "";

    return {
      "name": kaomoji,
      "description": description,
      "icon": null,
      "isImage": false,
      "hideIcon": true,         // No icon needed in list view
      "singleLine": true,       // Clip tall kaomoji to single line
      "onActivate": function() {
        // Copy to clipboard using wl-copy
        // Escape single quotes for shell
        var escaped = kaomoji.replace(/'/g, "'\\''");
        Quickshell.execDetached(["sh", "-c", "printf '%s' '" + escaped + "' | wl-copy"]);
        launcher.close();
      }
    };
  }
}
