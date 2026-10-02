#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$PROJECT/build/live-root"
STAGING="$PROJECT/build/iso"
ISO="$PROJECT/build/galapagos-26.04-amd64.iso"
FINAL="$PROJECT/iso/galapagos-linux-1.0.0-amd64.iso"
CUSTOM_DISK="$PROJECT/custom-disk"
BUILD_USER="${SUDO_USER:-$(id -un)}"
BUILD_GROUP="$(id -gn "$BUILD_USER" 2>/dev/null || printf "%s" "$BUILD_USER")"

readonly REQUIRED_TOOLS=(
    awk
    find
    grep
    grub-mkrescue
    mksquashfs
    mount
    mountpoint
    rsync
    sha256sum
    sort
    sudo
    umount
    unsquashfs
    xorriso
)

readonly REQUIRED_REPO_SOURCES=(
    "$PROJECT/config/calamares/settings.conf"
    "$PROJECT/config/calamares/modules"
    "$PROJECT/config/calamares/branding/galapagos"
    "$PROJECT/config/scripts/galapagos-live-installer"
    "$PROJECT/config/scripts/galapagos-live-branding"
    "$PROJECT/config/desktop/galapagos-installer.desktop"
    "$PROJECT/config/desktop/galapagos-live-branding.desktop"
    "$PROJECT/config/icons/galapagos-installer.svg"
    "$PROJECT/config/backgrounds/galapagos-wallpaper.svg"
    "$PROJECT/scripts/clean-live-apps.sh"
)

readonly REQUIRED_EXTERNAL_INPUTS=(
    "$ROOT"
    "$CUSTOM_DISK/boot/grub/grub.cfg"
    "$CUSTOM_DISK/boot/grub/loopback.cfg"
    "$CUSTOM_DISK/EFI/boot/bootx64.efi"
)

CHROOT_MOUNTS=()

log() {
    printf '%s\n' "$*"
}

die() {
    printf '[HATA] %s\n' "$*" >&2
    exit 1
}

cleanup_mounts() {
    local index

    for (( index=${#CHROOT_MOUNTS[@]}-1; index>=0; index-- )); do
        if sudo mountpoint -q "${CHROOT_MOUNTS[$index]}"; then
            sudo umount "${CHROOT_MOUNTS[$index]}" || true
        fi
    done
}

trap cleanup_mounts EXIT

require_tool() {
    command -v "$1" >/dev/null 2>&1 || die "Eksik araç: $1"
}

require_path() {
    [ -e "$1" ] || die "Eksik: $1"
}

install_repo_assets() {
    log "[BİLGİ] Repository dosyaları live root içine kuruluyor..."

    sudo rm -rf "$ROOT/etc/calamares"
    sudo mkdir -p "$ROOT/etc/calamares"
    sudo rsync -a --delete "$PROJECT/config/calamares/" "$ROOT/etc/calamares/"

    sudo install -Dm755 "$PROJECT/config/scripts/galapagos-live-installer" "$ROOT/usr/local/bin/galapagos-live-installer"
    sudo install -Dm755 "$PROJECT/config/scripts/galapagos-live-branding" "$ROOT/usr/local/bin/galapagos-live-branding"
    sudo install -Dm755 "$PROJECT/scripts/clean-live-apps.sh" "$ROOT/usr/local/sbin/galapagos-clean-live-apps"

    sudo install -Dm644 "$PROJECT/config/desktop/galapagos-installer.desktop" "$ROOT/usr/share/applications/galapagos-installer.desktop"
    sudo install -Dm644 "$PROJECT/config/desktop/galapagos-live-branding.desktop" "$ROOT/etc/xdg/autostart/galapagos-live-branding.desktop"

    sudo install -Dm644 "$PROJECT/config/icons/galapagos-installer.svg" "$ROOT/usr/share/icons/hicolor/scalable/apps/galapagos-installer.svg"
    sudo install -Dm644 "$PROJECT/config/backgrounds/galapagos-wallpaper.svg" "$ROOT/usr/share/backgrounds/galapagos/galapagos-wallpaper.svg"
}

mount_chroot_tree() {
    local source="$1"
    local target="$2"
    local fstype="$3"

    sudo mkdir -p "$target"

    if sudo mountpoint -q "$target"; then
        return
    fi

    case "$fstype" in
        bind)
            sudo mount --bind "$source" "$target"
            ;;
        proc)
            sudo mount -t proc proc "$target"
            ;;
        sysfs)
            sudo mount -t sysfs sys "$target"
            ;;
        tmpfs)
            sudo mount -t tmpfs tmpfs "$target"
            ;;
        efivarfs)
            sudo mount -t efivarfs efivarfs "$target"
            ;;
        *)
            die "Bilinmeyen mount türü: $fstype"
            ;;
    esac

    CHROOT_MOUNTS+=("$target")
}

