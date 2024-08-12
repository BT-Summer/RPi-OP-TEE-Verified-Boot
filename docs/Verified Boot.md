
Verified boot is the checking of the OS image against a signature in the boot loader; this means that the boot loader is the root of trust. Trusted boot would require that the signature of the boot loader be placed in OTP (one time programmable) memory to prevent modification of boot loader, placing the root of trust in hardware.

Not verifying that the boot loader has not been modified means that this implementation is **<span style="color: red">NOT SECURE</span>** in its current state, but can be used as a development platform for other devices, as it should be mostly board agnostic via board DTBs (device tree binaries) and configuration targets.

Measured boot takes advantage of hardware TPM (trusted platform module) to validate the boot loader and OS using keys stored internally to the TPM.

## [[U-Boot]]

> See [About U-Boot](https://docs.u-boot.org/en/latest/#)

U-Boot is a second stage boot loader which can load a variety of OS image formats, including FIT (flattened image tree) which supports the inclusion of a signed configuration with hashes for each of the OS components. This lets U-Boot verify at boot that each of the OS components is as expected before booting to them.

## [[TF-A]]

> See [About TF-A](https://trustedfirmware-a.readthedocs.io/en/latest/index.html)

TF-A (trusted firmware for arm) is a first stage boot loader which enables the loading of secure OS's into secure memory and running these in EL3 (the highest privilege level in the arm architecture). This is where OPTEE is run, allowing it to maintain separation from the client OS and ensure its own security.

## [[OP-TEE]]

> See [About OP-Tee](https://optee.readthedocs.io/en/latest/index.html)

OP-TEE (OP trusted execution environment) takes advantage of the built in privilege levels in the CPU to provide separation for secure operations. Interrupts are passed from the client OS through the containing secure monitor layer to OP-TEE wrapped by openssl and processed by the secure code requested before the result is returned.

> [!NOTE]
> The layer under which OP-TEE and the client OS run, while part of OP-TEE, is not a hypervisor as it is only interested in interrupts targeted directly at OP-TEE.

## [[Linux]]

> See [About Linux](https://github.com/torvalds/linux)

Linux is used as the client OS as the full OS stack is available for modification, allowing the kernel changes required for OP-TEE to function, namely the inclusion of the required drivers. While this would be possible on Windows, any changes would need to make it through the [WHQL](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/whql-release-signature) verification process.