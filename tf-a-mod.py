from pathlib import Path

content = Path("optee/trusted-firmware-a/plat/rpi/rpi3/rpi3_bl31_setup.c").read_text()

content = content.replace(
    "#endif /* RPI3_DIRECT_LINUX_BOOT */\n}",
    "#endif /* RPI3_DIRECT_LINUX_BOOT */\n\tVERBOSE(\"rpi3: Set x0 to DTB base\\n\");\n\tbl33_image_ep_info.args.arg0 = (u_register_t) RPI3_PRELOADED_DTB_BASE;\n}"
)

with open("optee/trusted-firmware-a/plat/rpi/rpi3/rpi3_bl31_setup.c", 'w') as f:
    f.write(content)
