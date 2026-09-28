import io.calamares.ui 1.0
import io.calamares.core 1.0

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: sidebar

    color: Branding.styleString(Branding.SidebarBackground)

    width: 255
    implicitHeight: 600

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // --------------------------------------------------
        // GALAPAGOS LOGO
        // --------------------------------------------------

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 155
            color: "#0D2230"

            Column {
                anchors.centerIn: parent
                spacing: 8

                Image {
                    width: 72
                    height: 72
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "file:/" + Branding.imagePath(Branding.ProductLogo)
                    sourceSize.width: 72
                    sourceSize.height: 72
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Galapagos Linux"
                    color: "#FFFFFF"
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "26.04 LTS"
                    color: "#9FDCEC"
                    font.pixelSize: 12
                }
            }
        }

        // --------------------------------------------------
        // BAŞLIK
        // --------------------------------------------------

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 22
            Layout.rightMargin: 15
            Layout.topMargin: 18
            Layout.bottomMargin: 10

            text: "Kurulum adımları"
            color: "#8FB2C2"
            font.pixelSize: 12
            font.bold: true
        }

        // --------------------------------------------------
        // ADIMLAR
        // --------------------------------------------------

        ListView {
            id: steps

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            model: ViewManager

            spacing: 5

            delegate: Rectangle {
                width: steps.width - 20
                height: 48

                anchors.horizontalCenter: parent.horizontalCenter

                radius: 9

                color: index === ViewManager.currentStepIndex
                       ? Branding.styleString(Branding.SidebarBackgroundCurrent)
                       : "transparent"

                opacity: index === ViewManager.currentStepIndex
                         ? 1.0
                         : (index < ViewManager.currentStepIndex ? 0.75 : 0.55)

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        width: 28
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 14

                        color: index === ViewManager.currentStepIndex
                               ? "#FFFFFF"
                               : "#244A5C"

                        Text {
                            anchors.centerIn: parent

                            text: index < ViewManager.currentStepIndex
                                  ? "✓"
                                  : String(index + 1)

                            color: index === ViewManager.currentStepIndex
                                   ? "#1976A8"
                                   : "#CFE5ED"

                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: display

                        color: index === ViewManager.currentStepIndex
                               ? Branding.styleString(Branding.SidebarTextCurrent)
                               : Branding.styleString(Branding.SidebarText)

                        font.pixelSize: 13
                        font.bold: index === ViewManager.currentStepIndex

                        elide: Text.ElideRight
                        width: parent.width - 50
                    }
                }
            }
        }

        // --------------------------------------------------
        // ALT BİLGİ
        // --------------------------------------------------

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60

            color: "#0D2230"

            Text {
                anchors.centerIn: parent

                text: "Galapagos Linux 26.04 LTS"
                color: "#6F96A7"
                font.pixelSize: 10
            }
        }
    }
}
