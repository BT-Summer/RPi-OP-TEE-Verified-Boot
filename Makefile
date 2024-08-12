ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: init cortex-a53-1530924 update-u-boot-env update-image-build preloaded-dtb modify-tf-a build fit build-uboot custom_armstub image

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
	# Create FIT file place holder
	touch image.fit

# Sets TF-A's debug level to full
tf-a-debug-50:
	echo "#### set tf-a log level to 50 ####"
	sed -i -e 's/\tLOG_LEVEL=40 \\/\tLOG_LEVEL=50 \\/' optee/build/Makefile
	sed -i -e 's|printf("%sVA:0x%lx PA:0x%llx size:0x%zx ",|printf("%sVA:0x%lx PA:0x%lx size:0x%zx ",|' optee/trusted-firmware-a/lib/xlat_tables_v2/xlat_tables_utils.c

# Set the preloaded DTB config to the address in config.txt which the SoC will use
preloaded-dtb:
	echo "#### set the address of the preloaded dtb ####"
	sed -i -e 's/\tRPI3_PRELOADED_DTB_BASE=0x00010000 \\/\tRPI3_PRELOADED_DTB_BASE=0x01000000 \\/' optee/build/Makefile

# Clone and build v2024.07 of u-boot
build-uboot:
	echo "#### u-boot v2024.07 ####"
	rm -rf u-boot
	git clone git://git.denx.de/u-boot.git
	cd u-boot && git checkout v2024.07
	# TODO: Modify the defconfig rather than replace the .config file
	$(MAKE) -C ./u-boot rpi_3_b_plus_defconfig
	rm -f u-boot/.config
	cp u-boot.config u-boot/.config
	$(MAKE) CROSS_COMPILE=aarch64-linux-gnu- -C ./u-boot

# Update a .c file in TF-A to set the register u-boot requires for CONFIG_OF_PRIOR_STAGE 
modify-tf-a:
	python3 tf-a-mod.py

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
	rm -f image.fit
	# Sign the u-boot FDT
	./config-its-u-boot.sh
	./optee/u-boot/tools/mkimage -f image.its -K bcm2837-rpi-3-b-plus-u-boot.dtb -k keys -r image.fit
	rm -f image.fit image.its
	# Sign the linux DTB
	./config-its-linux.sh
	./optee/u-boot/tools/mkimage -f image.its -K bcm2710-rpi-3-b-plus-linux.dtb -k keys -r image.fit

# For use with CONFIG_OF_EMBED
rebuild-uboot:
	echo "#### rebuild ####"
	$(MAKE) -C ./optee/build clean
	rm -f optee/out/rpi3-sdcard.img
	# Rebuild u-boot specifying the signed DTB
	$(MAKE) -C ./optee/build EXT_DTB=~/Downloads/custom-fit/bcm2710-rpi-3-b-plus.dtb	

# For use with CONFIG_OF_PRIOR_STAGE
image:
	echo "#### construct sd card image ####"
	rm -f optee/out/rpi3-sdcard.img

	rm -f optee/out/boot/armstub8.bin
	cp -f armstub/armstub8.bin optee/out/boot/armstub8.bin
	sudo chmod 755 optee/out/boot/armstub8.bin

	rm -f optee/out/boot/image.fit
	cp -f image.fit optee/out/boot/image.fit
	sudo chmod 755 optee/out/boot/image.fit

	./optee/build/rpi3/scripts/create-image.sh -w optee

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
	# /bin/dtc -I dts -O dtb -o optee/u-boot/arch/arm/dts/bcm2837-rpi-3-b-plus.dtb optee/u-boot/arch/arm/dts/bcm2837-rpi-3-b-plus.dts
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
	# cp -f Makefile-optee.bck optee/build/Makefile

clean-boot:
	rm -f Image armstub8.bin kernel8.img bcm2837-rpi-3-b-plus.dtb bcm2710-rpi-3-b-plus.dtb image.fit image.its bcm2710-rpi-3-b-plus-linux.dtb bcm2837-rpi-3-b-plus-u-boot.dtb tmp.dts Makefile-optee.bck

remove: clean-boot
	sudo rm -rf optee

########## CUSTOM ARMSTUB8 ############

custom_armstub: armstub/clean armstub armstub/armstub8.bin

armstub:
	mkdir -p armstub

armstub/armstub8.bin: armstub armstub/just_armstub.bin armstub/new_fip.bin
	cd armstub && cat just_armstub.bin new_fip.bin > armstub8.bin

armstub/u-boot.bin:
	# cp -f optee/u-boot/u-boot-nodtb.bin armstub/u-boot-nodtb.bin
	# cd armstub && cat u-boot-nodtb.bin bcm2710-rpi-3-b-plus.dtb > u-boot.bin
	cp -f u-boot/u-boot-nodtb.bin armstub/u-boot-nodtb.bin
	cp -f armstub/u-boot-nodtb.bin armstub/u-boot.bin

armstub/src_armstub8.bin:
	cp optee/trusted-firmware-a/build/rpi3/debug/armstub8.bin armstub/src_armstub8.bin

armstub/fip.bin: armstub armstub/src_armstub8.bin
	cd armstub && cat src_armstub8.bin | tail -c +131073 > fip.bin

armstub/just_armstub.bin: armstub armstub/src_armstub8.bin
	cd armstub && cat src_armstub8.bin | head -c 131072 > just_armstub.bin

armstub/tos-fw.bin: armstub/fip.bin
	cd armstub && ../optee/trusted-firmware-a/tools/fiptool/fiptool unpack fip.bin
	cd armstub && ../optee/trusted-firmware-a/tools/fiptool/fiptool info fip.bin

armstub/new_fip.bin: armstub/u-boot.bin armstub/tos-fw.bin
	cd armstub && ../optee/trusted-firmware-a/tools/fiptool/fiptool create --tb-fw tb-fw.bin --soc-fw soc-fw.bin --tos-fw tos-fw.bin --tos-fw-extra1 tos-fw-extra1.bin --tos-fw-extra2 tos-fw-extra2.bin --nt-fw u-boot.bin new_fip.bin

armstub/clean:
	rm -rf ./armstub

.PHONY: all init cortex-a53-15330924 build fit rebuild-u-boot gen-keys boot-files clean clean-boot remove update-dtbs update-u-boot-order tools armstub/clean custom_armstub

