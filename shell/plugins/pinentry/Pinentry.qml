import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  // Injected by omarchy-shell.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property string fontFamily: Style.font.menuFamily
  // Deliberately the same tokens as the polkit (sudo) prompt, not a separate
  // [pinentry] theme section — the two dialogs should look identical and
  // stay that way as themes change.
  property color accent: Color.polkit.accent
  property color background: Color.polkit.background
  property color foreground: Color.polkit.text
  property color border: Color.polkit.border
  property color scrim: Color.polkit.scrim
  property var borderSpec: Border.surfaceSpec("polkit", "border", border, Math.max(1, Style.space(2)), "border-alpha")
  readonly property int cornerRadius: Style.cornerRadius
  property int contentMargin: Style.spacing.panelPadding
  property int fieldHeight: Math.max(Style.space(42), Style.spacing.controlHeight)
  readonly property int cardHeight: fieldHeight + contentMargin * 2
  readonly property int cardWidth: Math.min(Style.space(312), Math.max(Style.space(260), panel.width - Style.gapsOut * 2))

  property bool dialogVisible: false
  property string currentMessage: ""
  property string selectionFile: ""
  property string doneFile: ""

  function beginRequest(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }

    root.currentMessage = String(payload.message || "")
    root.selectionFile = String(payload.selectionFile || "")
    root.doneFile = String(payload.doneFile || "")
    passwordInput.text = ""
    root.dialogVisible = true
    Qt.callLater(function() { passwordInput.forceActiveFocus() })
  }

  function finish(value) {
    if (!root.doneFile) {
      root.dialogVisible = false
      return
    }

    var activeSelectionFile = root.selectionFile
    var activeDoneFile = root.doneFile
    root.selectionFile = ""
    root.doneFile = ""
    root.dialogVisible = false
    passwordInput.text = ""

    if (value === null || value === undefined) {
      resultProc.command = ["bash", "-c", ": > " + Util.shellQuote(activeDoneFile)]
    } else {
      resultProc.command = ["bash", "-c", "printf '%s' " + Util.shellQuote(value) + " > " + Util.shellQuote(activeSelectionFile) + "; : > " + Util.shellQuote(activeDoneFile)]
    }
    resultProc.running = true
  }

  function submit() {
    root.finish(passwordInput.text)
  }

  function cancel() {
    root.finish(null)
  }

  IpcHandler {
    target: "pinentry"

    function show(payloadJson: string): string {
      root.beginRequest(payloadJson)
      return "ok"
    }
  }

  Process { id: resultProc }

  PanelWindow {
    id: panel
    visible: root.dialogVisible
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-pinentry"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: passwordInput.forceActiveFocus()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: passwordInput.forceActiveFocus() }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.cancel()
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit()
            event.accepted = true
          }
        }

        Row {
          anchors.fill: parent
          anchors.topMargin: card.contentTopInset
          anchors.rightMargin: card.contentRightInset
          anchors.bottomMargin: card.contentBottomInset
          anchors.leftMargin: card.contentLeftInset
          spacing: Style.space(14)

          Text {
            text: "\uf023"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.iconLarge
            width: Style.space(26)
            height: root.fieldHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          Item {
            width: parent.width - Style.space(40)
            height: root.fieldHeight

            TextInput {
              id: passwordInput
              anchors.fill: parent
              verticalAlignment: TextInput.AlignVCenter
              activeFocusOnPress: true
              clip: true
              selectionColor: Util.alpha(root.accent, 0.45)
              selectedTextColor: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.iconLarge
              echoMode: TextInput.Password
              passwordCharacter: "\u2022"
              color: root.foreground
              cursorVisible: activeFocus
              enabled: root.dialogVisible
              onAccepted: root.submit()
            }

            Text {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              text: "Enter password"
              color: root.foreground
              opacity: 0.36
              font.family: root.fontFamily
              font.pixelSize: Style.font.iconLarge
              elide: Text.ElideRight
              visible: passwordInput.text.length === 0
            }

            Rectangle {
              width: Math.max(1, Style.space(2))
              height: Style.space(24)
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              color: root.foreground
              visible: passwordInput.activeFocus && passwordInput.text.length === 0
            }

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton
              onClicked: passwordInput.forceActiveFocus()
            }
          }
        }
      }
    }

    Rectangle {
      width: Math.min(messageText.implicitWidth + Style.space(24), panel.width - Style.gapsOut * 2)
      height: Style.space(28)
      anchors.horizontalCenter: card.horizontalCenter
      anchors.bottom: card.top
      anchors.bottomMargin: Style.space(10)
      radius: root.cornerRadius
      color: root.background
      visible: root.currentMessage.length > 0

      Text {
        id: messageText
        anchors.fill: parent
        anchors.leftMargin: Style.space(12)
        anchors.rightMargin: Style.space(12)
        text: root.currentMessage
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideMiddle
      }
    }
  }
}
