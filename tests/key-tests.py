import sys
import subprocess
import re
import OpenSSL.crypto

pub_key_file = sys.argv[1]
dtb_file = sys.argv[2]
fit_file = sys.argv[3]

# KEY FILE

pub_key_f = open(pub_key_file, "r")
pub_key_data = pub_key_f.read()
pub_key_f.close()

cert = OpenSSL.crypto.load_certificate(
        OpenSSL.crypto.FILETYPE_PEM,
        pub_key_data
    )
pub_key_len = cert.get_pubkey().bits()

# DTB

res = subprocess.run(["u-boot/tools/fdtgrep", "-n", "/signature", "-s", dtb_file], capture_output=True, encoding="UTF-8")

raw_key_algo = re.search("algo = \"[a-z]+[0-9]+,[a-z]+[0-9]+\"", res.stdout).group()
key_algo = raw_key_algo.split(",")[1].replace("\"", "")
key_algo_len = int(re.search("[0-9]+", key_algo).group())

# TODO: need to check if this would support other algorithms
raw_key_len = re.search("num-bits = <0x[0-9a-f]{8}>;", res.stdout).group()
key_len = int(raw_key_len[12:-2], 16)

if key_len != key_algo_len:
    sys.exit("DTB key length and algorithm do not match")

# FIT FILE

res = subprocess.run(["u-boot/tools/fdtgrep", "-n", "/configurations", "-s", fit_file], capture_output=True, encoding="UTF-8")

raw_sig_algo = re.search("algo = \"[a-z]+[0-9]+,[a-z]+[0-9]+\"", res.stdout).group()
sig_algo = raw_sig_algo.split(",")[1].replace("\"", "")
sig_algo_len = int(re.search("[0-9]+", sig_algo).group())

raw_sig_len = re.search("value = <(0x[0-9a-f]{8}[\s>])+;", res.stdout).group()
sig_len = len(raw_sig_len[9:-2].split(" ")) * 32

if sig_len != sig_algo_len:
    sys.exit("FIT file signature length and signature algorithm do not match")

# CHECKS

if pub_key_len != key_len:
    sys.exit("Public key length did not match DTB key length")

if pub_key_len != sig_len:
    sys.exit("Public key length did not match FIT signature length")

if key_len != sig_len:
    sys.exit("DTB key length did not match FIT signature length")

print("Public key length, DTB key length, and FIT file signature length match ✓")
