### This python script updates the image building in the OP-TEE build Makefile
new_lines = []

with open("optee/build/Makefile", "r") as f:
	for line in f:
		if "@install -v -p --mode=755 $(LINUX_IMAGE) $(BOOT_PARTITION_FILES)/kernel8.img" in line:
			new_lines.append("\t@install -v -p --mode=755 ../../image.fit $(BOOT_PARTITION_FILES)/image.fit\n")
		elif "@install -v -p --mode=755 $(LINUX_DTB_RPI3_BPLUS) $(BOOT_PARTITION_FILES)/bcm2710-rpi-3-b-plus.dtb" in line:
			new_lines.append("\t@install -v -p --mode=755 ../../bcm2837-rpi-3-b-plus-u-boot.dtb $(BOOT_PARTITION_FILES)/bcm2710-rpi-3-b-plus.dtb\n")
		else:
			new_lines.append(line)
	
with open("optee/build/Makefile", "w") as f:
	f.write(''.join(new_lines))
