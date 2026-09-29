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

# YAD installs a developer-oriented "Icon Browser" launcher; keep YAD unavailable\n# from the live application menu without removing the underlying utility.\nYAD_ICON_DESKTOP="/usr/share/applications/yad-icon-browser.desktop"\nif [ -f "$YAD_ICON_DESKTOP" ]; then\n    rm -f "$YAD_ICON_DESKTOP"\nfi\n\nif command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi

echo "[OK] Live uygulama temizliği tamamlandı."
