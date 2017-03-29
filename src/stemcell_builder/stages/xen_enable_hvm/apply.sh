#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

run_in_chroot $chroot "
grub-set-default default
update-grub -y
"

cp -a $assets_dir/grub_conf_template $chroot/tmp
run_in_chroot $chroot "
sed -i 's/#kernel_version#/'"$(eval uname -r)"'/g' /tmp/grub_conf_template
mv /tmp/grub_conf_template /boot/grub/grub.conf
"