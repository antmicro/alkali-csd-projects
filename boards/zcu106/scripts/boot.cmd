# This is a boot script for U-Boot
# Generate boot.scr:
# mkimage -c none -A arm -T script -d boot_zcu106.cmd boot.scr

setenv bootargs "earlycon root=/dev/ram0 rw rootwait cpuidle.off=1"
setenv fdt_high 0x60000000
setenv initrd_high 0x60000000

fatload mmc 0 ${kernel_addr_r} Image
fatload mmc 0 ${ramdisk_addr_r} rootfs.cpio.uboot
fatload mmc 0 ${fdt_addr_r} system.dtb

booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
