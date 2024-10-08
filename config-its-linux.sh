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
		fdt-1 {
			description = "device tree";
			data = /incbin/("bcm2710-rpi-3-b-plus-linux.dtb");
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
			fdt = "fdt-1";
			signature-1 {
				algo = "sha256,rsa3072";
				key-name-hint = "dev";
				sign-images = "fdt", "kernel";
			};
		};
	};
};' > image.its
