# Galapagos Linux

Galapagos Linux, Ubuntu tabanlı ve Calamares kullanan bir Linux dağıtımı
projesidir. Cinnamon, KDE Plasma ve GNOME seçenekleri sunar.

## Proje yapısı

- config/calamares/ — Calamares ayarları ve Galapagos branding
- config/scripts/ — Live ortam yardımcı scriptleri
- config/desktop/ — masaüstü launcher dosyaları
- scripts/ — ISO build scriptleri
- packages/ — paket metadata/listeleri

## ISO build

Gerekli araçlar: mksquashfs, grub-mkrescue, xorriso, rsync, unsquashfs.

Mevcut ISO paketleme adımı önceden hazırlanmış build/live-root ve
custom-disk girdilerini bekler.

    cd ~/galapagos
    ./scripts/build-iso.sh

## Calamares

Kurulum seçenekleri: Cinnamon, KDE Plasma, GNOME

Kurulum türleri: Minimal, Standard

## Test

ISO önce VirtualBox gibi bir sanal makinede test edilmelidir.
GRUB, Live oturum, Calamares, kurulum, reboot ve ilk açılış doğrulanmalıdır.

## Geliştirme durumu

Repository henüz rootfs'ı sıfırdan oluşturan tam reproducible pipeline değildir.
build/live-root ve custom-disk girdilerinin üretimi sonraki geliştirme adımıdır.
