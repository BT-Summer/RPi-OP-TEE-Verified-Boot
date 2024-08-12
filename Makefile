ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: init cortex-a53-1530924 update-u-boot-env build fit update-image-build rebuild-uboot

########## BUILD TOOLS ###############

tools: corruptor/target/release/corruptor

corruptor/target/release/corruptor:
	cd corruptor && cargo build --release
	echo "binary file corruptor is at $(ROOT_DIR)/corruptor/target/release/corruptor"

########## FILE SET UP ###############

init:
	echo "#### init ####"
	sudo add-apt-repository universe -y
	grep -vE '^#' dependencies-22.04.txt | xargs sudo apt --ignore-missing install -y
	mkdir -p optee
	cd optee && yes y | repo init -u https://github.com/OP-TEE/manifest.git -m rpi3.xml -b 4.3.0
	cd optee && repo sync
	cp optee/build/Makefile Makefile-optee.bck

# Apply fix for cotext a53 errata 1530924 to TF-A's flags
cortex-a53-1530924:
	echo "#### cortex fix ####"
	sed -i -e 's/TF_A_FLAGS ?= \\/TF_A_FLAGS ?= ERRATA_A53_1530924=1 \\/' optee/build/Makefile

# Not used
# Replaces all bcm dtb references to the upstream dtbs
update-dtbs-2710:
	echo "#### update dtbs ####"
	sed -i -e 's/bcm2837-rpi-3-b-plus.dtb/bcm2710-rpi-3-b-plus.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2837-rpi-3-b.dtb/bcm2710-rpi-3-b.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2837-rpi-3-b-plus.dtb/bcm2710-rpi-3-b-plus.dtb/' optee/build/rpi3.mk
	sed -i -e 's/bcm2837-rpi-3-b.dtb/bcm2710-rpi-3-b.dtb/' optee/build/rpi3.mk

# Not used
# Replaces all bcm dtb references to the downstream dtbs
update-dtbs-2837:
	echo "#### update dtbs ####"
	sed -i -e 's/bcm2710-rpi-3-b-plus.dtb/bcm2837-rpi-3-b-plus.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2710-rpi-3-b.dtb/bcm2837-rpi-3-b.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2710-rpi-3-b-plus.dtb/bcm2837-rpi-3-b-plus.dtb/' optee/build/rpi3.mk
	sed -i -e 's/bcm2710-rpi-3-b.dtb/bcm2837-rpi-3-b.dtb/' optee/build/rpi3.mk

# Replace u-boot.env source with custom env
update-u-boot-env:
	echo "#### update u-boot env ####"
	rm ./optee/build/rpi3/firmware/uboot.env.txt
	./config-u-boot-env.sh

# Update which files the optee Makefile will place into the output disk image
update-image-build:
	echo "#### update image builder ####"
	rm -f optee/out/rpi3-sdcard.img
	# Use python for this to avoid conflicts with bash variables
	python3 image-build.py

# Not used
upgrade_uboot:
	echo "#### upgrade u-boot ####"
	sudo rm -rf optee/u-boot
	cd optee && git clone git://git.denx.de/u-boot.git
	cd optee/u-boot && git checkout v2024.07

########## BUILD #####################

build:
	echo "#### build toolchains ####"
	$(MAKE) -C ./optee/build -j3 toolchains
	rm -f optee/u-boot/configs/rpi_3_defconfig
	cp rpi_3_b_plus_fit_defconfig optee/u-boot/configs/rpi_3_defconfig
	echo "#### build ####"
	$(MAKE) -C ./optee/build

fit: boot-files gen-keys
	echo "#### create fit file ####"
	# Sign the u-boot FDT
	./config-its-u-boot.sh
	./optee/u-boot/tools/mkimage -f image.its -K bcm2837-rpi-3-b-plus-u-boot.dtb -k keys -r image.fit
	rm -f image.fit image.its
	# Sign the linux DTB
	./config-its-linux.sh
	./optee/u-boot/tools/mkimage -f image.its -K bcm2710-rpi-3-b-plus-linux.dtb -k keys -r image.fit

rebuild-uboot:
	echo "#### rebuild ####"
	$(MAKE) -C ./optee/build clean
	rm -f optee/out/rpi3-sdcard.img
	# TODO: get `CONFIG_OF_SEPERATE` working; likely stuck on a conflict with TF-A
	# Rebuild u-boot specifying the signed DTB
	$(MAKE) -C ./optee/build EXT_DTB=$(ROOT_DIR)/bcm2837-rpi-3-b-plus-u-boot.dtb	

########## KEYS #######################
# TODO: this should be able to generate a selection of keys
gen-keys: keys keys/dev.key keys/dev.crt

keys:
	mkdir keys

keys/dev.key:
	openssl genrsa -out keys/dev.key 2048
	
keys/dev.crt:
	openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt

########## SET UP BOOT FILES ##########

# U-Boot and Linux require different DTBs:
# 	- U-Boot's must be signed
# 	- Linux's must be used when generating the signed FIT image
boot-files: clean-boot
	echo "#### setting up fit files ####"
	cp optee/linux/arch/arm64/boot/Image Image
	cp optee/trusted-firmware-a/build/rpi3/debug/armstub8.bin kernel8.img

	# Copy the required DTBs for mkimage
	cp optee/u-boot/arch/arm/dts/bcm2837-rpi-3-b-plus.dtb bcm2837-rpi-3-b-plus-u-boot.dtb
	cp optee/linux/arch/arm64/boot/dts/broadcom/bcm2710-rpi-3-b-plus.dtb bcm2710-rpi-3-b-plus-linux.dtb

	# Add a KASLR seed to the u-boot FDT
	rm -f tmp.dts
	/bin/dtc -I dtb -O dts -o tmp.dts bcm2837-rpi-3-b-plus-u-boot.dtb
	./kaslrGenerator.sh
	/bin/dtc -I dts -O dtb -o bcm2837-rpi-3-b-plus.dtb tmp.dts

	# Add a KASLR seed to the linux DTB
	rm -f tmp.dts
	/bin/dtc -I dtb -O dts -o tmp.dts bcm2710-rpi-3-b-plus-linux.dtb
	./kaslrGenerator.sh
	/bin/dtc -I dts -O dtb -o bcm2710-rpi-3-b-plus-linux.dtb tmp.dts

########## CLEAN ######################

clean: clean-boot
	$(MAKE) -C ./optee/build clean -j `nproc`
	cp -f Makefile-optee.bck optee/build/Makefile

clean-boot:
	rm -f Image armstub8.bin kernel8.img bcm2837-rpi-3-b-plus.dtb bcm2710-rpi-3-b-plus.dtb image.fit image.its bcm2710-rpi-3-b-plus-linux.dtb bcm2837-rpi-3-b-plus-u-boot.dtb tmp.dts Makefile-optee.bck

remove: clean-boot
	sudo rm -rf optee

.PHONY: all init cortex-a53-15330924 build fit rebuild-u-boot gen-keys boot-files clean clean-boot remove update-dtbs update-u-boot-order tools

