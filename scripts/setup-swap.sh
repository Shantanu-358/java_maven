#!/bin/bash
# ==============================================================================
# Setup Swap Space for AWS Free Tier (t2.micro / t3.micro - 1GB RAM)
# Prevents Maven builds and Jenkins from being killed by Linux OOM (Out Of Memory)
# Run as sudo: sudo bash setup-swap.sh
# ==============================================================================

set -e

SWAP_SIZE="2G"
SWAP_FILE="/swapfile"

echo "==> Checking existing swap space..."
if [ $(swapon --show | wc -l) -gt 0 ]; then
    echo "Swap space already exists:"
    swapon --show
    free -h
    exit 0
fi

echo "==> Creating ${SWAP_SIZE} swap file at ${SWAP_FILE}..."
fallocate -l ${SWAP_SIZE} ${SWAP_FILE} || dd if=/dev/zero of=${SWAP_FILE} bs=1M count=2048

chmod 600 ${SWAP_FILE}
mkswap ${SWAP_FILE}
swapon ${SWAP_FILE}

echo "==> Making swap persistent across reboots in /etc/fstab..."
if ! grep -q "${SWAP_FILE}" /etc/fstab; then
    echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
fi

# Set swappiness to 10 (prefers RAM, uses swap only when memory pressure occurs)
sysctl vm.swappiness=10
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" >> /etc/sysctl.conf
fi

echo "==> Swap setup complete! Current memory status:"
free -h
