#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$PROJECT/build/live-root"
STAGING="$PROJECT/build/iso"
ISO="$PROJECT/build/galapagos-26.04-amd64.iso"
FINAL="$PROJECT/iso/galapagos-linux-1.0.0-amd64.iso"

echo "============================================================"
echo " GALAPAGOS — ISO BUILD"
echo "============================================================"

cd "$PROJECT"

echo
echo "=== 1. ÖN KONTROL ==="

for cmd in mksquashfs grub-mkrescue xorriso rsync sha256sum; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[OK] $cmd"
    else
        echo "[HATA] Eksik araç: $cmd"
        exit 1
    fi
done

for path in \
    "$ROOT" \
    custom-disk/boot/grub/grub.cfg \
    custom-disk/boot/grub/loopback.cfg \
    custom-disk/EFI/boot/bootx64.efi \
    "$ROOT/boot/vmlinuz-7.0.0-34-generic" \
    "$ROOT/boot/initrd.img-7.0.0-34-generic"
do
    if [ -e "$path" ]; then
        echo "[OK] $path"
    else
        echo "[HATA] Eksik: $path"
        exit 1
    fi
done

echo
echo "=== 2. ESKİ STAGING TEMİZLENİYOR ==="

sudo rm -rf "$STAGING"
sudo mkdir -p \
    "$STAGING/casper" \
    "$STAGING/boot" \
    "$STAGING/EFI"

echo "[OK] build/iso temizlendi."

echo
echo "=== 3. CUSTOM-DISK ISO TABANI ==="

sudo rsync -a \
    custom-disk/ \
    "$STAGING/"

echo "[OK] custom-disk aktarıldı."

echo
echo "=== 4. GALAPAGOS ISO BİLGİSİ ==="

sudo mkdir -p "$STAGING/.disk"

printf '%s\n' \
    'Galapagos Linux 26.04 LTS - amd64' \
    | sudo tee "$STAGING/.disk/info" >/dev/null

echo "[OK] .disk/info güncellendi."

echo
echo "=== 5. KERNEL / INITRD ==="

sudo cp \
    "$ROOT/boot/vmlinuz-7.0.0-34-generic" \
    "$STAGING/casper/vmlinuz"

sudo cp \
    "$ROOT/boot/initrd.img-7.0.0-34-generic" \
    "$STAGING/casper/initrd"

echo "[OK] Kernel ve initrd güncel rootfs'tan alındı."

echo
echo "=== 6. FILESYSTEM.SQUASHFS OLUŞTURULUYOR ==="

sudo rm -f "$STAGING/casper/filesystem.squashfs"

sudo mksquashfs \
    "$ROOT" \
    "$STAGING/casper/filesystem.squashfs" \
    -comp xz \
    -b 1M \
    -noappend \
    -wildcards

echo "[OK] filesystem.squashfs oluşturuldu."

echo
echo "=== 7. FILESYSTEM MANIFEST ==="

sudo chroot "$ROOT" \
    dpkg-query -W -f='${binary:Package} ${Version}\n' \
    | sort \
    | sudo tee "$STAGING/casper/filesystem.manifest" >/dev/null

echo "[OK] filesystem.manifest oluşturuldu."

echo
echo "=== 8. FILESYSTEM SIZE ==="

sudo du -sx --block-size=1 "$ROOT" \
    | awk '{print $1}' \
    | sudo tee "$STAGING/casper/filesystem.size" >/dev/null

echo "[OK] filesystem.size oluşturuldu."

echo
echo "=== 9. GRUB KONTROL ==="

sudo cp \
    custom-disk/boot/grub/grub.cfg \
    "$STAGING/boot/grub/grub.cfg"

sudo cp \
    custom-disk/boot/grub/loopback.cfg \
    "$STAGING/boot/grub/loopback.cfg"

if grep -qi 'Ubuntu' "$STAGING/boot/grub/grub.cfg"; then
    echo "[HATA] ISO GRUB içinde Ubuntu metni bulundu."
    exit 1
fi

if ! grep -q 'galapagos.install=1' \
    "$STAGING/boot/grub/grub.cfg"; then
    echo "[HATA] Galapagos Kur parametresi bulunamadı."
    exit 1
fi

echo "[OK] GRUB Galapagos."

echo
echo "=== 10. EFI KONTROL ==="

for f in \
    "$STAGING/EFI/boot/bootx64.efi" \
    "$STAGING/EFI/boot/grubx64.efi" \
    "$STAGING/EFI/boot/mmx64.efi"
do
    if [ -f "$f" ]; then
        echo "[OK] $f"
    else
        echo "[HATA] Eksik EFI dosyası: $f"
        exit 1
    fi
done

echo
echo "=== 11. ISO OLUŞTURULUYOR ==="

sudo rm -f "$ISO"

sudo grub-mkrescue \
    -o "$ISO" \
    "$STAGING"

sudo chown "$USER:$USER" "$ISO"

echo "[OK] ISO oluşturuldu."

echo
echo "=== 12. ISO DOSYA BİLGİSİ ==="

ls -lh "$ISO"

echo
echo "=== 13. ISO EL TORITO KONTROLÜ ==="

xorriso \
    -indev "$ISO" \
    -report_el_torito plain \
    2>/dev/null

echo
echo "=== 14. ISO CASPER KONTROLÜ ==="

xorriso \
    -indev "$ISO" \
    -ls /casper \
    2>/dev/null \
    | grep -E \
        'filesystem\.manifest|filesystem\.size|filesystem\.squashfs|initrd|vmlinuz' \
    || true

echo
echo "=== 15. SQUASHFS KONTROLÜ ==="

sudo unsquashfs -s \
    "$STAGING/casper/filesystem.squashfs" \
    | head -20

echo
echo "=== 16. ISO İÇERİĞİ BRANDING KONTROLÜ ==="

if xorriso \
    -indev "$ISO" \
    -find / -name bootx64.efi -print \
    2>/dev/null | grep -q 'EFI/boot/bootx64.efi'
then
    echo "[OK] UEFI bootx64.efi ISO içinde."
else
    echo "[HATA] UEFI bootx64.efi ISO içinde bulunamadı."
    exit 1
fi

echo
echo "=== 17. SHA256 ==="

sha256sum "$ISO" | tee "$ISO.sha256"

echo
echo "=== 18. FINAL ISO LINK ==="

mkdir -p "$PROJECT/iso"

rm -f "$FINAL"

ln "$ISO" "$FINAL"

echo "[OK] Final ISO:"
ls -lh "$FINAL"

echo
echo "============================================================"
echo " GALAPAGOS ISO BUILD TAMAMLANDI"
echo "============================================================"
echo
echo "ISO:"
echo "$ISO"
echo
echo "Final:"
echo "$FINAL"
echo
echo "SHA256:"
cat "$ISO.sha256"
echo
echo "============================================================"
