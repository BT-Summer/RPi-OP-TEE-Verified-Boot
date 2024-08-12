#!/bin/bash

# Generate two u32 numbers
SEEDVAL1=`openssl rand -hex 4`
SEEDVAL2=`openssl rand -hex 4`

# Add these into KASLR seed to form u64 seed
KASL_ARG="		kaslr-seed = <0x$SEEDVAL1 0x$SEEDVAL2>;" # 2 indents to match .dts file later

# Check if any line contains the "kaslr-seed"
if grep -q 'kaslr-seed' tmp.dts; then
    echo "Line with 'kaslr-seed' found. Replacing with new seed."
    sed -i '/kaslr-seed/c\'"$KASL_ARG" tmp.dts
    echo "KASLR seed replaced in .dts."
    exit 0;
fi

echo "No line starting with 'kaslr-seed' found. Creating new one."

# Add the new seed into the dts
sed "/^\s*chosen\s*{/a\    $KASL_ARG" tmp.dts > temp.dts && mv temp.dts tmp.dts

echo "Added KASLR seed into .dts"