run_live_root_maintenance() {
    log "[BİLGİ] Chroot mount ağaçları hazırlanıyor..."

    mount_chroot_tree /dev "$ROOT/dev" bind
    mount_chroot_tree proc "$ROOT/proc" proc
    mount_chroot_tree sys "$ROOT/sys" sysfs
    mount_chroot_tree tmpfs "$ROOT/run" tmpfs

    if [ -d /run/udev ]; then
        mount_chroot_tree /run/udev "$ROOT/run/udev" bind
    fi

    if [ -d /run/systemd/resolve ]; then
        mount_chroot_tree /run/systemd/resolve "$ROOT/run/systemd/resolve" bind
    fi

    if [ -d /cdrom ]; then
        mount_chroot_tree /cdrom "$ROOT/cdrom" bind
    fi

    if [ -d /sys/firmware/efi/efivars ]; then
        mount_chroot_tree efivarfs "$ROOT/sys/firmware/efi/efivars" efivarfs
    fi

    log "[BİLGİ] Live cleanup scripti çalıştırılıyor..."
    sudo chroot "$ROOT" /usr/local/sbin/galapagos-clean-live-apps

    log "[BİLGİ] Paket manifesti üretiliyor..."
    sudo chroot "$ROOT" dpkg-query -W -f='${binary:Package} ${Version}\n' | sort | sudo tee "$STAGING/casper/filesystem.manifest" >/dev/null

    cleanup_mounts
    CHROOT_MOUNTS=()
}

verify_no_live_mounts() {
    local candidate

    for candidate in "$ROOT/dev" "$ROOT/proc" "$ROOT/sys" "$ROOT/run" "$ROOT/run/udev" "$ROOT/run/systemd/resolve" "$ROOT/cdrom" "$ROOT/sys/firmware/efi/efivars"; do
        if [ -d "$candidate" ] && sudo mountpoint -q "$candidate"; then
            die "Mount temizliği tamamlanamadı: $candidate"
        fi
    done
}

copy_kernel_and_initrd() {
    local kernel_file kernel_version initrd_file

    kernel_file="$(find "$ROOT/boot" -maxdepth 1 -type f -name 'vmlinuz-*' -printf '%f\n' | sort -V | tail -n 1)"
    [ -n "$kernel_file" ] || die "RootFS içinde kernel bulunamadı."

    kernel_version="${kernel_file#vmlinuz-}"
    initrd_file="initrd.img-${kernel_version}"
    [ -f "$ROOT/boot/$initrd_file" ] || die "Eşleşen initrd bulunamadı: $initrd_file"

    log "[OK] Kernel: $kernel_file"
    log "[OK] Initrd: $initrd_file"

    sudo cp "$ROOT/boot/$kernel_file" "$STAGING/casper/vmlinuz"
    sudo cp "$ROOT/boot/$initrd_file" "$STAGING/casper/initrd"
}

create_squashfs() {
    log "[BİLGİ] filesystem.squashfs oluşturuluyor..."

    sudo rm -f "$STAGING/casper/filesystem.squashfs"
    sudo mksquashfs "$ROOT" "$STAGING/casper/filesystem.squashfs" \
        -comp xz \
        -b 1M \
        -noappend \
        -wildcards \
        -e dev proc sys run cdrom tmp var/tmp

    sudo du -sx --block-size=1 "$ROOT" | awk '{print $1}' | sudo tee "$STAGING/casper/filesystem.size" >/dev/null
}

validate_grub_and_efi() {
    sudo cp "$CUSTOM_DISK/boot/grub/grub.cfg" "$STAGING/boot/grub/grub.cfg"
    sudo cp "$CUSTOM_DISK/boot/grub/loopback.cfg" "$STAGING/boot/grub/loopback.cfg"

    if grep -qi "Ubuntu" "$STAGING/boot/grub/grub.cfg"; then
        die "GRUB içinde Ubuntu metni bulundu."
    fi

    grep -q "galapagos.install=1" "$STAGING/boot/grub/grub.cfg" || die "galapagos.install=1 eksik."

    if [ -f "$STAGING/EFI/boot/bootx64.efi" ] && [ -f "$STAGING/EFI/boot/grubx64.efi" ] && [ -f "$STAGING/EFI/boot/mmx64.efi" ]; then
        log "[OK] EFI dosyaları mevcut."
    else
        die "Gerekli EFI dosyaları eksik."
    fi
}

main() {
    local cmd source_path

    cd "$PROJECT"

    log "=== Galapagos ISO Build ==="

    for cmd in "${REQUIRED_TOOLS[@]}"; do
        require_tool "$cmd"
    done

    for source_path in "${REQUIRED_REPO_SOURCES[@]}"; do
        require_path "$source_path"
    done

    for source_path in "${REQUIRED_EXTERNAL_INPUTS[@]}"; do
        require_path "$source_path"
    done

    sudo rm -rf "$STAGING"
    sudo mkdir -p "$STAGING/casper" "$STAGING/boot/grub" "$STAGING/EFI"
    sudo rsync -a "$CUSTOM_DISK/" "$STAGING/"

    install_repo_assets

    sudo mkdir -p "$STAGING/.disk"
    printf "%s\n" "Galapagos Linux 26.04 LTS - amd64" | sudo tee "$STAGING/.disk/info" >/dev/null

    copy_kernel_and_initrd
    run_live_root_maintenance
    verify_no_live_mounts
    create_squashfs
    validate_grub_and_efi

    sudo rm -f "$ISO"
    sudo grub-mkrescue -o "$ISO" "$STAGING"
    sudo chown "$BUILD_USER:$BUILD_GROUP" "$ISO"

    sha256sum "$ISO" | tee "$ISO.sha256"

    sudo mkdir -p "$PROJECT/iso"
    sudo rm -f "$FINAL"
    sudo ln -sfn "../build/galapagos-26.04-amd64.iso" "$FINAL"

    log "[OK] ISO: $ISO"
    log "[OK] Final: $FINAL"
    ls -lh "$ISO" "$FINAL"
}

main "$@"
