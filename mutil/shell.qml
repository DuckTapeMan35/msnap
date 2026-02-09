import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Screenshot tool popup for quickshell
// Integrates with mango-utils/mshot for capture functionality
PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: true
  color: "transparent"

  // Layer shell configuration
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "screencast-tool"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // ===== STATE =====
  property bool isScreenshotMode: true
  property string captureMode: "region"

  // Region selection state
  property bool isRegionSelected: false
  property int selectedX: 0
  property int selectedY: 0
  property int selectedWidth: 0
  property int selectedHeight: 0

  // Reset region selection when mode changes
  onCaptureModeChanged: isRegionSelected = false
  onIsScreenshotModeChanged: isRegionSelected = false

  // ===== THEME =====
  readonly property color bgColor: "#1a1b26"
  readonly property color surfaceColor: "#24283b"
  readonly property color accentColor: isScreenshotMode ? "#7aa2f7" : "#f7768e"
  readonly property color textColor: "#a9b1d6"
  readonly property color textMuted: "#565f89"
  readonly property color borderColor: "#414868"

  // ===== FUNCTIONS =====
  function close() {
    visible = false
    Qt.quit()
  }

  function executeAction() {
    if (!isScreenshotMode) {
      close()
      return
    }

    // Region mode: two-step process
    if (captureMode === "region") {
      if (!isRegionSelected) {
        // Step 1: Open region selector
        root.visible = false
        regionSelector.open()
        return
      } else {
        // Step 2: Execute with selected region
        var geometry = selectedX + "," + selectedY + " " + selectedWidth + "x" + selectedHeight
        Quickshell.execDetached(["mshot", "-r", "-g", geometry])
        close()
        return
      }
    }

    // Window and Screen modes: direct execution
    var args = ["mshot"]
    if (captureMode === "window") {
      args.push("-w")
    }
    // screen mode: no args needed

    Quickshell.execDetached(args)
    close()
  }

  // ===== REGION SELECTOR =====
  RegionSelector {
    id: regionSelector

    onSelectionComplete: (x, y, w, h) => {
      selectedX = x
      selectedY = y
      selectedWidth = w
      selectedHeight = h
      isRegionSelected = true
      regionSelector.close()
      root.visible = true
    }

    // When user cancels (Esc or right-click in RegionSelector)
    onCancelled: {
      // Option A: restore shell panel and keep tool open:
      root.visible = true

      // If you instead want Esc in the selector to abort the whole tool,
      // replace the above line with:
      // root.close()
    }
  }

  // ===== UI =====

  // Full-screen container with keyboard focus
  Item {
    anchors.fill: parent
    focus: true

    Keys.onPressed: (event) => {
      if (event.key === Qt.Key_Escape) {
        root.close()
        event.accepted = true
      }
    }

    Component.onCompleted: {
      forceActiveFocus()
    }

    // Full-screen click catcher - closes when clicking outside popup
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: root.close()

      // Main popup container - sizes based on mutil design
      Rectangle {
        id: popupContainer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: 280
        height: contentLayout.implicitHeight + 24
        color: bgColor
        radius: 12
        border.width: 1
        border.color: borderColor

        // Block clicks from passing through to background
        MouseArea {
          anchors.fill: parent
        }

        // Content
        ColumnLayout {
          id: contentLayout
          anchors.centerIn: parent
          spacing: 12

          // Mode Toggle (Photo/Video) - matching mutil sizing
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 244
            Layout.preferredHeight: 36
            color: surfaceColor
            radius: 8

            RowLayout {
              anchors.fill: parent
              anchors.margins: 4
              spacing: 6

              // Photo button
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: isScreenshotMode ? accentColor : "transparent"
                radius: 6

                Text {
                  anchors.centerIn: parent
                  text: "Screenshot"
                  color: isScreenshotMode ? bgColor : textColor
                  font.pixelSize: 12
                  font.bold: isScreenshotMode
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: isScreenshotMode = true
                }
              }

              // Video button
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: !isScreenshotMode ? accentColor : "transparent"
                radius: 6

                Text {
                  anchors.centerIn: parent
                  text: "Record"
                  color: !isScreenshotMode ? bgColor : textColor
                  font.pixelSize: 12
                  font.bold: !isScreenshotMode
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: isScreenshotMode = false
                }
              }
            }
          }

          // Capture Mode Icons - matching mutil grid layout
          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            // Region
            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 64
              color: captureMode === "region"
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                       : surfaceColor
              radius: 8
              border.width: captureMode === "region" ? 2 : 0
              border.color: accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "◰"
                  color: captureMode === "region" ? accentColor : textColor
                  font.pixelSize: 20
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Region"
                  color: captureMode === "region" ? accentColor : textMuted
                  font.pixelSize: 11
                  font.bold: captureMode === "region"
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: captureMode = "region"
              }
            }

            // Window
            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 64
              color: captureMode === "window"
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                       : surfaceColor
              radius: 8
              border.width: captureMode === "window" ? 2 : 0
              border.color: accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "□"
                  color: captureMode === "window" ? accentColor : textColor
                  font.pixelSize: 20
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Window"
                  color: captureMode === "window" ? accentColor : textMuted
                  font.pixelSize: 11
                  font.bold: captureMode === "window"
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: captureMode = "window"
              }
            }

            // Screen
            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 64
              color: captureMode === "screen"
                       ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                       : surfaceColor
              radius: 8
              border.width: captureMode === "screen" ? 2 : 0
              border.color: accentColor

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "⛶"
                  color: captureMode === "screen" ? accentColor : textColor
                  font.pixelSize: 20
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Screen"
                  color: captureMode === "screen" ? accentColor : textMuted
                  font.pixelSize: 11
                  font.bold: captureMode === "screen"
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: captureMode = "screen"
              }
            }
          }

          // Selected region info (only for region mode when selected)
          Text {
            Layout.alignment: Qt.AlignHCenter
            visible: captureMode === "region" && isRegionSelected
            text: selectedWidth + "x" + selectedHeight
            color: accentColor
            font.pixelSize: 11
            font.bold: true
          }

          // Action Button - matching mutil sizing
          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 244
            Layout.preferredHeight: 36
            color: accentColor
            radius: 8

            RowLayout {
              anchors.centerIn: parent
              spacing: 8

              Text {
                text: isScreenshotMode ? "◉" : "⏺"
                color: bgColor
                font.pixelSize: 16
              }

              Text {
                text: {
                  if (!isScreenshotMode) return "Start Recording"
                  if (captureMode === "region" && !isRegionSelected) return "Select Region"
                  return "Capture"
                }
                color: bgColor
                font.pixelSize: 12
                font.bold: true
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: executeAction()
            }
          }
        }
      }
    }
  }
}
