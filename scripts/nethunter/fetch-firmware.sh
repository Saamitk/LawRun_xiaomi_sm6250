#!/usr/bin/env bash
# Download the Wi-Fi firmware blobs that get linked into the kernel image
# (CONFIG_EXTRA_FIRMWARE) from the linux-firmware tree.
#
# Usage: scripts/nethunter/fetch-firmware.sh <kernel-src-dir> <out-dir>/.config
#
# - htc_9271 (TL-WN722N v1) and rt2870.bin (RT3070/RT5370) are REQUIRED: the
#   script fails if they can't be fetched.
# - The rest are optional; whatever can't be fetched is removed from
#   CONFIG_EXTRA_FIRMWARE in the given .config so the build never breaks.
set -euo pipefail

SRC=${1:?kernel source dir}
CONFIG=${2:?path to .config}

# Pinned linux-firmware commit (mirror of kernel.org linux-firmware.git)
FW_REPO=${FW_REPO:-CirrusLogic/linux-firmware}
FW_REF=${FW_REF:-33b68e2c701198457657c2e656ef9a9cc4272d01}
BASE="https://raw.githubusercontent.com/${FW_REPO}/${FW_REF}"

REQUIRED="ath9k_htc/htc_9271-1.4.0.fw rt2870.bin"
# "name-the-kernel-asks-for|path-in-linux-firmware"
FILES="
ath9k_htc/htc_9271-1.4.0.fw|ath9k_htc/htc_9271-1.4.0.fw
ath9k_htc/htc_7010-1.4.0.fw|ath9k_htc/htc_7010-1.4.0.fw
rt2870.bin|rt2870.bin
rt73.bin|rt73.bin
mt7601u.bin|mediatek/mt7601u.bin
carl9170-1.fw|carl9170-1.fw
rtlwifi/rtl8192cufw_A.bin|rtlwifi/rtl8192cufw_A.bin
rtlwifi/rtl8192cufw_B.bin|rtlwifi/rtl8192cufw_B.bin
rtlwifi/rtl8192cufw_TMSC.bin|rtlwifi/rtl8192cufw_TMSC.bin
rtlwifi/rtl8192eu_nic.bin|rtlwifi/rtl8192eu_nic.bin
rtlwifi/rtl8723aufw_A.bin|rtlwifi/rtl8723aufw_A.bin
rtlwifi/rtl8723aufw_B.bin|rtlwifi/rtl8723aufw_B.bin
rtlwifi/rtl8723aufw_B_NoBT.bin|rtlwifi/rtl8723aufw_B_NoBT.bin
rtlwifi/rtl8723bu_nic.bin|rtlwifi/rtl8723bu_nic.bin
rtlwifi/rtl8723bu_bt.bin|rtlwifi/rtl8723bu_bt.bin
"

FWDIR="$SRC/firmware"
mkdir -p "$FWDIR"
ok=()
for entry in $FILES; do
    want=${entry%%|*}; path=${entry##*|}
    mkdir -p "$FWDIR/$(dirname "$want")"
    if { curl -fsSL --retry 3 -o "$FWDIR/$want" "$BASE/$path" 2>/dev/null ||
         { command -v gh >/dev/null && gh api -H "Accept: application/vnd.github.raw" \
             "repos/${FW_REPO}/contents/${path}?ref=${FW_REF}" > "$FWDIR/$want" 2>/dev/null; }; } \
       && [ -s "$FWDIR/$want" ]; then
        echo "fetched  $want ($(stat -c %s "$FWDIR/$want") bytes)"
        ok+=("$want")
    else
        rm -f "$FWDIR/$want"
        if [[ " $REQUIRED " == *" $want "* ]]; then
            echo "ERROR: required firmware $want could not be downloaded" >&2
            exit 1
        fi
        echo "skipped  $want (not available)"
    fi
done

sed -i "s|^CONFIG_EXTRA_FIRMWARE=.*|CONFIG_EXTRA_FIRMWARE=\"${ok[*]}\"|" "$CONFIG"
grep '^CONFIG_EXTRA_FIRMWARE' "$CONFIG"
