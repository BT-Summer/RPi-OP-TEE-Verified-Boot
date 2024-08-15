import sys
import os

TESTING_DIR = "testing/armstub/"

files = [
    ("bl1.bin", 1),
    ("nt-fw.bin", 1),
    ("soc-fw.bin", 1),
    ("tb-fw.bin", 1),
    ("tos-fw.bin", 1),
    ("tos-fw-extra1.bin", 1),
    ("tos-fw-extra2.bin", 0),
]

for f in files:
    try:
        len = os.path.getsize(TESTING_DIR + f[0])
        if len < f[1]:
            sys.exit(f[0] + " was empty")
        else:
            print(f[0] + " was at least " + str(f[1]) + " bytes long ✓")
    except Exception as e:
        sys.exit(str(e))

sys.exit()
