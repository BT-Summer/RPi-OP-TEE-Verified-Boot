# Verified Boot for RPi

## Description
A TEE solution for Raspberry Pi using OP-TEE, built on TF-A, U-Boot, and buildroot.
This is our implementation to get a version of this working, and is *not* supported by the above projects.

## Usage

The only prior dependency, while building on an Ubuntu 22.04 system, should be `make` which can be installed via `sudo apt install make`, though it is recommended to build on a VM or container to remove external factors

```bash
git clone https://github.com/BT-Summer/RPi-OP-TEE-Verified-Boot.git
cd https://github.com/BT-Summer/RPi-OP-TEE-Verified-Boot.git
make
```

This should generate a file in `optee/out` called `rpi3-sccard.img` which can be simply flashed to an SD card using your favorite image flasher, then booted on a Raspberry Pi.

## Demo
TODO: will be added as we move toward an upcoming presentation

## Support
This is *not* an official OP-TEE, U-Boot, or TF-A project; any updates should be pushed through the Issues tab in this repo.

## Contributing
We are purely interested only in updates for running these scripts on Ubuntu 22.04; feel free to fork if you wish to get this working on another distro.

## Authors and acknowledgment
Based on [OP-TEE](https://github.com/OP-TEE), [U-Boot](https://github.com/u-boot), and [TF-A](https://github.com/ARM-software/arm-trusted-firmware).

Developed by [Eden Hamilton](https://github.com/EdenH1234) and [Thomas Gymer](https://github.com/TommyGymer)

## License
Distributed under the BSD 3-Clause License

## Project status
We are currently only maintaining this project, though may pick it up again as part of university projects.
