### AnyKernel3 script - Redmi Note 9S (curtana) NetHunter Wi-Fi kernel
## Based on osm0sis' AnyKernel3 template

### AnyKernel setup
# global properties
properties() { '
kernel.string=LawRun NetHunter Wi-Fi kernel for Redmi Note 9S (curtana)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=curtana
device.name2=miatoll
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# boot shell variables (curtana is an A-only device)
BLOCK=/dev/block/bootdevice/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# ---- Safety net: back up the current boot + dtbo before touching anything ----
BK=/sdcard/NetHunter-backup;
[ -d /sdcard ] || BK=/data/media/0/NetHunter-backup;
mkdir -p $BK;
STAMP=$(date +%Y%m%d-%H%M%S);
ui_print " " "Backing up current boot/dtbo to $BK ...";
dd if=$BLOCK of=$BK/boot-$STAMP.img 2>/dev/null || ui_print "WARNING: boot backup failed";
for D in /dev/block/bootdevice/by-name/dtbo /dev/block/by-name/dtbo; do
  if [ -e $D ]; then dd if=$D of=$BK/dtbo-$STAMP.img 2>/dev/null || ui_print "WARNING: dtbo backup failed"; break; fi;
done;

# boot install (replaces kernel + dtb, keeps the stock MIUI ramdisk; writes dtbo.img too)
dump_boot;
write_boot;
## end boot install
