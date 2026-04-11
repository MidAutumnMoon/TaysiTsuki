import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: 0

  property var pluginApi: null

  property bool valueTodoIntegration: pluginApi?.pluginSettings?.enableTodoIntegration ?? false
  property bool valuePincardsEnabled: pluginApi?.pluginSettings?.pincardsEnabled ?? true
  property bool valueNotecardsEnabled: pluginApi?.pluginSettings?.notecardsEnabled ?? true
  property bool valueShowCloseButton: pluginApi?.pluginSettings?.showCloseButton ?? false
  property bool valueFullscreenMode: pluginApi?.pluginSettings?.fullscreenMode ?? false
  property bool valueHidePanelBackground: pluginApi?.pluginSettings?.hidePanelBackground ?? false
  property bool valueAutoPaste: pluginApi?.pluginSettings?.autoPaste ?? false
  property bool valueAutoPasteOnRightClick: pluginApi?.pluginSettings?.autoPasteOnRightClick ?? false
  property int valueAutoPasteDelay: pluginApi?.pluginSettings?.autoPasteDelay ?? 300
  property var pendingCardColors: JSON.parse(JSON.stringify(defaultCardColors))
  property var pendingCustomColors: {
    "Text": {
      bg: "#555555",
      separator: "#000000",
      fg: "#e9e4f0"
    },
    "Image": {
      bg: "#e0b7c9",
      separator: "#000000",
      fg: "#20161f"
    },
    "Link": {
      bg: "#c7a1d8",
      separator: "#000000",
      fg: "#1a151f"
    },
    "Code": {
      bg: "#a984c4",
      separator: "#000000",
      fg: "#f3edf7"
    },
    "Color": {
      bg: "#a984c4",
      separator: "#000000",
      fg: "#f3edf7"
    },
    "Emoji": {
      bg: "#e0b7c9",
      separator: "#000000",
      fg: "#20161f"
    },
    "File": {
      bg: "#e9899d",
      separator: "#000000",
      fg: "#1e1418"
    }
  }

  // ToDo integration
  property bool todoPluginAvailable: false
  property bool enableTodoIntegration: pluginApi?.pluginSettings?.enableTodoIntegration ?? false

  // Available card types
  readonly property var cardTypes: [
    {
      key: "Text",
      name: "Text"
    },
    {
      key: "Image",
      name: "Image"
    },
    {
      key: "Link",
      name: "Link"
    },
    {
      key: "Code",
      name: "Code"
    },
    {
      key: "Color",
      name: "Color"
    },
    {
      key: "Emoji",
      name: "Emoji"
    },
    {
      key: "File",
      name: "File"
    }
  ]

  // Available colors from Color scheme
  readonly property var colorOptions: [
    {
      key: "mPrimary",
      name: "Primary"
    },
    {
      key: "mOnPrimary",
      name: "On Primary"
    },
    {
      key: "mSecondary",
      name: "Secondary"
    },
    {
      key: "mOnSecondary",
      name: "On Secondary"
    },
    {
      key: "mTertiary",
      name: "Tertiary"
    },
    {
      key: "mOnTertiary",
      name: "On Tertiary"
    },
    {
      key: "mSurface",
      name: "Surface"
    },
    {
      key: "mOnSurface",
      name: "On Surface"
    },
    {
      key: "mSurfaceVariant",
      name: "Surface Variant"
    },
    {
      key: "mOnSurfaceVariant",
      name: "On Surface Variant"
    },
    {
      key: "mOutline",
      name: "Outline"
    },
    {
      key: "mError",
      name: "Error"
    },
    {
      key: "mOnError",
      name: "On Error"
    },
    {
      key: "mHover",
      name: "Hover"
    },
    {
      key: "mOnHover",
      name: "On Hover"
    },
    {
      key: "custom",
      name: "Custom..."
    }
  ]

  // Currently selected card type for editing
  property string selectedCardType: "Text"

  // Default colors per card type
  readonly property var defaultCardColors: {
    "Text": {
      bg: "mOutline",
      separator: "mSurface",
      fg: "mOnSurface"
    },
    "Image": {
      bg: "mTertiary",
      separator: "mSurface",
      fg: "mOnTertiary"
    },
    "Link": {
      bg: "mPrimary",
      separator: "mSurface",
      fg: "mOnPrimary"
    },
    "Code": {
      bg: "mSecondary",
      separator: "mSurface",
      fg: "mOnSecondary"
    },
    "Color": {
      bg: "mSecondary",
      separator: "mSurface",
      fg: "mOnSecondary"
    },
    "Emoji": {
      bg: "mHover",
      separator: "mSurface",
      fg: "mOnHover"
    },
    "File": {
      bg: "mError",
      separator: "mSurface",
      fg: "mOnError"
    }
  }

  // Current card colors (loaded from settings or defaults)
  property var cardColors: JSON.parse(JSON.stringify(defaultCardColors))

  // Custom color values (when "custom" is selected)
  property var customColors: {
    "Text": {
      bg: "#555555",
      separator: "#000000",
      fg: "#e9e4f0"
    },
    "Image": {
      bg: "#e0b7c9",
      separator: "#000000",
      fg: "#20161f"
    },
    "Link": {
      bg: "#c7a1d8",
      separator: "#000000",
      fg: "#1a151f"
    },
    "Code": {
      bg: "#a984c4",
      separator: "#000000",
      fg: "#f3edf7"
    },
    "Color": {
      bg: "#a984c4",
      separator: "#000000",
      fg: "#f3edf7"
    },
    "Emoji": {
      bg: "#e0b7c9",
      separator: "#000000",
      fg: "#20161f"
    },
    "File": {
      bg: "#e9899d",
      separator: "#000000",
      fg: "#1e1418"
    }
  }

  // Home directory for path resolution
  readonly property string homeDir: Quickshell.env("HOME") || ""

  // Check if ToDo plugin is installed and enabled
  FileView {
    id: pluginsConfigFile
    path: root.homeDir + "/.config/noctalia/plugins.json"
    printErrors: false
    watchChanges: true
    onLoaded: {
      try {
        const content = text();
        if (content && content.length > 0) {
          const config = JSON.parse(content);
          root.todoPluginAvailable = config?.states?.todo?.enabled === true;
        }
      } catch (e) {
        root.todoPluginAvailable = false;
      }
    }
  }

  Component.onCompleted: {
    // Load saved settings
    if (pluginApi?.pluginSettings?.enableTodoIntegration !== undefined) {
      enableTodoIntegration = pluginApi.pluginSettings.enableTodoIntegration;
    }
    if (pluginApi?.pluginSettings?.cardColors) {
      try {
        const loaded = JSON.parse(JSON.stringify(pluginApi.pluginSettings.cardColors));
        cardColors = loaded;
        pendingCardColors = JSON.parse(JSON.stringify(loaded));
      } catch (e) {
        Logger.w("Clipper", "Failed to load card colors: " + e);
      }
    }
    if (pluginApi?.pluginSettings?.customColors) {
      try {
        const loaded = JSON.parse(JSON.stringify(pluginApi.pluginSettings.customColors));
        customColors = loaded;
        pendingCustomColors = JSON.parse(JSON.stringify(loaded));
      } catch (e) {
        Logger.w("Clipper", "Failed to load custom colors: " + e);
      }
    }
  }

  // Helper to get actual color value
  function getColorValue(colorKey, cardType, colorType) {
    if (colorKey === "custom") {
      return customColors[cardType]?.[colorType] || "#888888";
    }
    if (typeof Color !== "undefined" && Color[colorKey]) {
      return Color[colorKey];
    }
    return "#888888";
  }

  // Get current colors for preview
  function getPreviewBg() {
    return getColorValue(cardColors[selectedCardType]?.bg || "mOutline", selectedCardType, "bg");
  }
  function getPreviewSeparator() {
    return getColorValue(cardColors[selectedCardType]?.separator || "mSurface", selectedCardType, "separator");
  }
  function getPreviewFg() {
    return getColorValue(cardColors[selectedCardType]?.fg || "mOnSurface", selectedCardType, "fg");
  }

  // Tab bar
  NTabBar {
    id: tabBar
    Layout.fillWidth: true
    Layout.bottomMargin: Style.marginM
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: pluginApi?.tr("settings.tab-general")
      tabIndex: 0
      checked: tabBar.currentIndex === 0
    }
    NTabButton {
      text: pluginApi?.tr("settings.tab-appearance")
      tabIndex: 1
      checked: tabBar.currentIndex === 1
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Style.marginS
  }

  // Tab view
  NTabView {
    id: tabView
    currentIndex: tabBar.currentIndex

    // TAB 1: GENERAL
    ColumnLayout {
      spacing: Style.marginL

      // ===== INTEGRATIONS SECTION =====
      NText {
        text: pluginApi?.tr("settings.integrations")
        font.bold: true
        font.pointSize: Style.fontSizeL
      }

      // ToDo Integration Toggle
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.todo-integration")
        description: root.todoPluginAvailable ? pluginApi?.tr("settings.todo-description") : pluginApi?.tr("settings.todo-disabled")
        enabled: root.todoPluginAvailable
        checked: root.valueTodoIntegration
        onToggled: checked => {
                     root.valueTodoIntegration = checked;
                   }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // ===== FEATURES SECTION =====
      NText {
        text: pluginApi?.tr("settings.features")
        font.bold: true
        font.pointSize: Style.fontSizeL
      }

      // Fullscreen Mode Toggle
      NToggle {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.fullscreen-mode")
          description: pluginApi?.tr("settings.fullscreen-mode-desc")
          checked: root.valueFullscreenMode
          onToggled: checked => {
              root.valueFullscreenMode = checked;
          }
      }

      NDivider {
          Layout.fillWidth: true
      }

      // PinCards Enable Toggle
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.pincards-enabled")
        description: pluginApi?.tr("settings.pincards-desc")
        checked: root.valuePincardsEnabled
        onToggled: checked => {
                     root.valuePincardsEnabled = checked;
                   }
      }

      // Pinned items count display
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        visible: pluginApi?.pluginSettings?.pincardsEnabled ?? true

        NText {
          text: pluginApi?.tr("settings.pincards-items-count")
          font.bold: true
        }

        Item {
          Layout.fillWidth: true
        }

        NText {
          text: {
            const count = pluginApi?.mainInstance?.pinnedItems?.length || 0;
            const max = pluginApi?.mainInstance?.maxPinnedItems || 20;
            return count + " / " + max;
          }
          color: {
            const count = pluginApi?.mainInstance?.pinnedItems?.length || 0;
            const max = pluginApi?.mainInstance?.maxPinnedItems || 20;
            return count >= max ? Color.mError : Color.mOnSurface;
          }
        }
      }

      // Clear all pinned items button
      NButton {
        Layout.alignment: Qt.AlignRight
        text: pluginApi?.tr("settings.clear-all-pinned")
        icon: "trash"
        visible: pluginApi?.pluginSettings?.pincardsEnabled ?? true
        enabled: (pluginApi?.mainInstance?.pinnedItems?.length || 0) > 0
        onClicked: {
          if (pluginApi?.mainInstance) {
            // Clear all pinned items
            pluginApi.mainInstance.pinnedItems = [];
            pluginApi.mainInstance.savePinnedFile();
            pluginApi.mainInstance.pinnedRevision++;
            ToastService.showNotice(pluginApi?.tr("toast.pinned-cleared"));
          }
        }
      }

      // NoteCards Enable Toggle
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.notecards-enabled")
        description: pluginApi?.tr("settings.notecards-desc")
        checked: root.valueNotecardsEnabled
        onToggled: checked => {
                     root.valueNotecardsEnabled = checked;
                   }
      }

      // Notes count display
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        visible: pluginApi?.pluginSettings?.notecardsEnabled ?? true

        NText {
          text: pluginApi?.tr("settings.notecards-notes-count")
          font.bold: true
        }

        Item {
          Layout.fillWidth: true
        }

        NText {
          text: {
            const count = pluginApi?.mainInstance?.noteCards?.length || 0;
            const max = pluginApi?.mainInstance?.maxNoteCards || 20;
            return count + " / " + max;
          }
          color: {
            const count = pluginApi?.mainInstance?.noteCards?.length || 0;
            const max = pluginApi?.mainInstance?.maxNoteCards || 20;
            return count >= max ? Color.mError : Color.mOnSurface;
          }
        }
      }

      // Clear all notes button
      NButton {
        Layout.alignment: Qt.AlignRight
        text: pluginApi?.tr("settings.clear-all-notes")
        icon: "trash"
        visible: pluginApi?.pluginSettings?.notecardsEnabled ?? true
        enabled: (pluginApi?.mainInstance?.noteCards?.length || 0) > 0
        onClicked: {
          if (pluginApi?.mainInstance) {
            pluginApi.mainInstance.clearAllNoteCards();
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Hide Panel Background Toggle
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.hide-panel-background")
        description: pluginApi?.tr("settings.hide-panel-background-desc")
        checked: root.valueHidePanelBackground
        onToggled: checked => {
            root.valueHidePanelBackground = checked;
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // ===== AUTO-PASTE SECTION =====
      NText {
        text: pluginApi?.tr("settings.auto-paste-section")
        font.bold: true
        font.pointSize: Style.fontSizeL
      }

      // Auto-Paste Toggle
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.auto-paste")
        description: pluginApi?.tr("settings.auto-paste-desc")
        checked: root.valueAutoPaste
        onToggled: checked => {
          root.valueAutoPaste = checked;
        }
      }

      // Warning: wtype not installed (visible only when autoPaste=true and wtype unavailable)
      Rectangle {
        visible: root.valueAutoPaste && !(pluginApi?.mainInstance?.wtypeAvailable ?? false)
        Layout.fillWidth: true
        Layout.preferredHeight: warningText.implicitHeight + Style.marginM * 2
        color: (typeof Color !== "undefined") ? Qt.rgba(Color.mError.r, Color.mError.g, Color.mError.b, 0.15) : "#33CC0000"
        radius: Style.radiusS
        border.width: 1
        border.color: (typeof Color !== "undefined") ? Color.mError : "#CC0000"

        NText {
          id: warningText
          anchors.fill: parent
          anchors.margins: Style.marginM
          text: pluginApi?.tr("settings.auto-paste-warning")
          wrapMode: Text.Wrap
          color: (typeof Color !== "undefined") ? Color.mError : "#CC0000"
          font.pointSize: Style.fontSizeS
        }
      }

      // RMB Only Toggle (visible only when autoPaste=true)
      NToggle {
        visible: root.valueAutoPaste
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.auto-paste-rmb")
        description: pluginApi?.tr("settings.auto-paste-rmb-desc")
        checked: root.valueAutoPasteOnRightClick
        onToggled: checked => {
          root.valueAutoPasteOnRightClick = checked;
        }
      }

      // Paste Delay Row (visible only when autoPaste=true)
      ColumnLayout {
        visible: root.valueAutoPaste
        Layout.fillWidth: true
        spacing: Style.marginS

        NValueSlider {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.auto-paste-delay")
          description: pluginApi?.tr("settings.auto-paste-delay-desc")
          from: 100
          to: 1000
          stepSize: 50
          value: root.valueAutoPasteDelay
          text: root.valueAutoPasteDelay + " ms"
          onMoved: value => { root.valueAutoPasteDelay = Math.round(value); }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Show close button toggle
      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-close-button")
        description: pluginApi?.tr("settings.show-close-button-desc")
        checked: root.valueShowCloseButton
        onToggled: checked => {
                     root.valueShowCloseButton = checked;
                   }
      }
    }  // End General Tab

    // TAB 2: APPEARANCE
    ColumnLayout {
      spacing: Style.marginL

      // ===== APPEARANCE SECTION =====
      NText {
        text: pluginApi?.tr("settings.appearance")
        font.bold: true
        font.pointSize: Style.fontSizeL
      }

      // Card type selector
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.card-type")
        description: pluginApi?.tr("settings.card-type-desc")
        model: root.cardTypes
        currentKey: root.selectedCardType
        onSelected: key => root.selectedCardType = key
      }

      // Live Preview
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 280
        color: (typeof Color !== "undefined") ? Color.mSurfaceVariant : "#333333"
        radius: Style.radiusM

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginS

          NText {
            text: pluginApi?.tr("settings.preview")
            font.bold: true
            color: Color.mOnSurface
          }

          // Preview card
          Rectangle {
            Layout.preferredWidth: 250
            Layout.preferredHeight: 220
            Layout.alignment: Qt.AlignHCenter
            color: root.getPreviewBg()
            radius: Style.radiusM
            border.width: 2
            border.color: root.getPreviewBg()

            ColumnLayout {
              anchors.fill: parent
              spacing: 0

              // Header
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: root.getPreviewBg()
                radius: Style.radiusM

                Rectangle {
                  anchors.bottom: parent.bottom
                  width: parent.width
                  height: parent.radius
                  color: parent.color
                }

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 8

                  NIcon {
                    icon: root.selectedCardType === "Image" ? "photo" : root.selectedCardType === "Link" ? "link" : root.selectedCardType === "Code" ? "code" : root.selectedCardType === "Color" ? "palette" : root.selectedCardType === "Emoji" ? "mood-smile" : root.selectedCardType === "File" ? "file" : "align-left"
                    pointSize: 12
                    color: root.getPreviewFg()
                  }

                  NText {
                    text: root.selectedCardType
                    font.bold: true
                    color: root.getPreviewFg()
                  }

                  Item {
                    Layout.fillWidth: true
                  }

                  NIcon {
                    icon: "trash"
                    pointSize: 12
                    color: root.getPreviewFg()
                  }
                }
              }

              // Separator
              Rectangle {
                Layout.preferredWidth: parent.width - 10
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 1
                color: root.getPreviewSeparator()
              }

              // Content area
              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 8

                NText {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.top: parent.top
                  text: pluginApi?.tr("settings.sample-content")
                  wrapMode: Text.Wrap
                  color: root.getPreviewFg()
                  verticalAlignment: Text.AlignTop
                }
              }
            }
          }
        }
      }

      // Color settings
      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.bg-color")
        description: pluginApi?.tr("settings.bg-color-desc")
        model: root.colorOptions
        currentKey: root.cardColors[root.selectedCardType]?.bg || "mOutline"
        onSelected: key => {
                      if (!root.pendingCardColors[root.selectedCardType])
                      root.pendingCardColors[root.selectedCardType] = {};
                      root.pendingCardColors[root.selectedCardType].bg = key;
                      root.cardColors = JSON.parse(JSON.stringify(root.pendingCardColors));
                    }
      }

      NColorPicker {
        visible: root.cardColors[root.selectedCardType]?.bg === "custom"
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.customColors[root.selectedCardType]?.bg || "#888888"
        onColorSelected: color => {
                           if (!root.pendingCustomColors[root.selectedCardType])
                           root.pendingCustomColors[root.selectedCardType] = {};
                           root.pendingCustomColors[root.selectedCardType].bg = color.toString();
                           root.customColors = JSON.parse(JSON.stringify(root.pendingCustomColors));
                         }
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.separator-color")
        description: pluginApi?.tr("settings.separator-color-desc")
        model: root.colorOptions
        currentKey: root.cardColors[root.selectedCardType]?.separator || "mSurface"
        onSelected: key => {
                      if (!root.pendingCardColors[root.selectedCardType])
                      root.pendingCardColors[root.selectedCardType] = {};
                      root.pendingCardColors[root.selectedCardType].separator = key;
                      root.cardColors = JSON.parse(JSON.stringify(root.pendingCardColors));
                    }
      }

      NColorPicker {
        visible: root.cardColors[root.selectedCardType]?.separator === "custom"
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.customColors[root.selectedCardType]?.separator || "#000000"
        onColorSelected: color => {
                           if (!root.pendingCustomColors[root.selectedCardType])
                           root.pendingCustomColors[root.selectedCardType] = {};
                           root.pendingCustomColors[root.selectedCardType].separator = color.toString();
                           root.customColors = JSON.parse(JSON.stringify(root.pendingCustomColors));
                         }
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fg-color")
        description: pluginApi?.tr("settings.fg-color-desc")
        model: root.colorOptions
        currentKey: root.cardColors[root.selectedCardType]?.fg || "mOnSurface"
        onSelected: key => {
                      if (!root.pendingCardColors[root.selectedCardType])
                      root.pendingCardColors[root.selectedCardType] = {};
                      root.pendingCardColors[root.selectedCardType].fg = key;
                      root.cardColors = JSON.parse(JSON.stringify(root.pendingCardColors));
                    }
      }

      NColorPicker {
        visible: root.cardColors[root.selectedCardType]?.fg === "custom"
        Layout.preferredWidth: Style.sliderWidth
        Layout.preferredHeight: Style.baseWidgetSize
        selectedColor: root.customColors[root.selectedCardType]?.fg || "#e9e4f0"
        onColorSelected: color => {
                           if (!root.pendingCustomColors[root.selectedCardType])
                           root.pendingCustomColors[root.selectedCardType] = {};
                           root.pendingCustomColors[root.selectedCardType].fg = color.toString();
                           root.customColors = JSON.parse(JSON.stringify(root.pendingCustomColors));
                         }
      }

      // Reset button
      NButton {
        Layout.alignment: Qt.AlignRight
        text: pluginApi?.tr("settings.reset-defaults")
        icon: "refresh"
        onClicked: {
          const defaults = JSON.parse(JSON.stringify(root.defaultCardColors));
          const defaultCustom = {
            "Text": {
              bg: "#555555",
              separator: "#000000",
              fg: "#e9e4f0"
            },
            "Image": {
              bg: "#e0b7c9",
              separator: "#000000",
              fg: "#20161f"
            },
            "Link": {
              bg: "#c7a1d8",
              separator: "#000000",
              fg: "#1a151f"
            },
            "Code": {
              bg: "#a984c4",
              separator: "#000000",
              fg: "#f3edf7"
            },
            "Color": {
              bg: "#a984c4",
              separator: "#000000",
              fg: "#f3edf7"
            },
            "Emoji": {
              bg: "#e0b7c9",
              separator: "#000000",
              fg: "#20161f"
            },
            "File": {
              bg: "#e9899d",
              separator: "#000000",
              fg: "#1e1418"
            }
          };
          root.pendingCardColors = defaults;
          root.pendingCustomColors = defaultCustom;
          root.cardColors = JSON.parse(JSON.stringify(defaults));
          root.customColors = JSON.parse(JSON.stringify(defaultCustom));
        }
      }
    }  // End Appearance Tab

  }  // End NTabView

  function saveSettings() {
    if (!pluginApi)
      return;

    pluginApi.pluginSettings.enableTodoIntegration = root.valueTodoIntegration;
    pluginApi.pluginSettings.pincardsEnabled = root.valuePincardsEnabled;
    pluginApi.pluginSettings.notecardsEnabled = root.valueNotecardsEnabled;
    pluginApi.pluginSettings.showCloseButton = root.valueShowCloseButton;
    pluginApi.pluginSettings.fullscreenMode = root.valueFullscreenMode;
    pluginApi.pluginSettings.hidePanelBackground = root.valueHidePanelBackground;
    pluginApi.pluginSettings.autoPaste = root.valueAutoPaste;
    pluginApi.pluginSettings.autoPasteOnRightClick = root.valueAutoPasteOnRightClick;
    pluginApi.pluginSettings.autoPasteDelay = root.valueAutoPasteDelay;
    pluginApi.pluginSettings.cardColors = JSON.parse(JSON.stringify(root.pendingCardColors));
    pluginApi.pluginSettings.customColors = JSON.parse(JSON.stringify(root.pendingCustomColors));

    if (pluginApi.mainInstance) {
      pluginApi.mainInstance.showCloseButton = root.valueShowCloseButton;
    }

    pluginApi.saveSettings();
  }
}
