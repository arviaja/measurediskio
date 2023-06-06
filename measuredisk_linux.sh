#!/bin/bash

min_size=$((100*1024**3))
min_free=$((5*1024**3))
test_file="test_io"
numjobs=16

# Probe for devices with at least 100 GB capacity
devices=$(lsblk -d -o NAME,TYPE -n | awk '$2 == "disk" {print $1}')

# Create and navigate to the testing directory
mkdir -p ~/disk_testing
cd ~/disk_testing

# Loop through each device
for device in $devices; do
    echo "Testing device /dev/${device}..."

    # Check if device is large enough
    device_size=$(blockdev --getsize64 "/dev/${device}")
    
    if [ -z "$device_size" ]; then
        echo "Skipping /dev/${device} - Could not determine size"
        continue
    fi

    if [ $device_size -ge $min_size ]; then
        # Get mountpoints
        mountpoints=$(lsblk -n -o MOUNTPOINT "/dev/${device}")
        total_free_space=0

        # Calculate total free space across all mount points
        for mountpoint in $mountpoints; do
            if [ -n "$mountpoint" ]; then
                free_space=$(df --output=avail "$mountpoint" | tail -n 1)
                total_free_space=$(($total_free_space + $free_space*1024))
            fi
        done

        if [ $total_free_space -ge $min_free ]; then
          echo "/dev/${device} has enough space, conducting tests..."

          # Perform testing here

          # Measuring IOPS
          fio --randrepeat=1 --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=/dev/$device --bs=4k --iodepth=64 --size=1G --readwrite=randrw --rwmixread=75 --numjobs=$numjobs

          # Measuring Throughput
          fio --randrepeat=1 --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=/dev/$device --bs=64k --iodepth=64 --size=1G --readwrite=randrw --rwmixread=75 --numjobs=$numjobs

          # Measuring Latency
          fio --randrepeat=1 --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=/dev/$device --bs=4k --iodepth=1 --size=1G --readwrite=randrw --rwmixread=75 --numjobs=$numjobs

        else
            echo "/dev/${device} does not have enough free space"
        fi
    else
        echo "/dev/${device} is too small"
    fi
done