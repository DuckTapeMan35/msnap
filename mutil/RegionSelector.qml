import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "region-selector"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  signal selectionComplete(int x, int y, int width, int height)
  signal cancelled()

  property bool isSelecting: false
  property bool isMoving: false
  property bool isResizing: false
  property int activeHandle: -1    // 0=TL, 1=TR, 2=BL, 3=BR

  property int startX: 0
  property int startY: 0
  property int currentX: 0
  property int currentY: 0

  property int selX: 0
  property int selY: 0
  property int selWidth: 0
  property int selHeight: 0

  property int moveOffsetX: 0
  property int moveOffsetY: 0

  property bool hasSelection: selWidth > 0 && selHeight > 0

  function open() {
    visible = true
    isSelecting = false
    isMoving = false
    isResizing = false
    activeHandle = -1
    startX = 0
    startY = 0
    currentX = 0
    currentY = 0
    moveOffsetX = 0
    moveOffsetY = 0
    defaultSelectionTimer.start()
  }

  Timer {
    id: defaultSelectionTimer
    interval: 1
    running: false
    repeat: false

    onTriggered: {
      const defaultWidth = 400
      const defaultHeight = 300
      const parentItem = root.contentItem

      if (parentItem) {
        root.selX = Math.floor((parentItem.width - defaultWidth) / 2)
        root.selY = Math.floor((parentItem.height - defaultHeight) / 2)
        root.selWidth = defaultWidth
        root.selHeight = defaultHeight
      }
    }
  }

  function close() {
    visible = false
    isSelecting = false
    isMoving = false
    isResizing = false
    activeHandle = -1
  }

  function confirmSelection() {
    if (hasSelection)
      selectionComplete(selX, selY, selWidth, selHeight)
  }

  function getSelection() {
    return {
      x: selX,
      y: selY,
      width: selWidth,
      height: selHeight,
      valid: hasSelection
    }
  }

  function updateSelection() {
    selX = Math.min(startX, currentX)
    selY = Math.min(startY, currentY)
    selWidth = Math.abs(currentX - startX)
    selHeight = Math.abs(currentY - startY)
  }

  Item {
    anchors.fill: parent
    focus: true

    Keys.onPressed: (event) => {
      if (event.key === Qt.Key_Escape) {
        root.cancelled()
        root.close()
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.confirmSelection()
        event.accepted = true
      }
    }

    Component.onCompleted: forceActiveFocus()

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      hoverEnabled: true
      z: -2

      cursorShape: {
        if (root.isSelecting)
          return Qt.CrossCursor
        if (root.hasSelection &&
            mouseX >= root.selX && mouseX <= root.selX + root.selWidth &&
            mouseY >= root.selY && mouseY <= root.selY + root.selHeight) {
          return Qt.ArrowCursor
        }
        return Qt.CrossCursor
      }

      onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
          root.cancelled()
          root.close()
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.5)
      z: -1
    }

    Rectangle {
      id: selectionRect
      x: root.selX
      y: root.selY
      width: root.selWidth
      height: root.selHeight
      visible: root.hasSelection
      color: "transparent"
      border.width: 2
      border.color: "#ffffff"
      z: 5

      MouseArea {
        anchors.fill: parent
        enabled: root.hasSelection && !root.isSelecting && !root.isResizing
        cursorShape: root.isMoving ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        hoverEnabled: true

        onPressed: (mouse) => {
          root.isMoving = true
          root.moveOffsetX = mouse.x
          root.moveOffsetY = mouse.y
        }

        onPositionChanged: (mouse) => {
          if (!root.isMoving)
            return

          let newX = root.selX + mouse.x - root.moveOffsetX
          let newY = root.selY + mouse.y - root.moveOffsetY
          const width = root.selWidth
          const height = root.selHeight

          newX = Math.max(0, Math.min(newX, parent.parent.width - width))
          newY = Math.max(0, Math.min(newY, parent.parent.height - height))

          root.selX = newX
          root.selY = newY
        }

        onReleased: root.isMoving = false
      }
    }

    Rectangle {
      x: Math.min(Math.max(root.selX + 10, 10), parent.width - width - 10)
      y: Math.max(root.selY - 35, 10)
      width: dimensionsText.implicitWidth + 16
      height: dimensionsText.implicitHeight + 8
      visible: root.hasSelection
      color: Qt.rgba(0, 0, 0, 0.8)
      radius: 4
      z: 10

      Text {
        id: dimensionsText
        anchors.centerIn: parent
        text: root.selWidth + "x" + root.selHeight
        color: "#ffffff"
        font.pixelSize: 12
        font.bold: true
      }
    }

    // Top-Left
    Rectangle {
      x: root.selX - 6
      y: root.selY - 6
      width: 12
      height: 12
      radius: 6
      visible: root.hasSelection && !root.isSelecting
      color: "#ffffff"
      border.width: 2
      border.color: "#000000"
      z: 10

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.SizeFDiagCursor
        hoverEnabled: true

        onPressed: {
          root.isResizing = true
          root.activeHandle = 0
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Top-Right
    Rectangle {
      x: root.selX + root.selWidth - 6
      y: root.selY - 6
      width: 12
      height: 12
      radius: 6
      visible: root.hasSelection && !root.isSelecting
      color: "#ffffff"
      border.width: 2
      border.color: "#000000"
      z: 10

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.SizeBDiagCursor
        hoverEnabled: true

        onPressed: {
          root.isResizing = true
          root.activeHandle = 1
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Bottom-Left
    Rectangle {
      x: root.selX - 6
      y: root.selY + root.selHeight - 6
      width: 12
      height: 12
      radius: 6
      visible: root.hasSelection && !root.isSelecting
      color: "#ffffff"
      border.width: 2
      border.color: "#000000"
      z: 10

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.SizeBDiagCursor
        hoverEnabled: true

        onPressed: {
          root.isResizing = true
          root.activeHandle = 2
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Bottom-Right
    Rectangle {
      x: root.selX + root.selWidth - 6
      y: root.selY + root.selHeight - 6
      width: 12
      height: 12
      radius: 6
      visible: root.hasSelection && !root.isSelecting
      color: "#ffffff"
      border.width: 2
      border.color: "#000000"
      z: 10

      MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.SizeFDiagCursor
        hoverEnabled: true

        onPressed: {
          root.isResizing = true
          root.activeHandle = 3
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 20
      text: root.hasSelection
            ? "Adjust selection • Enter to confirm • Esc to cancel"
            : "Drag to select area • Esc to cancel"
      color: "#ffffff"
      font.pixelSize: 11
      z: 10
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      hoverEnabled: false
      z: 0

      onPressed: (mouse) => {
        const outsideSelection =
          !root.hasSelection ||
          mouse.x < root.selX || mouse.x > root.selX + root.selWidth ||
          mouse.y < root.selY || mouse.y > root.selY + root.selHeight

        if (mouse.button === Qt.LeftButton && !root.isResizing && outsideSelection) {
          root.isSelecting = true
          root.startX = mouse.x
          root.startY = mouse.y
          root.currentX = mouse.x
          root.currentY = mouse.y
          root.selWidth = 0
          root.selHeight = 0
        }
      }

      onPositionChanged: (mouse) => {
        if (root.isSelecting) {
          root.currentX = mouse.x
          root.currentY = mouse.y
          root.updateSelection()
          return
        }

        if (!root.isResizing)
          return

        let newWidth
        let newHeight

        if (root.activeHandle === 0) { // TL
          newWidth = (root.selX + root.selWidth) - mouse.x
          newHeight = (root.selY + root.selHeight) - mouse.y
          if (newWidth >= 1 && newHeight >= 1) {
            root.selX = mouse.x
            root.selY = mouse.y
            root.selWidth = newWidth
            root.selHeight = newHeight
          }
        } else if (root.activeHandle === 1) { // TR
          newWidth = mouse.x - root.selX
          newHeight = (root.selY + root.selHeight) - mouse.y
          if (newWidth >= 1 && newHeight >= 1) {
            root.selY = mouse.y
            root.selWidth = newWidth
            root.selHeight = newHeight
          }
        } else if (root.activeHandle === 2) { // BL
          newWidth = (root.selX + root.selWidth) - mouse.x
          newHeight = mouse.y - root.selY
          if (newWidth >= 1 && newHeight >= 1) {
            root.selX = mouse.x
            root.selWidth = newWidth
            root.selHeight = newHeight
          }
        } else if (root.activeHandle === 3) { // BR
          newWidth = mouse.x - root.selX
          newHeight = mouse.y - root.selY
          if (newWidth >= 1 && newHeight >= 1) {
            root.selWidth = newWidth
            root.selHeight = newHeight
          }
        }
      }

      onReleased: (mouse) => {
        if (mouse.button === Qt.LeftButton && root.isSelecting)
          root.isSelecting = false
      }
    }
  }
}
