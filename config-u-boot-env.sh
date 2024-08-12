echo "
# generic params
bootdelay=3
stderr=serial,lcd
stdin=serial,usbkbd
stdout=serial,lcd

# CPU config
cpu=armv8
smp=on

# Console config
baudrate=115200
sttyconsole=ttyS0
ttyconsole=tty0

# NFS/TFTP boot configuraton
gatewayip=192.168.1.1
netmask=255.255.255.0
nfsserverip=192.168.1.1
nfspath=/srv/nfs/rpi

# bootcmd & bootargs configuration
preboot=usb start
bootcmd=run mmcboot
set_bootargs_tty=setenv bootargs console=${ttyconsole} console=${sttyconsole},${baudrate}
set_bootargs_nfs=setenv bootargs ${bootargs} root=/dev/nfs rw rootfstype=nfs nfsroot=${nfsserverip}:${nfspath},udp,vers=3 ip=dhcp
set_common_args=setenv bootargs ${bootargs} smsc95xx.macaddr=${ethaddr} 'dma.dmachans=0x7f35 rootwait 8250.nr_uarts=1 fsck.repair=yes bcm2708_fb.fbwidth=1920 bcm2708_fb.fbheight=1080 vc_mem.mem_base=0x3ec00000 vc_mem.mem_size=0x40000000 dwc_otg.fiq_enable=0 dwc_otg.fiq_fsm_enable=0 dwc_otg.nak_holdoff=0 root=/dev/mmcblk0p2 rw rootfs=ext4'

# fit boot
load_fit=fatload mmc 0:1 0x02000000 image.fit
boot_fit=bootm 0x02000000
mmcboot=run load_fit; run set_bootargs_tty set_common_args; run boot_fit
" > optee/build/rpi3/firmware/uboot.env.txt


