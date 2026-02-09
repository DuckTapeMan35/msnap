import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Region selection overlay - full screen grey overlay with white selection rectangle
// Supports drag-to-select, drag-to-move, and resizable corners
PanelWindow {
  id: root

  screen: Quickshell.screens[0]

  anchors.top: true
  anchors.left: true
  anchors.right: true
  anchors.bottom: true

  visible: false
  color: "transparent"

  // Layer shell configuration - below the shell panel
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "region-selector"
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  // Signals
  signal selectionComplete(int x, int y, int width, int height)
  signal cancelled()

  // Selection state
  property bool isSelecting: false
  property bool isMoving: false
  property bool isResizing: false
  property int activeHandle: -1 // 0=TL, 1=TR, 2=BL, 3=BR
  
  // Working coordinates (while dragging)
  property int startX: 0
  property int startY: 0
  property int currentX: 0
  property int currentY: 0
  
  // Final selection rectangle coordinates
  property int selX: 0
  property int selY: 0
  property int selWidth: 0
  property int selHeight: 0
  
  property int moveOffsetX: 0
  property int moveOffsetY: 0

  // Check if selection is valid (at least 1x1)
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
    
    // Set default selection - will be centered once component is ready
    // Using a timer to ensure parent dimensions are available
    defaultSelectionTimer.start()
  }
  
  Timer {
    id: defaultSelectionTimer
    interval: 1
    running: false
    repeat: false
    onTriggered: {
      // Set default selection - centered 400x300 region
      var defaultWidth = 400
      var defaultHeight = 300
      var parentItem = root.contentItem
      
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
    if (hasSelection) {
      selectionComplete(selX, selY, selWidth, selHeight)
    }
  }
  
  function getSelection() {
    // Return current selection coordinates
    return {
      x: selX,
      y: selY,
      width: selWidth,
      height: selHeight,
      valid: hasSelection
    }
  }
  
  function updateSelection() {
    // Update final selection from current drag coordinates
    selX = Math.min(startX, currentX)
    selY = Math.min(startY, currentY)
    selWidth = Math.abs(currentX - startX)
    selHeight = Math.abs(currentY - startY)
  }

  // Full-screen overlay with selection
  Item {
    anchors.fill: parent
    focus: true

    Keys.onPressed: (event) => {
      if (event.key === Qt.Key_Escape) {
        // Cancel and notify parent
        root.cancelled()
        root.close()
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        // Confirm selection on Enter key
        root.confirmSelection()
        event.accepted = true
      }
    }

    Component.onCompleted: {
      forceActiveFocus()
    }

    // Full-screen cursor handler - prevents clicks from passing through to shell
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      hoverEnabled: true
      z: -2  // Behind grey overlay but still catches events
      
      // Show crosshair when not over selection box
      cursorShape: {
        if (root.isSelecting) return Qt.CrossCursor
        if (root.hasSelection &&
            mouseX >= root.selX && mouseX <= root.selX + root.selWidth &&
            mouseY >= root.selY && mouseY <= root.selY + root.selHeight) {
          return Qt.ArrowCursor  // Default over selection, let selection handle it
        }
        return Qt.CrossCursor
      }
      
      onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
          // Right-click also cancels
          root.cancelled()
          root.close()
        }
      }
    }

    // Grey background overlay - always visible
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.5)
      z: -1  // Behind everything except cursor handler
    }

    // Selection rectangle with thick border
    Rectangle {
      id: selectionRect
      x: root.selX
      y: root.selY
      width: root.selWidth
      height: root.selHeight
      visible: root.hasSelection
      color: "transparent"
      border.width: 2
      border.color: "#ffffff" // White border
      z: 5  // Above main MouseArea, below handles
      
      // MouseArea for moving the selection
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
          if (root.isMoving) {
            var newX = root.selX + mouse.x - root.moveOffsetX
            var newY = root.selY + mouse.y - root.moveOffsetY
            var width = root.selWidth
            var height = root.selHeight
            
            // Keep within screen bounds
            newX = Math.max(0, Math.min(newX, parent.parent.width - width))
            newY = Math.max(0, Math.min(newY, parent.parent.height - height))
            
            root.selX = newX
            root.selY = newY
          }
        }
        
        onReleased: {
          root.isMoving = false
        }
      }
    }

    // Dimensions label
    Rectangle {
      x: Math.min(Math.max(root.selX + 10, 10), parent.width - width - 10)
      y: Math.max(root.selY - 35, 10)
      width: dimensionsText.implicitWidth + 16
      height: dimensionsText.implicitHeight + 8
      visible: root.hasSelection
      color: Qt.rgba(0, 0, 0, 0.8)
      radius: 4
      z: 10  // Above everything

      Text {
        id: dimensionsText
        anchors.centerIn: parent
        text: root.selWidth + "x" + root.selHeight
        color: "#ffffff"
        font.pixelSize: 12
        font.bold: true
      }
    }

    // Corner handles - centered on endpoints
    // Top-Left handle
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
        anchors.margins: -6 // Larger hit area
        cursorShape: Qt.SizeFDiagCursor
        hoverEnabled: true
        enabled: true  // Always enabled
        onPressed: {
          root.isResizing = true
          root.activeHandle = 0 // TL
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Top-Right handle
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
        enabled: true  // Always enabled
        onPressed: {
          root.isResizing = true
          root.activeHandle = 1 // TR
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Bottom-Left handle
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
        enabled: true  // Always enabled
        onPressed: {
          root.isResizing = true
          root.activeHandle = 2 // BL
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Bottom-Right handle
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
        enabled: true  // Always enabled
        onPressed: {
          root.isResizing = true
          root.activeHandle = 3 // BR
        }
        onReleased: {
          root.isResizing = false
          root.activeHandle = -1
        }
      }
    }

    // Instructions label
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 20
      text: root.hasSelection ? "Adjust selection • Press Enter to confirm • Esc to cancel"
                              : "Drag to select area • Esc to cancel"
      color: "#ffffff"
      font.pixelSize: 11
      z: 10  // Above everything
    }

    // Main mouse handling - for creating NEW selections
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      hoverEnabled: false
      // Active when selecting OR when there's no selection OR clicking outside selection
      enabled: root.isSelecting || !root.hasSelection || !isInsideSelection()
      z: 0  // Below selection and handles
      
      function isInsideSelection() {
        // We can't use mouseX/mouseY here in enabled binding; always true and
        // check in onPressed instead.
        return false
      }

      onPressed: (mouse) => {
        // Check if clicking outside the selection box
        var outsideSelection = !root.hasSelection ||
                              mouse.x < root.selX || mouse.x > root.selX + root.selWidth ||
                              mouse.y < root.selY || mouse.y > root.selY + root.selHeight
        
        if (mouse.button === Qt.LeftButton && !root.isResizing && outsideSelection) {
          // Start new selection (clears old one)
          root.isSelecting = true
          root.startX = mouse.x
          root.startY = mouse.y
          root.currentX = mouse.x
          root.currentY = mouse.y
          // Clear old selection while creating new one
          root.selWidth = 0
          root.selHeight = 0
        }
      }

      onPositionChanged: (mouse) => {
        if (root.isSelecting) {
          // Creating selection - update working coordinates and live preview
          root.currentX = mouse.x
          root.currentY = mouse.y
          root.updateSelection()
        } else if (root.isResizing) {
          // Resizing via corners
          var newX = root.selX
          var newY = root.selY
          var newWidth = root.selWidth
          var newHeight = root.selHeight

          if (root.activeHandle === 0) { // Top-Left
            newWidth = (root.selX + root.selWidth) - mouse.x
            newHeight = (root.selY + root.selHeight) - mouse.y
            if (newWidth >= 1 && newHeight >= 1) {
              root.selX = mouse.x
              root.selY = mouse.y
              root.selWidth = newWidth
              root.selHeight = newHeight
            }
          } else if (root.activeHandle === 1) { // Top-Right
            newWidth = mouse.x - root.selX
            newHeight = (root.selY + root.selHeight) - mouse.y
            if (newWidth >= 1 && newHeight >= 1) {
              root.selY = mouse.y
              root.selWidth = newWidth
              root.selHeight = newHeight
            }
          } else if (root.activeHandle === 2) { // Bottom-Left
            newWidth = (root.selX + root.selWidth) - mouse.x
            newHeight = mouse.y - root.selY
            if (newWidth >= 1 && newHeight >= 1) {
              root.selX = mouse.x
              root.selWidth = newWidth
              root.selHeight = newHeight
            }
          } else if (root.activeHandle === 3) { // Bottom-Right
            newWidth = mouse.x - root.selX
            newHeight = mouse.y - root.selY
            if (newWidth >= 1 && newHeight >= 1) {
              root.selWidth = newWidth
              root.selHeight = newHeight
            }
          }
        }
      }

      onReleased: (mouse) => {
        if (mouse.button === Qt.LeftButton) {
          if (root.isSelecting) {
            root.isSelecting = false
            // Selection coordinates are already set by updateSelection()
          }
        }
      }
    }
  }
}
