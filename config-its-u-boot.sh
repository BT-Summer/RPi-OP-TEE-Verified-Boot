echo '/dts-v1/;
/ {
	description = "RPi FIT Image";
	#address-cells = <2>;
	images {
		kernel-1 {
			description = "default kernel";
			data = /incbin/("Image");
			type = "kernel";
			arch = "arm64";
			os = "linux";
			compression = "none";
			load =  <0x12000000>;
			entry = <0x12000000>;
			hash-1 {
				algo = "sha256";
			};
		};
		tee-1 {
			description = "bootloader";
			data = /incbin/("kernel8.img");
			type = "standalone";
			arch = "arm64";
			compression = "none";
			load =  <0x08400000>;
			entry = <0x08400000>;
			hash-1 {
				algo = "sha256";
			};
		};
		fdt-1 {
			description = "device tree";
			data = /incbin/("bcm2837-rpi-3-b-plus-u-boot.dtb");
			type = "flat_dt";
			arch = "arm64";
			compression = "none";
			load = <0x01000000>;
			entry = <0x01000000>;
			hash-1 {
				algo = "sha256";
			};
		};
	};
	configurations {
		default = "config-1";
		config-1 {
			description = "default configuration";
			kernel = "kernel-1";
			loadables = "tee-1";
			fdt = "fdt-1";
			signature-1 {
				algo = "sha256,ecdsa256";
				key-name-hint = "ecc_dev";
				sign-images = "fdt", "kernel", "loadables";
			};
		};
	};
};' > image.its
