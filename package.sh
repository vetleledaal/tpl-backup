#!/usr/bin/env bash
set -euo pipefail

zlib_deflate() {
  # openssl zlib # Not bit-for-bit compatible, not always available
  python3 -c "import sys, zlib; sys.stdout.buffer.write(zlib.compress(sys.stdin.buffer.read()))"
}

source .encryption_params

cd data

data_mtime=$(stat -c%Y .)
mtime=$(stat -c%Y ori-backup-user-config.bin)
cat ori-backup-user-config.bin.decrypted.xml | \
  zlib_deflate | \
  openssl enc -aes-256-cbc -e -K "$KEY" -iv "$IV" -out ori-backup-user-config.bin
touch -d @"$mtime" ori-backup-user-config.bin

cd ori-backup-certificate.bin.decrypted/
mtime=$(stat -c%Y ../ori-backup-certificate.bin)
mode=$(stat -c%a ../ori-backup-certificate.bin)
tar -cf - -b1 --owner=root --group=root * | \
  zlib_deflate | \
  openssl enc -aes-256-cbc -e -K "$KEY" -iv "$IV" -out ../ori-backup-certificate.bin
touch -d @"$mtime" ../ori-backup-certificate.bin
chmod "$mode" ../ori-backup-certificate.bin
cd ..
touch -d @"$data_mtime" .

tar -cf - -b1 --owner=root --group=root --exclude 'magic_prefix.bin' --exclude '*.decrypted*' . | \
  tee >(cat > ../data.r1.bin) | \
  cat magic_prefix.bin - | \
  tee >(cat > ../data.r2.bin) | \
  zlib_deflate | \
  tee >(cat > ../data.r3.bin) | \
  # TODO: fix broken final output
  openssl enc -aes-256-cbc -e -K "$KEY" -iv "$IV" -out ../backup_final.bin
