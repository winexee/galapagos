# Galapagos Linux

Galapagos Linux, Ubuntu tabanlı ve Calamares kullanan bir Linux dağıtımı
projesidir. Cinnamon, KDE Plasma ve GNOME seçenekleri sunar.

## Proje yapısı

- config/calamares/ — Calamares ayarları ve Galapagos branding
- config/scripts/ — Live ortam yardımcı scriptleri
- config/desktop/ — masaüstü launcher dosyaları
- scripts/ — ISO build ve doğrulama scriptleri

## Dış önkoşullar (repository dışı girdiler)

Bu repository tek başına reproducible bir rootfs üreticisi değildir.
`scripts/build-iso.sh` çalışması için şu girdiler dışarıdan hazırlanmış olmalıdır:

- `build/live-root/` (kurulu paketleri ve kernel/initrd dosyalarını içeren hazır live root)
- `custom-disk/boot/grub/grub.cfg`
- `custom-disk/boot/grub/loopback.cfg`
- `custom-disk/EFI/boot/bootx64.efi`
- ayrıca `custom-disk/EFI/boot/grubx64.efi` ve `custom-disk/EFI/boot/mmx64.efi`

Build scripti bu girdileri açıkça doğrular ve eksikte hata ile durur.

## ISO build

Gerekli araçlar: `mksquashfs`, `grub-mkrescue`, `xorriso`, `rsync`, `unsquashfs`,
`mount`, `mountpoint`, `sudo`.

Repository içindeki Calamares/branding/live script/desktop/icon/wallpaper dosyaları,
`filesystem.squashfs` üretilmeden önce otomatik olarak `build/live-root` içine kurulur.

```bash
cd ~/galapagos
./scripts/build-iso.sh
```

## Doğrulama

Ağ erişimi veya paket indirme olmadan hızlı doğrulama:

```bash
./scripts/validate-repo.sh
```

Bu komut şunları kontrol eder:

- shell syntax (`bash -n`, `sh -n`)
- `galapagos-desktop` Python dosyası için AST/compile kontrolü
- Calamares settings/module/asset path tutarlılığı
- gerekli scriptlerde executable bit
- runtime-owned dosyalarda Ubuntu/Kubuntu/Debian branding kalıntısı

Dış girdileri de kontrol etmek için:

```bash
./scripts/validate-repo.sh --with-external-inputs
```

## Calamares

Kurulum seçenekleri: Cinnamon, KDE Plasma, GNOME.

Kurulum türleri (Minimal/Standard) için paket listelerinin tek kaynak noktası:
`config/calamares/modules/packagechooser_installtype.conf`

## Test

ISO mutlaka VirtualBox/gerçek makinede ayrıca test edilmelidir:

- UEFI ve BIOS boot
- GRUB menüsü ve `galapagos.install=1` davranışı
- Live oturum autostart davranışı
- Calamares kurulum akışı
- kurulum sonrası reboot ve ilk açılış
