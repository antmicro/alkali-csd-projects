# This is a boot script for U-Boot
# Generate boot.scr:
# mkimage -c none -A arm -T script -d boot_basalt.cmd boot.scr

setenv bootargs "earlycon root=/dev/ram0 rw rootwait"
setenv fdt_high 0x60000000
setenv initrd_high 0x60000000
booti 0x18000000 0x2100000 0x40000000
