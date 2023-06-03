#!/bin/bash

# Detect if this script is executed on Linux or MacOS. Set the OS variable accordingly
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        OS="linux"
        disk="/dev/sda"
        echo "Linux OS detected"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        disk="disk0"
        echo "MacOS detected"
else
        echo "This script only works on Linux or MacOS"
        exit 1
fi

# Check if run with root privileges. Exit if not run as root and show how to run as root or sudo

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo"
  exit 1
fi

# Check if fio is installed or not. Exit if not installed

if ! [ -x "$(command -v fio)" ]; then
  echo 'Error: fio is not installed.' >&2
  # Propose how to install on Linux and MacOS
    if [ "$OS" == "linux" ]; then
            echo "Install fio on Linux using the following command:"
            echo "sudo apt-get install fio"
    elif [ "$OS" == "macos" ]; then
            echo "Install fio on MacOS using the following command:"
            echo "brew install fio"
    else
            echo "This script only works on Linux or MacOS"
            exit 1
    fi
  exit 1
fi

# Check if iostat is installed or not. Exit if not installed

if ! [ -x "$(command -v iostat)" ]; then
  echo 'Error: iostat is not installed.' >&2
    # Propose how to install on Linux and MacOS
        if [ "$OS" == "linux" ]; then
                echo "Install iostat on Linux using the following command:"
                echo "sudo apt-get install sysstat"
        elif [ "$OS" == "macos" ]; then
                echo "Install iostat on MacOS using the following command:"
                echo "brew install iostat"
        else
                echo "This script only works on Linux or MacOS"
                exit 1
        fi
  exit 1
fi

# Check if dd is installed or not. Exit if not installed

if ! [ -x "$(command -v dd)" ]; then
  echo 'Error: dd is not installed.' >&2
  # Propose how to install on Linux and MacOS
        if [ "$OS" == "linux" ]; then
                echo "Install dd on Linux using the following command:"
                echo "sudo apt-get install coreutils"
        elif [ "$OS" == "macos" ]; then
                echo "Install dd on MacOS using the following command:"
                echo "brew install coreutils"
        else
                echo "This script only works on Linux or MacOS"
                exit 1
        fi
  exit 1
fi

# Check if tee is installed or not. Exit if not installed

if ! [ -x "$(command -v tee)" ]; then
  echo 'Error: tee is not installed.' >&2
    # Propose how to install on Linux and MacOS
            if [ "$OS" == "linux" ]; then
                    echo "Install tee on Linux using the following command:"
                    echo "sudo apt-get install coreutils"
            elif [ "$OS" == "macos" ]; then
                    echo "Install tee on MacOS using the following command:"
                    echo "brew install coreutils"
            else
                    echo "This script only works on Linux or MacOS"
                    exit 1
            fi
  exit 1
fi

# Main Program
# ------------

# Test 1: Sequential Write Speed.
# Measures how quickly large files can be read from or written to the disk in a continuous, sequential manner.

# display hostname:

echo "Hostname: $(hostname)"
echo "Date and Time: $(date)"
echo "Testing disk: $(disk)"
echo "------------------------------------"
echo ""


if [ "$OS" == "linux" ]; then
        echo "Testing Sequential Write Speed..."
        dd if=/dev/zero of=/tmp/test1.img bs=1G count=1 oflag=dsync
        echo ""
elif [ "$OS" == "macos" ]; then
        echo "Testing Sequential Write Speed..."
        dd if=/dev/zero of=/tmp/test1.img bs=1G count=1
        echo ""
else
        echo "This script only works on Linux or MacOS"
        exit 1
fi

# Drop caches to ensure accurate results and reading from disk, not from cache.

if [ "$OS" == "linux" ]; then
        echo "Dropping Caches..."
        sync; echo 3 | tee /proc/sys/vm/drop_caches
        echo ""
elif [ "$OS" == "macos" ]; then
        echo "Dropping Caches..."
        sudo purge
        echo ""
else
        echo "This script only works on Linux or MacOS"
        exit 1
fi

# Sequential Read Speed.

if [ "$OS" == "linux" ]; then
        echo "Testing Sequential Read Speed..."
        dd if=/tmp/test1.img of=/dev/null bs=1G count=1
        echo ""
elif [ "$OS" == "macos" ]; then
        echo "Testing Sequential Read Speed..."
        dd if=/tmp/test1.img of=/dev/null bs=1G count=1
        echo ""
else
        echo "This script only works on Linux or MacOS"
        exit 1
fi

# Test 2: Random Write Speed.
# Measures how quickly small files can be written to the disk in random locations.

if [ "$OS" == "linux" ]; then
    echo "Testing Random Write Speed..."
    fio --name=randwrite --ioengine=libaio --iodepth=1 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=1 --runtime=240 --group_reporting
    echo ""
elif [ "$OS" == "macos" ]; then
    echo "Testing Random Write Speed..."
    fio --name=mytest --filename=/tmp/testfile --size=1G --ioengine=posixaio --rw=write
    echo ""
else
    echo "This script only works on Linux or MacOS"
    exit 1
fi  

# Test 3: Random Read Speed. Using appropriate command for operating system

if [ "$OS" == "linux" ]; then
        echo "Testing Random Read Speed..."
        fio --name=randread --ioengine=libaio --iodepth=1 --rw=randread --bs=4k --direct=1 --size=1G --numjobs=1 --runtime=240 --group_reporting
        echo ""
elif [ "$OS" == "macos" ]; then
        echo "Testing Random Read Speed..."
        fio --name=mytest --filename=/tmp/testfile --size=1G --ioengine=posixaio --rw=read
        echo ""
else
        echo "This script only works on Linux or MacOS"
        exit 1
fi

# Test 4: Measure Average Latency and Disk Queue length with iostat. Using appropriate command for operating system

if [ "$OS" == "linux" ]; then
        echo "Testing Average Latency and Disk Queue length..."
        iostat -dx $disk 1 10
        echo ""
elif [ "$OS" == "macos" ]; then
        echo "Testing Average Latency. Disk Queue length not available on MacOS..."
        iostat -d $disk 1 10
        echo ""
else
        echo "This script only works on Linux or MacOS"
        exit 1
fi

echo "End of Test"
echo "-----------"