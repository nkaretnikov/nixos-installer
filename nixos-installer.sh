set -e

PROG=`basename "$0"`

function usage {
  echo "Usage: $PROG -d DISK -c CONF"
  echo "  -d  disk to use"
  echo "  -c  location of configuration.nix"
}

while getopts "d:c:" OPT; do
  case $OPT in
    d)
      DISK=$OPTARG
      ;;
    c)
      CONF=$OPTARG
      ;;
  esac
done

if [ -z "$DISK" ] || [ -z "$CONF" ]; then
  usage
  exit 1
fi

echo "This script will delete everything on $DISK, type uppercase yes to proceed."
read ANSWER
if [ $ANSWER != "YES" ]; then
  echo "Expected "YES" but got "$ANSWER", exiting."
  exit 1
fi

dd if=/dev/zero of=$DISK iflag=nocache oflag=direct bs=4096

parted --script -a opt $DISK mklabel gpt

parted --script -a opt $DISK mkpart primary 1MiB 3MiB
parted --script -a opt $DISK name 1 grub
parted --script -a opt $DISK set 1 bios_grub on

parted --script -a opt $DISK mkpart primary 3MiB 131MiB
parted --script -a opt $DISK name 2 boot
parted --script -a opt $DISK set 2 boot on

parted --script -a opt $DISK -- mkpart primary 131MiB -1
parted --script -a opt $DISK name 3 rootfs

mkfs.ext3 "${DISK}1"
mkfs.vfat "${DISK}2"
cryptsetup luksFormat -i 5000 "${DISK}3"
cryptsetup luksOpen "${DISK}3" main
pvcreate /dev/mapper/main
vgcreate main /dev/mapper/main
lvcreate -n main --extent=50%FREE main
lvcreate -n home --extent=50%FREE main
mkfs.ext3 /dev/main/main
mkfs.ext3 /dev/main/home

mount /dev/main/main /mnt
mkdir /mnt/home
mount /dev/main/home /mnt/home
mkdir /mnt/boot
mount "${DISK}2" /mnt/boot

nixos-generate-config --root /mnt
cp $CONF /mnt/etc/nixos/configuration.nix
nixos-install
