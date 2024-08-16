import sys

data = []

for line in sys.stdin:
    data.append(line.replace('\n', ''))

hash_count = 0
sig_count = 0
val_count = 0

for part in data:
    if "hash" in part:
        hash_count += 1
    if "signature" in part:
        sig_count += 1
    if "value" in part:
        val_count += 1

if hash_count < 2:
    sys.exit("Found less than two hashes: the FIT file is likely not signed")
else:
    print("Found " + str(hash_count) + " hash nodes in the FIT file ✓")

if sig_count < 1:
    sys.exit("Could not find a signature in the FIT file: may not be named 'signature'?")
else:
    print("Found " + str(sig_count) + " signature nodes in the FIT file ✓")

if hash_count + sig_count != val_count:
    sys.exit("Number of hash + signature values does not match the number of hash and signature nodes: " + str(hash_count) + " + " + str(sig_count) + " = " + str(val_count))
else:
    print("Found a matching number of value nodes to signature and hash nodes: " + str(hash_count) + " + " + str(sig_count) + " = " + str(val_count) + " ✓")
