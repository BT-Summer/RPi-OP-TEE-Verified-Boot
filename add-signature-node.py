import os
import subprocess
import sys

# Define the signature node
signature_node = """
/ {
    signature {

    };
};
"""

def decompile_dtb_to_dts(dtb_path, dts_path):
    try:
        # Decompile DTB to DTS using dtc
        subprocess.run(["dtc", "-I", "dtb", "-O", "dts", dtb_path, "-o", dts_path], check=True)
        print(f"DTS decompiled successfully: {dts_path}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to decompile DTB to DTS: {e}")
        sys.exit(1)

def add_signature_node_to_dts(dts_path, signature_node):
    # Read the original DTS file
    with open(dts_path, 'r') as file:
        dts_content = file.read()
    
    # Add the signature node at the end of the DTS file
    if signature_node.strip() not in dts_content:
        with open(dts_path, 'a') as file:
            file.write(signature_node)
        print("Signature node added.")
    else:
        print("Signature node already exists in the DTS file.")

def compile_dts_to_dtb(dts_path, dtb_path):
    try:
        # Compile DTS back to DTB using dtc
        subprocess.run(["dtc", "-I", "dts", "-O", "dtb", dts_path, "-o", dtb_path], check=True)
        print(f"DTB compiled successfully: {dtb_path}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to compile DTS to DTB: {e}")
        sys.exit(1)

def main(dtb_filename):
    dts_filename = dtb_filename.replace(".dtb", ".dts")

    # Decompile DTB to DTS
    decompile_dtb_to_dts(dtb_filename, dts_filename)
    
    # Add signature node to the DTS file
    add_signature_node_to_dts(dts_filename, signature_node)
    
    # Compile the modified DTS back to DTB
    compile_dts_to_dtb(dts_filename, dtb_filename)
    
    # Clean up the intermediate DTS file
    os.remove(dts_filename)
    print(f"Intermediate DTS file removed: {dts_filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 add-signature-node.py <dtb_file>")
        sys.exit(1)
    else:
        dtb_file = sys.argv[1]
        if not dtb_file.endswith(".dtb"):
            print("Please provide a valid DTB file.")
            sys.exit(1)
        main(dtb_file)

