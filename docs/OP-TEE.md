
```
+----------------+
| Secure Monitor |
+--------+-------+
| OP-TEE | Linux |
+--------+-------+
```

OP-TEE consists of two main parts: a secure OS, a TEE, for running secure code; and a set of drivers, OP-TEE client, to allow the client OS to communicate with OP-TEE OS. Both ends of this communication channel through the secure monitor running in EL3 (exception level 3) are terminated with a copy of openssl to maintain the security of data and instructions passed from one end to the other. Both the client OS and OP-TEE OS run in EL1, though the user code running of the client OS will be running in EL0, so will need to use interrupts to access the driver level communication channel.

This EL level separation is key to the security of OP-TEE, taking advantage of CPU architecture to maintain container validity, rather than verifying them via hardware level interfaces hidden in the silicon; by taking advantage of a known good TEE, it is allowed to become the root of trust for any application running in the guest OS.

### ARM Exception Levels

- EL0: Application
- EL1: Rich OS
- EL2: Hypervisor
- EL3: Firmware / Secure Monitor

These different exception levels correspond to different levels of access to certain parts of memory or secure registers, with any attempt to access a secure area being raised to the relevant system.

