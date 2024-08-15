import sys

data = []

for line in sys.stdin:
    data.append(line.replace('\n', ''))

for part in data:
    if "signature" in part:
        print("Found public key in DTB ✓")
        sys.exit()

sys.exit("Cound't find public key in DTB")
