Verified boot is the checking of the OS image against a signature in the boot loader; this means that the boot loader is the root of trust. Trusted boot would require that the signature of the boot loader be placed in OTP (one time programmable) memory to prevent modification of boot loader, placing the root of trust in hardware.

Not verifying that the boot loader has not been modified means that this implementation is **<span style="color: red">NOT SECURE</span>** in its current state, but can be used as a development platform for other devices, as it should be mostly board agnostic via board DTBs (device tree binaries) and configuration targets. It is also important to note that none of the current Raspberry Pi's (up to, and including the Pi 5) do not have SRAM (secure random access memory), which is required for a TEE (trusted execution environment) to be considered secure.

Measured boot takes advantage of hardware TPM (trusted platform module) to validate the boot loader and OS using keys stored internally to the TPM.

### Raspberry Pi's Secure Boot
Raspberry Pi themselves have provided [documentation](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://pip.raspberrypi.com/categories/685-whitepapers-app-notes/documents/RP-003466-WP/Boot-Security-Howto.pdf&ved=2ahUKEwiR8d6ayeCHAxWqSkEAHc7JOVEQFnoECBwQAQ&usg=AOvVaw350nb7iXQOS6sAEXvvgo9T) of enabling secure boot on the Pi 4 and the Pi 5, along with a [GitHub repo](https://github.com/raspberrypi/usbboot?tab=readme-ov-file#secure-boot) with instructions on how to achieve secure boot. This implementation currently has *NO* cryptographic algorithm agility, supporting only a default of RSA-2048, which is soon to be considered insecure.
This implementation places the key modulus in OTP, allowing recovery of a key to check that the OS image and boot loader are correctly signed, but relies on the key having a modulus to place in OTP. The alternatives would be to store the entire key in OTP, or to check the key against a hash stored in OTP.
It also requires firmware support for reading the OTP at boot, leaving support for older versions of the Pi unlikely at best, implicating the use of EEPROM to prevent anything but physical access from modifying the boot loader.

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