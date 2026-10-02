#!/usr/bin/env python3

import libcalamares


DESKTOPS = {
    "cinnamon": {
        "display_manager": "lightdm",
        "remove": [
            "kde-plasma-desktop",
            "sddm",
            "konsole",
            "kate",
            "ark",
            "gwenview",
            "spectacle",
            "systemsettings",
            "plasma-nm",
            "plasma-pa",
            "gnome-session",
            "gnome-shell",
            "gnome-settings-daemon",
            "gnome-control-center",
            "nautilus",
            "gdm3",
            "gnome-terminal",
            "gnome-text-editor",
        ],
        "install": [
            "cinnamon-core",
            "cinnamon-session",
            "muffin",
            "nemo",
            "lightdm",
            "lightdm-gtk-greeter",
            "xfce4-terminal",
            "xed",
            "file-roller",
            "gnome-screenshot",
            "xdg-desktop-portal",
            "xdg-desktop-portal-gtk",
        ],
    },

    "kde": {
        "display_manager": "sddm",
        "remove": [
            "cinnamon-core",
            "cinnamon-session",
            "muffin",
            "nemo",
            "lightdm",
            "lightdm-gtk-greeter",
            "xfce4-terminal",
            "xed",
            "gnome-session",
            "gnome-shell",
            "gnome-settings-daemon",
            "gnome-control-center",
            "nautilus",
            "gdm3",
            "gnome-terminal",
            "gnome-text-editor",
        ],
        "install": [
            "kde-plasma-desktop",
            "sddm",
            "dolphin",
            "konsole",
            "kate",
            "ark",
            "gwenview",
            "spectacle",
            "systemsettings",
            "plasma-nm",
            "plasma-pa",
            "xdg-desktop-portal",
            "xdg-desktop-portal-kde",
        ],
    },

    "gnome": {
        "display_manager": "gdm3",
        "remove": [
            "cinnamon-core",
            "cinnamon-session",
            "muffin",
            "nemo",
            "lightdm",
            "lightdm-gtk-greeter",
            "xfce4-terminal",
            "xed",
            "kde-plasma-desktop",
            "sddm",
            "konsole",
            "kate",
            "ark",
            "gwenview",
            "spectacle",
            "systemsettings",
            "plasma-nm",
            "plasma-pa",
        ],
        "install": [
            "gnome-session",
            "gnome-shell",
            "gnome-settings-daemon",
            "gnome-control-center",
            "nautilus",
            "gdm3",
            "gnome-terminal",
            "gnome-text-editor",
            "file-roller",
            "gnome-screenshot",
            "xdg-desktop-portal",
            "xdg-desktop-portal-gnome",
        ],
    },
}


def pretty_name():
    return "Galapagos masaüstü seçimi"


def run():
    gs = libcalamares.globalstorage
    key = "packagechooser_desktop"

    if not gs.contains(key):
        libcalamares.utils.error(
            "Galapagos Desktop: {} bulunamadı.".format(key)
        )
        return "Masaüstü seçimi alınamadı."

    selected = gs.value(key)

    libcalamares.utils.debug(
        "Galapagos Desktop: seçilen masaüstü = {!r}".format(selected)
    )

    if selected not in DESKTOPS:
        libcalamares.utils.error(
            "Galapagos Desktop: bilinmeyen masaüstü {!r}".format(selected)
        )
        return "Geçersiz masaüstü seçimi."

    desktop = DESKTOPS[selected]

    operations = []

    if desktop["install"]:
        operations.append({
            "install": desktop["install"]
        })

    if desktop["remove"]:
        operations.append({
            "remove": desktop["remove"]
        })

    if gs.contains("packageOperations"):
        existing = gs.value("packageOperations")

        if isinstance(existing, list):
            operations = existing + operations

    gs.insert("packageOperations", operations)

    # Calamares displaymanager modülünün kullanacağı seçili DM.
    gs.insert(
        "displaymanagers",
        [desktop["display_manager"]]
    )
    gs.insert(
        "displayManagers",
        [desktop["display_manager"]]
    )

    libcalamares.utils.debug(
        "Galapagos Desktop: packageOperations = {!r}".format(
            operations
        )
    )

    libcalamares.utils.debug(
        "Galapagos Desktop: displaymanagers = {!r}".format(
            [desktop["display_manager"]]
        )
    )

    return None
