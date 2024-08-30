## Components
- DHCP using `isc-dhcp-server`
- TFTP using `tftpd-hpa`
- NFS using ```nfs-kernel-server```

## DHCP
Dynamic host configuration protocol is used by a server on a network to provide IP address to devices which try to connect to the network. This allows discovery of new devices on the network without the need for modifying static configuration.

## TFTP
Trivial file transfer protocol is a striped down version of FTP (file transfer protocol) used in boot loader due to its small binary size to provide network boot functionality. This will be used to load the kernel and related files, before the OS can be started which will have full network capabilities.

## NFS
Network file system is used for supplying the Raspberry Pi with a root file system over the network. NFS is fully featured for Unix file permissions, making it both very powerful for this purpose, but also more difficult to set up.