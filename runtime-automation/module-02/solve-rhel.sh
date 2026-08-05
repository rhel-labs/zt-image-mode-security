#!/bin/sh
echo "Building and deploying security VM..." >> /tmp/progress.log

cd ~/bootc-base
podman build --file Containerfile --tag registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log
podman push registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log

cd ~
podman run --rm --privileged --security-opt label=type:unconfined_t \
  --volume ./config.toml:/config.toml \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  --volume .:/output \
  registry.redhat.io/rhel10/bootc-image-builder:10.1 \
  --type qcow2 \
  registry-${GUID}.${DOMAIN}/base 2>&1 >> /tmp/progress.log

cp -f qcow2/disk.qcow2 /var/lib/libvirt/images/security-vm.qcow2

virt-install --name security-vm \
  --disk /var/lib/libvirt/images/security-vm.qcow2 \
  --import --memory 4096 --graphics none \
  --osinfo rhel10-unknown --noautoconsole --noreboot 2>&1 >> /tmp/progress.log

virsh start security-vm 2>&1 >> /tmp/progress.log

echo "Security VM deployed" >> /tmp/progress.log
