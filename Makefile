ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: all
all: init cortex-a53-1530924 update-u-boot-env preloaded-dtb modify-tf-a build build-uboot fit custom_armstub image

########## BUILD TOOLS ###############

.PHONY: tools
tools: corruptor/target/release/corruptor

corruptor/target/release/corruptor:
	cd corruptor && cargo build --release
	echo "binary file corruptor is at $(ROOT_DIR)/corruptor/target/release/corruptor"

########## FILE SET UP ###############

.PHONY: init
init:
	echo "#### init ####"
	sudo add-apt-repository universe -y
	grep -vE '^#' dependencies-22.04.txt | xargs sudo apt --ignore-missing install -y
	mkdir -p optee
	cd optee && yes y | repo init -u https://github.com/OP-TEE/manifest.git -m rpi3.xml -b 4.3.0
	cd optee && repo sync
	cp optee/build/Makefile Makefile-optee.bck

# Apply fix for cotext a53 errata 1530924 to TF-A's flags
.PHONY: cortex-a53-1530924
cortex-a53-1530924:
	echo "#### cortex fix ####"
	sed -i -e 's/TF_A_FLAGS ?= \\/TF_A_FLAGS ?= ERRATA_A53_1530924=1 \\/' optee/build/Makefile

# Not used
# Replaces all bcm dtb references to the upstream dtbs
.PHONY: update-dtbs-2710
update-dtbs-2710:
	echo "#### update dtbs ####"
	sed -i -e 's/bcm2837-rpi-3-b-plus.dtb/bcm2710-rpi-3-b-plus.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2837-rpi-3-b.dtb/bcm2710-rpi-3-b.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2837-rpi-3-b-plus.dtb/bcm2710-rpi-3-b-plus.dtb/' optee/build/rpi3.mk
	sed -i -e 's/bcm2837-rpi-3-b.dtb/bcm2710-rpi-3-b.dtb/' optee/build/rpi3.mk

# Not used
# Replaces all bcm dtb references to the downstream dtbs
.PHONY: update-dtbs-2837
update-dtbs-2837:
	echo "#### update dtbs ####"
	sed -i -e 's/bcm2710-rpi-3-b-plus.dtb/bcm2837-rpi-3-b-plus.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2710-rpi-3-b.dtb/bcm2837-rpi-3-b.dtb/' optee/build/Makefile
	sed -i -e 's/bcm2710-rpi-3-b-plus.dtb/bcm2837-rpi-3-b-plus.dtb/' optee/build/rpi3.mk
	sed -i -e 's/bcm2710-rpi-3-b.dtb/bcm2837-rpi-3-b.dtb/' optee/build/rpi3.mk

# Replace u-boot.env source with custom env
.PHONY: update-u-boot-env
update-u-boot-env:
	echo "#### update u-boot env ####"
	rm -f ./optee/build/rpi3/firmware/uboot.env.txt
	./config-u-boot-env-netboot.sh

# Not used
# Update which files the optee Makefile will place into the output disk image
.PHONY: update-image-build
update-image-build:
	echo "#### update image builder ####"
	rm -f optee/out/rpi3-sdcard.img
	# Use python for this to avoid conflicts with bash variables
	python3 image-build.py
	# Create FIT file place holder
	touch image.fit
	# Create DTB file place holder
	touch bcm2710-rpi-3-b-plus.dtb
	touch bcm2837-rpi-3-b-plus-u-boot.dtb

# Sets TF-A's debug level to full
.PHONY: tf-a-debug-50
tf-a-debug-50:
	echo "#### set tf-a log level to 50 ####"
	sed -i -e 's/\tLOG_LEVEL=40 \\/\tLOG_LEVEL=50 \\/' optee/build/Makefile
	sed -i -e 's|printf("%sVA:0x%lx PA:0x%llx size:0x%zx ",|printf("%sVA:0x%lx PA:0x%lx size:0x%zx ",|' optee/trusted-firmware-a/lib/xlat_tables_v2/xlat_tables_utils.c

# Set the preloaded DTB config to the address in config.txt which the SoC will use
.PHONY: preloaded-dtb
preloaded-dtb:
	echo "#### set the address of the preloaded dtb ####"
	sed -i -e 's/\tRPI3_PRELOADED_DTB_BASE=0x00010000 \\/\tRPI3_PRELOADED_DTB_BASE=0x01000000 \\/' optee/build/Makefile

# Clone and build v2024.07 of u-boot
.PHONY: build-uboot
build-uboot:
	echo "#### u-boot v2024.07 ####"
	rm -rf u-boot
	git clone git://git.denx.de/u-boot.git
	cd u-boot && git checkout v2024.07
	
	rm -f u-boot/configs/rpi_3_b_plus_defconfig
	cp v2024.07-rpi_3_b_plus_fit_defconfig u-boot/configs/rpi_3_b_plus_defconfig
	$(MAKE) -C ./u-boot rpi_3_b_plus_defconfig
	#rm -f u-boot/.config
	#cp u-boot.config u-boot/.config
	$(MAKE) CROSS_COMPILE=aarch64-linux-gnu- -C ./u-boot -j$(nproc)

# Update a .c file in TF-A to set the register u-boot requires for CONFIG_OF_PRIOR_STAGE 
.PHONY: modify-tf-a
modify-tf-a:
	python3 tf-a-mod.py

########## BUILD #####################

.PHONY: build
build:
	echo "#### build toolchains ####"
	$(MAKE) -C ./optee/build -j3 toolchains
	rm -f optee/u-boot/configs/rpi_3_defconfig
	cp rpi_3_b_plus_fit_defconfig optee/u-boot/configs/rpi_3_defconfig
	echo "#### build ####"
	$(MAKE) -C ./optee/build

