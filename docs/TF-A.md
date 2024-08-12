The main use of TF-A is in building the binary files responsible for the boot process, including the boot loaders and [[OP-TEE]] binaries.
The boot loaders are mapped as follows:

- BL1: this is a modified version of the Raspberry Pi boot loader for allowing the inclusion of secure payloads
- BL2: this bootstrap sits between the TF-A boot loader and further boot loaders to allow additional CPU cores to be correctly passed around
- BL31: this handles the starting of the secure payload in BL32 ([[OP-TEE]] is our case), and the transition to `normal world` execution in EL1 which will be where [[U-Boot]] will run
- BL32: this is where the secure payload to be run from SRAM is placed, which is [[OP-TEE]] for our use case and also consists of two extra binary files under `BL32_extra_1` and `BL32_extra_2` which pertain to memory paging in [[OP-TEE]]
- BL33: this is the first non-secure boot loader, which will be [[U-Boot]] for this use case

### Boot Order Structure

- VideoCore runs its boot loader from integrated ROM on the SoC
	- TF-A BL1
		- TF-A BL2
			- TF-A BL31
				- OP-TEE BL32
				- OP-TEE BL32 extra 1
				- OP-TEE BL32 extra 2
			- TF-A BL31
				- U-Boot BL33
					- Linux from FIT

## Memory & File layout

On Raspberry Pi 3, the boot loaders are all placed into `armstub8.bin` as the Raspberry Pi's boot loader will load this file and execute this file in EL3 mode. `armstub8.bin` needs to consist of BL1 as the first bytes, followed by some padding, with a [FIP](https://trustedfirmware-a.readthedocs.io/en/latest/design/firmware-design.html#firmware-image-package-fip) (firmware image package) placed from `0x20000` onward which contains the remaining boot loaders.

### FIP

The FIP file is generated using the `fiptool` in TF-A's tools directory, which has a list of command line arguments for specifying which files need to be placed into the FIP file, with it automatically placing these in the necessary offsets.
The reason for these specific offsets is that the Raspberry Pi's boot loader does not understand the FIP format and can only load it in 'as-is' and then allow BL1 to take over, meaning that it will simply load the entire file into memory, maintaining the offsets set in the file.

|Address|Binary Name|File Name|
|---|---|---|
|`0x0`|`bl1.bin`|`armstub8.bin`|
|`0x20000`|`fip.bin`|Container file|
||`bl2.bin`|TF-A bootstrap|
||`bl31.bin`|TF-A bootstrap|
||`bl32.bin`|OP-TEE header|
||`bl32_extra_1.bin`|OP-TEE pager|
||`bl32_extra_2.bin`|OP-TEE pageable|
||`bl33.bin`|U-Boot|

## DTB

TF-A's DTB (device tree binary), a compiled DTS (device tree source) which describes a specific device's hardware layout, is loaded by the video core which is, in this case, the Raspberry Pi's SoC (system on a chip). This DTB will be placed in memory between `0x10000` and `0x20000` and should be available for later boot loaders to use, though it may also be configured to be placed in secure memory.

## Configs

### Crypto

```
encrypt bl31
encrypt b32
create keys
generate cot
```

## Cortex a53 Errata 1530924

This errata addresses an issue in the predictive pipeline that could cause invalid address translations in some edge cases. This can be trivially fixed by applying a patch from TF-A `ERRATA_A53_1530924=1` in the TF-A build flags. The exact details can be found in [this document](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://documentation-service.arm.com/static/5fa29fddb209f547eebd361d%3Ftoken%3D&ved=2ahUKEwiL9JGSscyHAxXwUUEAHRwAEccQFnoECBcQAQ&usg=AOvVaw1kEli5QJ6vb6SwBZPM1kp3).