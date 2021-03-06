# uboot-boot-scr.bbclass
#
# This provides a method to create a boot.ini or boot.scr files to help
# configure u-boot at boot up time
#
# UBOOT_FDT_FILE: default device tree. e.g., "KERNEL_DEVICETREE"
#
# UBOOT_FDT_LOADADDR: default Device tree load address, e.g., "0x01000000"
#
# UBOOT_INITRD_NAME: default initrd image name, e.g., "uInitrd"
#
# UBOOT_INITRD_ADDR: default initrd image load address, e.g., "0x2000000"
#
# UBOOT_CONSOLE: default console, e.g.,  "ttyttySAC2,115200"
#
# UBOOT_LOAD_CMD: default partition, e.g., "load"
#
# UBOOT_BOOTDEV: default boot device #
#
# UBOOT_BOOTPART: default boot partition #
#
# UBOOT_ROOTDEV: default root device #
#
# UBOOT_ROOTPART: default root device #
#
# UBOOT_FILE_TITLE: default partition, e.g., "UBOOT-CONFIG"
#
# UBOOT_EXTRA_ENV: default add extra env vars , e.g., "vout,'vga'"
#
# Copyright (C) 2017, Armin Kuster <akuster808@gmail.com> 
# All Rights Reserved Released under the MIT license (see packages/COPYING)
#
inherit kernel-arch

DEPENDS += "u-boot-mkimage-native"

# enable by default
USE_BOOTSCR ?=  '1'

UBOOT_ENV_SUFFIX ??= "scr"
UBOOT_ENV ?= "boot"

UBOOT_ENV_CONFIG ?= "${B}/${UBOOT_ENV}.txt"

UBOOT_LOADADDRESS ?= "0x40007FC0"
UBOOT_FDT_LOADADDR ?= "0x40800000"
UBOOT_KERNEL_NAME ?= "zimage"
UBOOT_INITRD_NAME ?= ""
UBOOT_INITRD_ADDR ?= ""

#UBOOT_CONSOLE ?= "console=ttySAC2,115200"
UBOOT_BOOTDEV  ?= "0"
UBOOT_BOOTPART ?= "1"
UBOOT_ROOTDEV ?= ""
UBOOT_ROOTPART ?= "2"
UBOOT_BOOT_CMD ?= "bootz"

UBOOT_LOAD_CMD ?= "load"
UBOOT_EXTRA_ENV ?= ""
UBOOT_FILE_TITLE ?= "#"

python create_uboot_boot_txt() {
    if d.getVar("USE_BOOTSCR") != "1":
      return

    if not d.getVar('WORKDIR'):
        bb.error("WORKDIR not defined, unable to package")

    cfile = d.getVar('UBOOT_ENV_CONFIG')
    if not cfile:
        bb.fatal('Unable to read UBOOT_ENV_CONFIG')

    localdata = bb.data.createCopy(d)

    try:
        with open(cfile, 'w') as cfgfile:

            # Title for boot.ini on some boards
            title = localdata.getVar('UBOOT_FILE_TITLE')
            if title:
                cfgfile.write('%s\n' % title)

            console = localdata.getVar('UBOOT_CONSOLE')
            if console:
                cfgfile.write('setenv console \"%s\" \n' % console) 
           
            loadcmd = localdata.getVar('UBOOT_LOAD_CMD')
            cfgfile.write('setenv loadcmd \"%s\" \n' % loadcmd) 

            mmcbootdev = localdata.getVar('UBOOT_BOOTDEV')
            if mmcbootdev:
                cfgfile.write('setenv mmcbootdev %s\n' % mmcbootdev )

            mmcbootpart = localdata.getVar('UBOOT_BOOTPART')
            if mmcbootpart:
                cfgfile.write('setenv mmcbootpart %s\n' % mmcbootpart )

            mmcrootdev = localdata.getVar('UBOOT_ROOTDEV')
            if mmcrootdev:
                cfgfile.write('setenv mmcrootdev %s\n' % mmcrootdev)

            mmcrootpart = localdata.getVar('UBOOT_ROOTPART')
            if mmcrootpart :
                cfgfile.write('setenv mmcrootpart %s\n' % mmcrootpart )

            # initrd
            initrdaddr = localdata.getVar('UBOOT_INITRD_ADDR')
            if initrdaddr:
                cfgfile.write('setenv initrdaddr  %s\n' % initrdaddr)

            initrd = localdata.getVar('UBOOT_INITRD_NAME')
            if initrd:
                cfgfile.write('setenv initrdname  \"%s\"\n' % initrd) 

            kerneladdr = localdata.getVar('UBOOT_LOADADDRESS')
            cfgfile.write('setenv kerneladdr \"%s\"\n' % kerneladdr)

            fdtaddr = localdata.getVar('UBOOT_FDT_LOADADDR')
            cfgfile.write('setenv fdtaddr %s\n' % fdtaddr)

            fdtfile = os.path.basename(localdata.getVar('KERNEL_DEVICETREE'))
            cfgfile.write('setenv fdtfile \"%s\"\n' % fdtfile)


            imgbootcmd = localdata.getVar('UBOOT_BOOT_CMD')
            cfgfile.write('setenv imgbootcmd \"%s\" \n' % imgbootcmd) 

            kernelname = localdata.getVar('UBOOT_KERNEL_NAME')
            cfgfile.write('setenv kernelname %s\n' % kernelname)

            cfgfile.write('setenv loaddtb     \"${loadcmd} mmc ${mmcbootdev}:${mmcbootpart} ${fdtaddr} ${fdtfile}\"\n')
            cfgfile.write('setenv loadkernel  \"${loadcmd} mmc ${mmcbootdev}:${mmcbootpart} ${kerneladdr} ${kernelname}\"\n')

            if initrd:
                cfgfile.write('setenv loadinitrd  \"${loadcmd} mmc ${mmcbootdev}:${mmcbootpart} ${initrdaddr} ${initrdname}"\n')

            cfgfile.write('setenv bootargs \"${console} root=/dev/mmcblk1p${mmcrootpart} rw rootwait\"\n')
            cfgfile.write('run loaddtb\n')
            cfgfile.write('run loadkernel\n')

            if initrd:
                cfgfile.write('run loadinitrd\n')
                cfgfile.write('%s %s %s %s" %(imgbootcmd, kerneladdr, initrd_addr, fdtaddr))\n')
            else:
                cfgfile.write('%s %s - %s\n' % (imgbootcmd, kerneladdr, fdtaddr))

    except OSError:
        bb.fatal('Unable to open %s' % (cfile))
}

FILES_${PN} += "/*.${UBOOT_ENV_SUFFIX}"

do_compile[prefuncs] += "create_uboot_boot_txt"

do_compile_prepend () {
    if [ "${UBOOT_ENV_SUFFIX}" = "scr" ]; then
        echo "uboot-mkimage -C none -A ${ARCH} -T script -d ${UBOOT_ENV_CONFIG} ${WORKDIR}/${UBOOT_ENV_BINARY}"
        uboot-mkimage -C none -A ${ARCH} -T script -d ${UBOOT_ENV_CONFIG} ${WORKDIR}/${UBOOT_ENV_BINARY}
    else
        cp ${UBOOT_ENV_CONFIG} ${WORKDIR}/${UBOOT_ENV_BINARY}
    fi
}

