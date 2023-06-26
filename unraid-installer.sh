#!/usr/bin/env bash

error() {
    echo "[ERROR] $1"
    exit 1
}

command -v mcopy || error "This tool need 'mcopy' executable in path"

UNRAID_DOWNLOAD_URL="https://unraid-dl.sfo2.cdn.digitaloceanspaces.com/stable/unRAIDServer-6.11.5-x86_64.zip"
UNRAID_ARCHIV="/tmp/unRAIDServer-6.11.5-x86_64.zip"
UNRAID_TMP_MOUNTPOINT="/tmp/UNRAID_TMP_MOUNT"

[ "$EUID" -ne 0 ] && error "Please run with sudo"

selection=$(lsblk -P -p -o "RM,TRAN,NAME,SIZE" | grep 'RM="1" TRAN="usb"' | cut -d ' ' -f 3- | fzf --prompt="Select USB Strick > " | cut -d ' ' -f 1)
[ -z "$selection" ] && exit 1
target="${selection:6:-1}"
[ -e "$target" ] || error "Invalid target selected"

wget -c -O $UNRAID_ARCHIV "$UNRAID_DOWNLOAD_URL"
[ -f $UNRAID_ARCHIV ] || error "Downloading unRAID archiv failed"

umount ${target} || true
[ -e "${target}1" ] && umount ${target}1 || true

wipefs --force --quiet --all $target
parted --script $target mklabel msdos
parted --script $target mkpart primary 1MiB 100%
parted --script $target set 1 boot on

mkfs.vfat -F32 ${target}1
fatlabel ${target}1 UNRAID

mkdir -p $UNRAID_TMP_MOUNTPOINT
mount ${target}1 $UNRAID_TMP_MOUNTPOINT
unzip $UNRAID_ARCHIV -d $UNRAID_TMP_MOUNTPOINT

bash $UNRAID_TMP_MOUNTPOINT/make_bootable_linux

umount ${target} || true
umount ${target}1 || true

sync
echo "Installing to ${target} complete"
