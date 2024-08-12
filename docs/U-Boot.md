## DTB

U-Boot's DTB (device tree binary) is referred to as an FDT (flat device tree) and should contain the signature, in the 'chosen' node, required to verify the integrity of the configuration in the FIT file.

There are a number of possible sources from which U-Boot can obtain its DTB: ^dtb-srcs
- `CONFIG_OF_EMBED`: embed the DTB into the U-Boot binary
- `CONFIG_OF_SEPARATE`: append the DTB(s) to the end of the compiled binary
- `CONFIG_OF_BOARD`: use an already loaded DTB
See how this affects the [[Build Process]]

## FIT File

A FIT file consists of a set of modules including kernel, boot loader, and device tree which are named and then can be used in configurations which may then be booted. Each module will have its hash stored to allow verification of correctness, and the configuration will contain these hashes and then be signed.
A FIT file header contains:

```rust
struct FIT_header {
	magic: u32,
	header_crc: u32,
	creation_timestamp: u32,
	image_size: u32,
	data_load_addr: u32,
	entry_point_addr: u32,
	image_crc: u32,
	os: u8,
	cpu_arch: u8,
	image_type: u8,
	compression_type: u8,
	image_name: u8,
}
```

The header magic is `0x27051956` and it, along with the above struct, can be found in `u-boot/include/image.h`. This also specifies an `LZ4F` magic as `0x184d2204` which is likely used for images compressed using the `LZ4` compression algorithm.

Building the necessary FIT file requires that a Linux image, DTB, and boot loader (as specified in the `.its`) are available. This `.its` is then run through `mkimage`, a tool built into U-Boot, to create the FIT file, which has extension `.itb`.

## Configs

### Crypto

`(?)` will denote optional

```
CONFIG_(SPL_?)HASH
CONFIG_ANDROID_AB
CONFIG_ANDROID_BOOT_IMAGE
CONFIG_(SPL_?)OF_LIBFDT
CONFIG_(SPL_?)OF_FIT_SIGNATURE
CONFIG_(SPL_?)FIT
CONFIG_(SPL_?)MULTI_DTB_FIT
CONFIG_(SPL_?)IMAGE_SIGN_INFO
CONFIG_(SPL_?)FIT_SIGNATURE
CONFIG_(SPL_?)FIT_CIPHER
CONFIG_IO_TRACE
```

### CPU

^psci

The BCM2837/B0 CPU on the Raspberry Pi 3 B+ implements the ARMv8 instruction set, which provides support for both [Spin Table](https://patches.linaro.org/project/u-boot/patch/1466167909-15345-2-git-send-email-yamada.masahiro@socionext.com/#343507) and [PSCI (power state coordination interface)](https://developer.arm.com/documentation/den0024/a/Power-Management/Power-State-Coordination-Interface?lang=en), which are both CPU thread containers for managing their execution. U-Boot provides native support for Spin Table, while v2023.07 provides configs for enabling PSCI and v2024.07 claims to provide native support for both. There is little documentation on Spin Table, likely due to its triviality. PSCI has [additional](https://developer.arm.com/documentation/den0022/latest/) documentation on its exact implementation in the ARM architecture.

## Issues

`CONFIG_OF_SEPARATE` not working when used in conjunction with [[TF-A]]; U-Boot is unable to boot, implying that it cannot find a valid DTB to boot with. It would be nice to know both why this is happening, and if we should be seeing any debug as that would make it possible to debug without JTAG.