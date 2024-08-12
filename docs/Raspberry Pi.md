### Pros
Raspberry Pi was picked as the target for this project as a means of inexpensive prototyping and proof of concept before requiring investment in more expensive development boards. The Raspberry Pi also benefits from a large and active community with a vested interest in exploring a wide range of topics for education, rather than a view directly to production.
Through this, a wide range of hardware for experimenting with a broad array of potential application for secure booted TEE's can be cheaply acquired, without the need to develop custom boards to mount sensors or other hardware. Community drivers can then also be used, removing another stage of development that would otherwise be required for each area of interest.

### Cons
That said, the Raspberry Pi family currently has a critical deficiency that make them unsuitable for secure deployment: a lack of secure RAM, preventing true isolation of the TEE.
All other problems with this solution currently stem from software compatibility issues with cryptography standards, and component interoperability, chief among which is support for quantum safe algorithms, or even full stack support for ECDSA.

## Board specifics
Each board is assigned a [board identifier](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-revision-codes)

### 3 B+
- SoC: boardcom 2837/B0
- CPU: A53

### 4 B
- SoC: broadcom 2711
- CPU: A72
- Has EEPROM for first stage boot loader

### 5
- SoC: boardcom 2712
- CPU: A76
- Has EEPROM for first stage boot loader
