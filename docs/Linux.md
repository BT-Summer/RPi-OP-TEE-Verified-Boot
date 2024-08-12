The required Linux image for making a FIT file to boot from will consist namely of the kernel. This is built using [buildroot](https://buildroot.org/docs.html) to include the required drivers from mainline Linux while adding some additional drivers required to interact with OP-TEE.

> [!NOTE]
> Buildroot must have a directory length of no more than 85 characters to prevent exceeding the max arguments environment condition on Ubuntu.

## DTB

Linux maintain the largest collection of DTB files in their [GitHub repository](https://github.com/torvalds/linux/tree/master/arch/arm/boot/dts/broadcom) with one for nearly every 32 and 64 bit board. These DTB are considered the 'upstream' versions, and for Raspberry Pi this means they are named under `bcm2710`, which would be more accurate for the name of the family of processors to which the Raspberry Pi processors belong.

### Linaro

Linaro also maintain [their own fork of Linux](https://github.com/linaro-swg/linux), which contains DTB's they have modified specifically for working with [[TF-A]] and [[OP-TEE]]. The most recent commits to the DTB's here include specification for the use of PSCI, more details of which can be found under [[U-Boot#^psci]].