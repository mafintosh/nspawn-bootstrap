#!/usr/bin/env bash

set -e

FORCE=false
IMAGE=""
SIZE=${NSPAWN_BOOTSTRAP_IMAGE_SIZE:-4GB}

while [ "$1" != "" ]; do
  case "$1" in
    --force)  FORCE=true; shift ;;
    --size)   SIZE="$2"; shift; shift ;;
    --ubuntu) UBUNTU="$2"; shift; shift ;;
    --debian) DEBIAN="$2"; shift; shift ;;
    --arch)   ARCH=true; shift; ;;
    --help)   shift; ;;
    *)        IMAGE="$1"; shift; ;;
  esac
done

if [ "$IMAGE" == "" ]; then
  echo "Usage: nspawn-bootstrap <container.img> [options]"
  echo
  echo "  --force"
  echo "  --size    <image-size>"
  echo "  --ubuntu  <version>"
  echo "  --debian  <version>"
  echo "  --arch"
  echo
  echo "Examples:"
  echo
  echo "  nspawn-bootstrap --arch --size 4GB"
  echo "  nspawn-bootstrap --ubuntu xenial --size 3GB"
  echo "  nspawn-bootstrap --debian stable"
  echo
  exit 1
fi

SIZE=$(($(echo $SIZE | sed 's|[bB]||' | sed 's|[kK]|* 1024|' | sed 's|[mM]|* 1024 * 1024|' | sed 's|[gG]|* 1024 * 1024 * 1024|')))

required () {
  if [ "$(which $1 2>/dev/null)" == "" ]; then
    echo $1 is required
    exit 1
  fi
}

[ "$ARCH" != "" ] && required pacstrap
[ "$UBUNTU" != "" ] && required debootstrap
[ "$DEBIAN" != "" ] && required debootstrap

if $FORCE; then
  rm -f "$IMAGE"
fi

if [ -f "$IMAGE" ]; then
  echo $IMAGE already exists
  exit 1
fi

echo Allocating image ...
fallocate -l "$SIZE" "$IMAGE"

echo Writing partition table ...
printf 'n\n\n\n2048\n\na\nw\n' | fdisk "$IMAGE" -u >/dev/null

echo Formatting to ext4 ...
DEV=$(sudo losetup -f --show "$IMAGE" --offset=$((2048 * 512)))
MNT="$IMAGE.mnt"

sudo mkfs.ext4 "$DEV" -q >/dev/null

build () {
  mkdir -p "$MNT"
  sudo mount "$DEV" "$MNT"
  "$@" || ERR=$?
  sudo umount "$MNT"
  rmdir "$MNT"
  sudo losetup -d "$DEV"
  [ "$ERR" != "" ] && rm -f "$IMAGE" && exit $ERR
  true
}

if [ "$ARCH" != "" ]; then
  echo Installing Arch ...
  build sudo pacstrap "$MNT" base
elif [ "$UBUNTU" != "" ]; then
  echo Installing Ubuntu ...
  build sudo debootstrap "$UBUNTU" "$MNT" http://archive.ubuntu.com/ubuntu/
elif [ "$DEBIAN" != "" ]; then
  echo Installing Debian ...
  build sudo debootstrap "$DEBIAN" "$MNT" http://deb.debian.org/debian/
else
  sudo losetup -d "$DEV"
  echo Done. Mount the first partition and install your OS.
fi


