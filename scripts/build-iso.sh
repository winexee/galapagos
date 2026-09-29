#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$PROJECT/build/live-root"
STAGING="$PROJECT/build/iso"
ISO="$PROJECT/build/galapagos-26.04-amd64.iso"
FINAL="$PROJECT/iso/galapagos-linux-1.0.0-amd64.iso"
BUILD_USER="${SUDO_USER:-$(id -un)}"
BUILD_GROUP="$(id -gn "$BUILD_USER" 2>/dev/null || printf "%s" "$BUILD_USER")"

cd "$PROJECT"

echo "=== Galapagos ISO Build ==="

for cmd in mksquashfs grub-mkrescue xorriso rsync sha256sum find sort unsquashfs; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "[HATA] Eksik araç: $cmd"; exit 1; }
done

for path in "$ROOT" "custom-disk/boot/grub/grub.cfg" "custom-disk/boot/grub/loopback.cfg" "custom-disk/EFI/boot/bootx64.efi"; do
    [ -e "$path" ] || { echo "[HATA] Eksik: $path"; exit 1; }
done

KERNEL_FILE="$(find "$ROOT/boot" -maxdepth 1 -type f -name "vmlinuz-*" -printf "%f\n" | sort -V | tail -n 1)"
[ -n "$KERNEL_FILE" ] || { echo "[HATA] RootFS içinde kernel bulunamadı."; exit 1; }
KERNEL_VERSION="${KERNEL_FILE#vmlinuz-}"
INITRD_FILE="initrd.img-${KERNEL_VERSION}"
[ -f "$ROOT/boot/$INITRD_FILE" ] || { echo "[HATA] Eşleşen initrd bulunamadı: $INITRD_FILE"; exit 1; }
echo "[OK] Kernel: $KERNEL_FILE"
echo "[OK] Initrd: $INITRD_FILE"

sudo rm -rf "$STAGING"
sudo mkdir -p "$STAGING/casper" "$STAGING/boot" "$STAGING/EFI"
sudo rsync -a custom-disk/ "$STAGING/"

sudo mkdir -p "$STAGING/.disk"
printf "%s\n" "Galapagos Linux 26.04 LTS - amd64" | sudo tee "$STAGING/.disk/info" >/dev/null

sudo cp "$ROOT/boot/$KERNEL_FILE" "$STAGING/casper/vmlinuz"
sudo cp "$ROOT/boot/$INITRD_FILE" "$STAGING/casper/initrd"

sudo rm -f "$STAGING/casper/filesystem.squashfs"
sudo mksquashfs "$ROOT" "$STAGING/casper/filesystem.squashfs" -comp xz -b 1M -noappend -wildcards

sudo chroot "$ROOT" dpkg-query -W -f="${binary:Package} ${Version}\n" | sort | sudo tee "$STAGING/casper/filesystem.manifest" >/dev/null
sudo du -sx --block-size=1 "$ROOT" | awk '{print $1}' | sudo tee "$STAGING/casper/filesystem.size" >/dev/null

sudo cp custom-disk/boot/grub/grub.cfg "$STAGING/boot/grub/grub.cfg"
sudo cp custom-disk/boot/grub/loopback.cfg "$STAGING/boot/grub/loopback.cfg"
if grep -qi "Ubuntu" "$STAGING/boot/grub/grub.cfg"; then
    echo "[HATA] GRUB içinde Ubuntu metni bulundu."
    exit 1
fi
grep -q "galapagos.install=1" "$STAGING/boot/grub/grub.cfg" || { echo "[HATA] galapagos.install=1 eksik."; exit 1; }

if [ -f "$STAGING/EFI/boot/bootx64.efi" ] && [ -f "$STAGING/EFI/boot/grubx64.efi" ] && [ -f "$STAGING/EFI/boot/mmx64.efi" ]; then
    echo "[OK] EFI dosyaları mevcut."
else
    echo "[HATA] Gerekli EFI dosyaları eksik."
    exit 1
fi

sudo rm -f "$ISO"
sudo grub-mkrescue -o "$ISO" "$STAGING"
sudo chown "$BUILD_USER:$BUILD_GROUP" "$ISO"

sha256sum "$ISO" | tee "$ISO.sha256"

sudo mkdir -p "$PROJECT/iso"
sudo rm -f "$FINAL"
sudo ln -sfn "../build/galapagos-26.04-amd64.iso" "$FINAL"

echo "[OK] ISO: $ISO"
echo "[OK] Final: $FINAL"
ls -lh "$ISO" "$FINAL"