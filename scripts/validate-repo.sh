#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK_EXTERNAL_INPUTS=0

if [ "${1:-}" = "--with-external-inputs" ]; then
    CHECK_EXTERNAL_INPUTS=1
fi

fail() {
    printf '[HATA] %s\n' "$*" >&2
    exit 1
}

info() {
    printf '[BİLGİ] %s\n' "$*"
}

check_shell_syntax() {
    info "Shell syntax kontrolü"

    bash -n "$PROJECT/scripts/build-iso.sh"
    bash -n "$PROJECT/scripts/clean-live-apps.sh"
    bash -n "$PROJECT/scripts/validate-repo.sh"

    sh -n "$PROJECT/config/scripts/galapagos-live-installer"
    sh -n "$PROJECT/config/scripts/galapagos-live-branding"
}

check_python_syntax() {
    info "Python AST/compile kontrolü"

    python3 - <<'PY' "$PROJECT/config/calamares/modules/galapagos-desktop/main.py"
import ast
import pathlib
import py_compile
import sys

path = pathlib.Path(sys.argv[1])
source = path.read_text(encoding='utf-8')
ast.parse(source, filename=str(path))
py_compile.compile(str(path), doraise=True)
PY
}

check_settings_references() {
    info "Calamares settings/module/path tutarlılığı"

    local settings_file="$PROJECT/config/calamares/settings.conf"
    local module_file local_rel runtime_path

    while IFS= read -r module_file; do
        [ -n "$module_file" ] || continue
        [ -f "$PROJECT/config/calamares/modules/$module_file" ] || fail "settings.conf içinde geçen modül config eksik: $module_file"
    done < <(sed -n 's/^[[:space:]]*config:[[:space:]]*//p' "$settings_file")

    [ -f "$PROJECT/config/calamares/modules/galapagos-desktop/module.desc" ] || fail "Özel modül tanımı eksik: galapagos-desktop/module.desc"
    [ -f "$PROJECT/config/calamares/modules/galapagos-desktop/main.py" ] || fail "Özel modül scripti eksik: galapagos-desktop/main.py"

    while IFS= read -r runtime_path; do
        [ -n "$runtime_path" ] || continue
        local_rel="${runtime_path#/etc/calamares/branding/galapagos/}"
        [ -f "$PROJECT/config/calamares/branding/galapagos/$local_rel" ] || fail "Branding asset eksik: $runtime_path"
    done < <(grep -Rho '/etc/calamares/branding/galapagos/[^"[:space:]]*' "$PROJECT/config/calamares" | sort -u)
}

check_executable_bits() {
    info "Executable bit kontrolleri"

    local required_exec

    for required_exec in \
        "$PROJECT/scripts/build-iso.sh" \
        "$PROJECT/scripts/clean-live-apps.sh" \
        "$PROJECT/scripts/validate-repo.sh" \
        "$PROJECT/config/scripts/galapagos-live-installer" \
        "$PROJECT/config/scripts/galapagos-live-branding"
    do
        [ -x "$required_exec" ] || fail "Çalıştırılabilir değil: $required_exec"
    done
}

check_stale_branding_terms() {
    info "Çalışma zamanı dosyalarında stale branding kontrolü"

    local match_output

    match_output="$(grep -RInE '(ubuntu|kubuntu|debian)' \
        "$PROJECT/scripts/build-iso.sh" \
        "$PROJECT/scripts/clean-live-apps.sh" \
        "$PROJECT/config/scripts" \
        "$PROJECT/config/desktop" \
        "$PROJECT/config/calamares/settings.conf" \
        "$PROJECT/config/calamares/modules/packagechooser_desktop.conf" \
        "$PROJECT/config/calamares/modules/packagechooser_installtype.conf" \
        "$PROJECT/config/calamares/modules/packages.conf" \
        "$PROJECT/config/calamares/modules/displaymanager.conf" \
        "$PROJECT/config/calamares/modules/finished.conf" \
        "$PROJECT/config/calamares/modules/fstab.conf" \
        "$PROJECT/config/calamares/modules/shellprocess_rmcdrom.conf" \
        "$PROJECT/config/calamares/modules/mount.conf" \
        "$PROJECT/config/calamares/modules/unpackfs.conf" \
        "$PROJECT/config/calamares/modules/bootloader.conf" \
        "$PROJECT/config/calamares/modules/grubcfg.conf" \
        "$PROJECT/config/calamares/modules/umount.conf" \
        "$PROJECT/config/calamares/modules/galapagos-desktop/main.py" \
        "$PROJECT/config/calamares/branding/galapagos/branding.desc" \
        "$PROJECT/config/calamares/branding/galapagos/calamares-navigation.qml" \
        "$PROJECT/config/calamares/branding/galapagos/calamares-sidebar.qml" \
        "$PROJECT/config/calamares/branding/galapagos/show.qml" \
        "$PROJECT/config/calamares/branding/galapagos/stylesheet.qss" \
        || true)"

    if [ -n "$match_output" ]; then
        printf '%s\n' "$match_output"
        fail "Stale Ubuntu/Kubuntu/Debian ifadeleri bulundu."
    fi
}

check_external_inputs() {
    info "Dış build girdileri kontrolü (--with-external-inputs)"

    local required_path

    for required_path in \
        "$PROJECT/build/live-root" \
        "$PROJECT/custom-disk/boot/grub/grub.cfg" \
        "$PROJECT/custom-disk/boot/grub/loopback.cfg" \
        "$PROJECT/custom-disk/EFI/boot/bootx64.efi"
    do
        [ -e "$required_path" ] || fail "Dış girdi eksik: $required_path"
    done
}

info "Repository doğrulama başlatıldı"
check_shell_syntax
check_python_syntax
check_settings_references
check_executable_bits
check_stale_branding_terms

if [ "$CHECK_EXTERNAL_INPUTS" -eq 1 ]; then
    check_external_inputs
else
    info "Dış girdiler bu çalıştırmada kontrol edilmedi (isteğe bağlı: --with-external-inputs)"
fi

info "Tüm doğrulamalar başarılı."
