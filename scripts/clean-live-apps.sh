#!/usr/bin/env bash
set -Eeuo pipefail

# Clean the live Cinnamon session from desktop applications that are not part
# of the Galapagos live environment. The installer can install KDE/GNOME
# packages later when the user selects them in Calamares.

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

# Remove stale user-level menu caches from the live account.
if [ -d /home/vboxuser ]; then
    rm -rf /home/vboxuser/.cache/menus
    rm -f /home/vboxuser/.config/menus/*.menu 2>/dev/null || true
    chown -R 1000:1000 /home/vboxuser/.cache /home/vboxuser/.config 2>/dev/null || true
fi

# Remove developer-oriented launchers from the live application menu.
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

# Also remove any launcher whose visible name still contains "Icon Browser".
if [ -d /usr/share/applications ]; then
    grep -ril --include='*.desktop' '^[[:space:]]*Name[^=]*=[[:space:]]*Icon Browser[[:space:]]*
         /usr/share/applications 2>/dev/null         | while IFS= read -r desktop_file
          do
              rm -f "$desktop_file"
          done
fi
