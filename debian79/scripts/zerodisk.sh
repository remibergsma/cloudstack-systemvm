#!/bin/bash

echo "Info: Zero out the free space to save space"
dd if=/dev/zero of=/EMPTY bs=1M
sync
rm -f /EMPTY
sync
