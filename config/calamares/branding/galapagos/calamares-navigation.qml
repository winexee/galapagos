import io.calamares.ui 1.0
import io.calamares.core 1.0

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: navigationBar

    color: "#FFFFFF"

    height: 76
    implicitWidth: 900

    border.color: "#DCE6EB"
    border.width: 1

    RowLayout {
        anchors.fill: parent

        anchors.leftMargin: 22
        anchors.rightMargin: 22

        spacing: 12

        // --------------------------------------------------
        // SOLDA DURUM
        // --------------------------------------------------

        Text {
            Layout.fillWidth: true

            text: "Galapagos Linux • Kurulum"

            color: "#6A7E89"
            font.pixelSize: 12
        }

        // --------------------------------------------------
        // GERİ
        // --------------------------------------------------

        Button {
            id: backButton

            Layout.preferredWidth: 105
            Layout.preferredHeight: 42

            enabled: ViewManager.backEnabled
            visible: ViewManager.backAndNextVisible

            text: "←  Geri"

            contentItem: Text {
                text: backButton.text
                color: backButton.enabled ? "#173042" : "#9AAAB2"
                font.pixelSize: 13
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 9
                color: backButton.enabled ? "#F5F8FA" : "#F1F3F4"
                border.color: "#D3E0E6"
                border.width: 1
            }

            onClicked: ViewManager.back()
        }

        // --------------------------------------------------
        // İLERİ
        // --------------------------------------------------

        Button {
            id: nextButton

            Layout.preferredWidth: 125
            Layout.preferredHeight: 42

            enabled: ViewManager.nextEnabled
            visible: ViewManager.backAndNextVisible && ViewManager.quitIcon !== "dialog-ok-apply"

            text: "İleri  →"

            contentItem: Text {
                text: nextButton.text
                color: "#FFFFFF"
                font.pixelSize: 13
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 9

                color: nextButton.enabled
                       ? "#1976A8"
                       : "#AFC0C9"
            }

            onClicked: ViewManager.next()
        }

        // --------------------------------------------------
        // İPTAL
        // --------------------------------------------------

        Button {
            id: cancelButton

            Layout.preferredWidth: 90
            Layout.preferredHeight: 42

            enabled: ViewManager.quitEnabled
            visible: ViewManager.quitVisible

            text: ViewManager.quitLabel.replace("&", "")

            contentItem: Text {
                text: cancelButton.text
                color: cancelButton.enabled ? "#173042" : "#9AAAB2"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 9
                color: "#FFFFFF"
                border.color: "#D3E0E6"
                border.width: 1
            }

            onClicked: ViewManager.quit()
        }
    }
}
