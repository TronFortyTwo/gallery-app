import QtQuick 2.0
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

Item {
    id: chromeBar
    property alias buttonsModel: buttonsRepeater.model
//    property bool showChromeBar: true
    property alias showChromeBar: bar.shown
    property bool showBackButton: true

    signal buttonClicked(var buttonName, var button)
    signal backButtonClicked()

    enabled: showBackButton || (buttonsRepeater.count > 0)
    anchors.left: parent.left
    anchors.right: parent.right
    height: bar.height - bar.y

    onEnabledChanged: {
        if (!enabled) {
            setBarShown(false);
        }
    }

    onButtonsModelChanged: setBarShown(false)

    Component.onCompleted: setBarShown(false)

    function setBarShown(shown) {
        if (shown) {
            bar.y = 0;
        } else {
            bar.y = bar.height;
        }
        bar.shown = shown;
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: bar.height
        drag.target: bar
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: height + bar.height
        propagateComposedEvents: true

        property int __pressedY
        onPressed: {
            __pressedY = mouse.y;
        }

        onReleased: {
            // check if there was at least some moving to avoid displaying
            // the chrome bar on clicking
            if (Math.abs(__pressedY - mouse.y) < units.gu(1)) {
                setBarShown(bar.shown);
                return;
            }

            setBarShown(!bar.shown);
        }

        Item {
            id: bar

            property bool shown: false
            height: units.gu(6) + orangeRect.height
            anchors.left: parent.left
            anchors.right: parent.right
            y: parent.height

            Rectangle {
                id: background
                anchors.fill: parent
                color: "white"
            }

            Behavior on y {
                NumberAnimation {
                    duration: 150
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                Item {
                    id: contents
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: chromeButtons.height + units.gu(2)

                    ChromeButton {
                        id: backButton
                        anchors.left: parent.left
                        anchors.leftMargin: units.gu(1)
                        anchors.top: parent.top
                        icon: "../img/back.png"
                        text: "Back"

                        onClicked: {
                            backButtonClicked()
                            setBarShown(false)
                        }

                        visible: showBackButton
                    }

                    Row {
                        id: chromeButtons
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: units.gu(1)
                        height: childrenRect.height

                        Repeater {
                            id: buttonsRepeater

                            ChromeButton {
                                id: chromeButton
                                text: model.label
                                icon: model.icon
                                objectName: model.name
                                anchors.top: parent.top
                                onClicked: buttonClicked(model.name, chromeButton)
                            }
                        } // Repeater
                    } // Row
                } // Item
            } // Column
        } // Item - bar
    } // MouseArea

    Rectangle {
        id: orangeRect
        color: "#f37505"
        height: units.dp(3)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
