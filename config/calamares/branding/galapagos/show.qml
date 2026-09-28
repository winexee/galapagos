import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 4000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#F5F9FC"

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 86
                text: "Galapagos Linux"
                color: "#173042"
                font.pixelSize: 32
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 132
                text: "Açık kaynaklı ve modern bir Linux deneyimi"
                color: "#647A87"
                font.pixelSize: 17
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 205
                width: Math.min(parent.width - 140, 620)
                height: 145
                radius: 18
                color: "#FFFFFF"
                border.color: "#DCE8EE"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "26.04 LTS"
                        color: "#1976A8"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Güvenilir temel • Güncel paketler • Galapagos arayüzü"
                        color: "#718590"
                        font.pixelSize: 15
                    }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#F5F9FC"

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 82
                text: "Üç masaüstü seçeneği"
                color: "#173042"
                font.pixelSize: 31
                font.bold: true
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 170
                spacing: 18

                Repeater {
                    model: [
                        ["Cinnamon", "Klasik ve sade"],
                        ["KDE Plasma", "Esnek ve özelleştirilebilir"],
                        ["GNOME", "Modern ve sade"]
                    ]

                    delegate: Rectangle {
                        width: 190
                        height: 190
                        radius: 18
                        color: "#FFFFFF"
                        border.color: "#DCE8EE"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Rectangle {
                                width: 58
                                height: 58
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 29
                                color: "#E6F4FA"

                                Text {
                                    anchors.centerIn: parent
                                    text: "●"
                                    color: "#1976A8"
                                    font.pixelSize: 25
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData[0]
                                color: "#173042"
                                font.pixelSize: 17
                                font.bold: true
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData[1]
                                color: "#718590"
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#F5F9FC"

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 82
                text: "Kişiselleştirilebilir kurulum"
                color: "#173042"
                font.pixelSize: 31
                font.bold: true
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 180
                spacing: 24

                Repeater {
                    model: [
                        ["Masaüstü", "Cinnamon • KDE • GNOME"],
                        ["Kurulum", "Minimal veya Standard"],
                        ["Ağ", "Kurulum sırasında yapılandırma"]
                    ]

                    delegate: Rectangle {
                        width: 210
                        height: 170
                        radius: 18
                        color: "#FFFFFF"
                        border.color: "#DCE8EE"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 12

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData[0]
                                color: "#1976A8"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Text {
                                width: 180
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData[1]
                                color: "#718590"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#F5F9FC"

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 88
                text: "Günlük kullanım için hazır"
                color: "#173042"
                font.pixelSize: 31
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 142
                text: "Firefox, dosya yöneticisi, terminal ve temel sistem araçları"
                color: "#647A87"
                font.pixelSize: 16
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 212
                width: Math.min(parent.width - 180, 560)
                height: 130
                radius: 18
                color: "#FFFFFF"
                border.color: "#DCE8EE"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 50
                    text: "Galapagos Linux kurulumu tamamlandığında seçtiğiniz masaüstü ile açılacaktır."
                    color: "#556D79"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    function onActivate()
    {
        presentation.currentSlide = 0
    }

    function onLeave()
    {
    }
}
