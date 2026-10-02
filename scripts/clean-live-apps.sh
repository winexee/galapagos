#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "[HATA] Bu script root olarak çalıştırılmalı."
    echo "Örnek: sudo chroot build/live-root /usr/local/sbin/galapagos-clean-live-apps"
    exit 1
fi

if [ ! -f /etc/calamares/settings.conf ] || ! grep -q '^branding:[[:space:]]*galapagos$' /etc/calamares/settings.conf 2>/dev/null; then
    echo "[HATA] /etc/calamares/settings.conf içinde Galapagos branding doğrulanamadı."
    echo "[HATA] Güvenlik için cleanup işlemi durduruldu."
    exit 1
fi

REMOVE_PACKAGES=(
    ark
    dolphin
    gwenview
    kate
    konsole
    spectacle
    systemsettings
    plasma-discover
    kdeconnect
    kcalc
    kinfocenter
    gtk-3-examples
    gtk-4-examples
)

remove_desktop_file_if_present() {
    local desktop_file="$1"

    if [ -f "$desktop_file" ]; then
        rm -f -- "$desktop_file"
    fi
}

detect_live_home() {
    local candidate user

    for candidate in /home/*; do
        [ -d "$candidate" ] || continue
        user="${candidate##*/}"

        if id -u "$user" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

installed=()
for pkg in "${REMOVE_PACKAGES[@]}"; do
    if dpkg-query -W -f='${db:Status-Status}\n' "$pkg" 2>/dev/null | grep -qx installed; then
        installed+=("$pkg")
    fi
done

echo "=== GALAPAGOS LIVE APP TEMİZLİĞİ ==="

if [ "${#installed[@]}" -eq 0 ]; then
    echo "[OK] Hedef uygulama paketleri zaten kurulu değil."
else
    printf '[BİLGİ] Kaldırılacak paketler:\n'
    printf '  - %s\n' "${installed[@]}"
    DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Use-Pty=0 purge -y "${installed[@]}"
fi

for desktop_file in \
    /usr/share/applications/yad-icon-browser.desktop \
    /usr/share/applications/kate.desktop \
    /usr/share/applications/konsole.desktop \
    /usr/share/applications/gwenview.desktop \
    /usr/share/applications/dolphin.desktop \
    /usr/share/applications/ark.desktop \
    /usr/share/applications/spectacle.desktop \
    /usr/share/applications/systemsettings.desktop
do
    remove_desktop_file_if_present "$desktop_file"
done

ICON_BROWSER_LIST="$(mktemp)"
grep -ril --include='*.desktop' \
    -e '^Name[[:space:]]*=[[:space:]]*Icon Browser[[:space:]]*$' \
    -e '^Name\[[^]]*\][[:space:]]*=[[:space:]]*Icon Browser[[:space:]]*$' \
    /usr/share/applications 2>/dev/null > "$ICON_BROWSER_LIST" || true

while IFS= read -r desktop_file; do
    [ -n "$desktop_file" ] && remove_desktop_file_if_present "$desktop_file"
done < "$ICON_BROWSER_LIST"

rm -f -- "$ICON_BROWSER_LIST"

LIVE_HOME=""
LIVE_USER=""
LIVE_UID=""
LIVE_GID=""

if LIVE_HOME="$(detect_live_home)"; then
    LIVE_USER="${LIVE_HOME##*/}"
    LIVE_UID="$(id -u "$LIVE_USER")"
    LIVE_GID="$(id -g "$LIVE_USER")"

    rm -rf -- "$LIVE_HOME/.cache/menus"
    rm -f -- "$LIVE_HOME"/.config/menus/*.menu 2>/dev/null || true
fi

AVATAR_SOURCE="/etc/calamares/branding/galapagos/logo.svg"
if [ ! -f "$AVATAR_SOURCE" ] && [ -f /usr/share/icons/hicolor/scalable/apps/galapagos-installer.svg ]; then
    AVATAR_SOURCE="/usr/share/icons/hicolor/scalable/apps/galapagos-installer.svg"
fi

if [ -n "$LIVE_USER" ] && [ -f "$AVATAR_SOURCE" ] && [ -d "$LIVE_HOME" ]; then
    mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users

    ACCOUNT_ICON="/var/lib/AccountsService/icons/${LIVE_USER}.svg"
    ACCOUNT_FILE="/var/lib/AccountsService/users/${LIVE_USER}"

    cp -f "$AVATAR_SOURCE" "$ACCOUNT_ICON"

    if [ -f "$ACCOUNT_FILE" ]; then
        if grep -q '^Icon=' "$ACCOUNT_FILE"; then
            sed -i "s|^Icon=.*$|Icon=$ACCOUNT_ICON|" "$ACCOUNT_FILE"
        else
            printf '\nIcon=%s\n' "$ACCOUNT_ICON" >> "$ACCOUNT_FILE"
        fi
    else
        printf '[User]\nIcon=%s\n' "$ACCOUNT_ICON" > "$ACCOUNT_FILE"
    fi

    cp -f "$AVATAR_SOURCE" "$LIVE_HOME/.face"
    chown "$LIVE_UID:$LIVE_GID" "$ACCOUNT_ICON" "$ACCOUNT_FILE" "$LIVE_HOME/.face" 2>/dev/null || true

    echo "[OK] Galapagos kullanıcı avatarı hazır."
else
    echo "[UYARI] Galapagos avatarı hazırlanamadı."
    echo "[BİLGİ] Kaynak: $AVATAR_SOURCE"
    echo "[BİLGİ] Ev dizini: ${LIVE_HOME:-bulunamadı}"
fi

icon_browser_problem=0

if grep -Ril --include='*.desktop' \
    -e '^Name[[:space:]]*=[[:space:]]*Icon Browser[[:space:]]*$' \
    -e '^Name\[[^]]*\][[:space:]]*=[[:space:]]*Icon Browser[[:space:]]*$' \
    /usr/share/applications >/dev/null 2>&1; then
    echo "[HATA] Icon Browser launcher dosyası hâlâ mevcut."
    icon_browser_problem=1
fi

for binary in gtk3-icon-browser gtk4-icon-browser yad-icon-browser; do
    if command -v "$binary" >/dev/null 2>&1; then
        echo "[HATA] Icon Browser ilişkili binary hâlâ mevcut: $binary"
        icon_browser_problem=1
    fi
done

for pkg in gtk-3-examples gtk-4-examples yad; do
    if dpkg-query -W -f='${db:Status-Status}\n' "$pkg" 2>/dev/null | grep -qx installed; then
        echo "[HATA] Icon Browser ilişkili paket hâlâ kurulu: $pkg"
        icon_browser_problem=1
    fi
done

if [ "$icon_browser_problem" -ne 0 ]; then
    exit 1
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -d /usr/share/icons/hicolor ]; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi

echo "[OK] Live uygulama ve launcher temizliği tamamlandı."