.PHONY: fit
fit: boot-files gen-keys
	echo "#### create fit file ####"
	rm -f image.fit
	# Sign the DTB to be used by uboot
	# However, the DTB in the FIT is to be used by the linux kernel
	./config-its-linux.sh
	./u-boot/tools/mkimage -f image.its -K bcm2837-rpi-3-b-plus-u-boot.dtb -k keys -r image.fit
	
# For use with CONFIG_OF_EMBED
.PHONY: rebuild-uboot
rebuild-uboot:
	echo "#### rebuild ####"
	$(MAKE) -C ./optee/build clean
	rm -f optee/out/rpi3-sdcard.img
	# Rebuild u-boot specifying the signed DTB
	$(MAKE) -C ./optee/build EXT_DTB=~/Downloads/custom-fit/bcm2710-rpi-3-b-plus.dtb

# For use with CONFIG_OF_PRIOR_STAGE
.PHONY: image
image:
	echo "#### construct sd card image ####"
	rm -f optee/out/rpi3-sdcard.img

	rm -f optee/out/boot/kernel8.img

	rm -f optee/out/boot/armstub8.bin
	cp -f armstub/armstub8.bin optee/out/boot/armstub8.bin
	sudo chmod 755 optee/out/boot/armstub8.bin

	rm -f optee/out/boot/image.fit
	cp -f image.fit optee/out/boot/image.fit
	sudo chmod 755 optee/out/boot/image.fit

	rm -f optee/out/boot/bcm2710-rpi-3-b-plus.dtb
	cp -f bcm2837-rpi-3-b-plus-u-boot.dtb optee/out/boot/bcm2710-rpi-3-b-plus.dtb
	sudo chmod 755 optee/out/boot/bcm2710-rpi-3-b-plus.dtb

	./optee/build/rpi3/scripts/create-image.sh -w optee

########## KEYS #######################
# TODO: this should be able to generate a selection of keys
.PHONY: gen-keys
gen-keys: keys keys/dev.key keys/dev.crt

keys:
	mkdir keys

keys/dev.key:
	openssl genrsa -out keys/dev.key 3072
	
keys/dev.crt:
	openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt

########## SET UP BOOT FILES ##########

# U-Boot and Linux require different DTBs:
# 	- U-Boot's must be signed
# 	- Linux's must be used when generating the signed FIT image
.PHONY: boot-files
boot-files: clean-boot
	echo "#### setting up fit files ####"
	cp optee/linux/arch/arm64/boot/Image Image
	cp optee/trusted-firmware-a/build/rpi3/debug/armstub8.bin kernel8.img

	# Copy the required DTBs for mkimage
	# /bin/dtc -I dts -O dtb -o optee/u-boot/arch/arm/dts/bcm2837-rpi-3-b-plus.dtb optee/u-boot/arch/arm/dts/bcm2837-rpi-3-b-plus.dts
	cp u-boot/arch/arm/dts/bcm2837-rpi-3-b-plus.dtb bcm2837-rpi-3-b-plus-u-boot.dtb
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

.PHONY: clean
clean: clean-boot
	$(MAKE) -C ./optee/build clean -j `nproc`

.PHONY: clean-boot
clean-boot:
	rm -f Image armstub8.bin kernel8.img bcm2837-rpi-3-b-plus.dtb bcm2710-rpi-3-b-plus.dtb image.fit image.its bcm2710-rpi-3-b-plus-linux.dtb bcm2837-rpi-3-b-plus-u-boot.dtb tmp.dts Makefile-optee.bck

.PHONY: remove
remove: clean-boot
	sudo rm -rf optee

########## CUSTOM ARMSTUB8 ############

.PHONY: custom_armstub
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

.PHONY: armstub/clean
armstub/clean:
	rm -rf ./armstub

########## TESTS ######################

.PHONY: test
test: test-setup test-armstub8 test-fit test-dtb test-key

.PHONY: test-setup
test-setup:
	rm -rf testing
	mkdir -p testing

.PHONY: test-armstub8
test-armstub8:
	mkdir -p testing/armstub
	cp -f optee/out/boot/armstub8.bin testing/armstub/armstub8.bin
	cat testing/armstub/armstub8.bin | tail -c +131073 > testing/armstub/fip.bin
	cat testing/armstub/armstub8.bin | head -c 131072 > testing/armstub/bl1.bin
	optee/trusted-firmware-a/tools/fiptool/fiptool unpack --out testing/armstub testing/armstub/fip.bin
	python3 tests/armstub8-tests.py

.PHONY: test-fit
test-fit:
	mkdir -p testing/fit
	cp -f optee/out/boot/image.fit testing/fit/image.fit
	u-boot/tools/fdtgrep -n "/configurations" -s -p "value" testing/fit/image.fit | python3 tests/fit-tests.py

.PHONY: test-dtb
test-dtb:
	mkdir -p testing/dtb
	cp -f optee/out/boot/bcm2710-rpi-3-b-plus.dtb testing/dtb/bcm2710-rpi-3-b-plus.dtb
	cp -f bcm2837-rpi-3-b-plus-u-boot.dtb testing/dtb/u-boot.dtb
	cp -f bcm2710-rpi-3-b-plus-linux.dtb testing/dtb/linux.dtb
	u-boot/tools/fdtgrep -n "/signature" -s testing/dtb/bcm2710-rpi-3-b-plus.dtb | python3 tests/dtb-tests.py

.PHONY: test-key
test-key:
	mkdir -p testing/key
	cp -f optee/out/boot/bcm2710-rpi-3-b-plus.dtb testing/key/u-boot.dtb
	cp -f optee/out/boot/image.fit testing/key/image.fit
	cp -f keys/*.crt testing/key/
	python3 tests/key-tests.py testing/key/dev.crt testing/key/u-boot.dtb testing/key/image.fit
