#!/usr/bin/env bash
set -euo pipefail

zlib_inflate() {
  # openssl zlib -d
  python3 -c "import sys, zlib; sys.stdout.buffer.write(zlib.decompress(sys.stdin.buffer.read()))"
}

source .encryption_params

ENCRYPTED_BACKUP_FILE=$(realpath "$1")

mkdir -p data/ori-backup-certificate.bin.decrypted/
cd data

openssl enc -aes-256-cbc -d -K "$KEY" -iv "$IV" -in "$ENCRYPTED_BACKUP_FILE" | \
  # tee >(cat > ../data.p1.bin) |
  zlib_inflate | \
  tee >(head -c16 > magic_prefix.bin ; true) | \
  # tee >(cat > ../data.p2.bin) |
  tail -c+17 | \
  # tee >(cat > ../data.p3.bin) |
  tar -xpf - -C .

openssl enc -aes-256-cbc -d -K "$KEY" -iv "$IV" -in ori-backup-user-config.bin | \
  zlib_inflate > \
  ori-backup-user-config.bin.decrypted.xml

openssl enc -aes-256-cbc -d -K "$KEY" -iv "$IV" -in ori-backup-certificate.bin | \
  zlib_inflate | \
  tar -xpf - -C ori-backup-certificate.bin.decrypted
