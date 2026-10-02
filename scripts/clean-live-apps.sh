#!/usr/bin/env bash
set -Eeuo pipefail

# Prepare the live Cinnamon environment. Desktop-specific packages selected
# later in Calamares are not affected by this live-session cleanup.

if [ "$(id -u)" -ne 0 ]; then
    echo "[HATA] Bu script root olarak çalıştırılmalı."
    echo "Örnek: sudo chroot build/live-root /usr/local/sbin/galapagos-clean-live-apps"
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

installed=()

for pkg in "${REMOVE_PACKAGES[@]}"; do
    if dpkg-query -W -f='${db:Status-Status}\n' "${pkg}" 2>/dev/null | grep -qx installed; then
        installed+=( "${pkg}" )
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

# Remove known developer-oriented launchers.
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
    rm -f "$desktop_file"
done

# Remove any remaining launcher whose visible name is exactly "Icon Browser".
if [ -d /usr/share/applications ]; then
    while IFS= read -r -d '' desktop_file; do
        rm -f "$desktop_file"
    done < <(
        grep -rilz --include='*.desktop' \
            -e '^Name[[:space:]]*=[[:space:]]*Icon Browser[[:space:]]*$' \
            -e '^Name\[[^]]*\][[:space:]]*=[[:space:]]*Icon Browser[[:space:]]*$' \
            /usr/share/applications 2>/dev/null || true
    )
fi

# Remove stale Cinnamon menu caches.
if [ -d /home/vboxuser ]; then
    rm -rf /home/vboxuser/.cache/menus
    rm -f /home/vboxuser/.config/menus/*.menu 2>/dev/null || true
fi

# Give the live user the Galapagos logo instead of the distro default account picture.
AVATAR_SOURCE="/etc/calamares/branding/galapagos/icon.png"
LIVE_UID=1000
LIVE_USER="$(getent passwd "$LIVE_UID" | cut -d: -f1 || true)"
LIVE_HOME="$(getent passwd "$LIVE_UID" | cut -d: -f6 || true)"

if [ -n "$LIVE_USER" ] && [ -n "$LIVE_HOME" ] && [ -f "$AVATAR_SOURCE" ]; then
    mkdir -p /var/lib/AccountsService/icons /var/lib/AccountsService/users

    ACCOUNT_ICON="/var/lib/AccountsService/icons/$LIVE_USER.png"
    ACCOUNT_FILE="/var/lib/AccountsService/users/$LIVE_USER"

    cp -f "$AVATAR_SOURCE" "$ACCOUNT_ICON"
    chown "$LIVE_UID:$(id -gn "$LIVE_UID")" "$ACCOUNT_ICON" 2>/dev/null || true

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
    chown "$LIVE_UID:$(id -gn "$LIVE_UID")" "$LIVE_HOME/.face" 2>/dev/null || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -d /usr/share/icons/hicolor ]; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi

echo "[OK] Live uygulama, launcher ve kullanıcı avatar temizliği tamamlandı."
