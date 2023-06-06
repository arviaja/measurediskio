#!/bin/bash
# Created by Sebastian Varga
# License: Apache 2.0

# Pre-Checks
# ----------

# Detect if this script is executed on Linux or any other OS. If not Linux, exit with error message

if [[ "$OSTYPE" != "linux-gnu" ]]; then
        echo "This script only works on Linux"
        exit 1
fi

# Check if run with root privileges. Exit if not run as root and show how to run as root or sudo

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo"
  exit 1
fi

# Check if fio, iostat and dd are installed or not. Exit if not installed and suggest how to install via apt-get and yum

if ! [ -x "$(command -v fio)" ]; then
  echo 'Error: fio is not installed.' >&2
  echo "Install fio on Linux using the following command:"
  echo "sudo apt-get install fio"
  echo "or"
  echo "sudo yum install fio"
  exit 1
fi

if ! [ -x "$(command -v iostat)" ]; then
  echo 'Error: iostat is not installed.' >&2
  echo "Install iostat on Linux using the following command:"
  echo "sudo apt-get install sysstat"
  echo "or"
  echo "sudo yum install sysstat"
  exit 1
fi

if ! [ -x "$(command -v dd)" ]; then
  echo 'Error: dd is not installed.' >&2
  echo "Install dd on Linux using the following command:"
  echo "sudo apt-get install coreutils"
  echo "or"
  echo "sudo yum install coreutils"
  exit 1
fi

# Declare variables
# -----------------

fiothreads=16 # default number of threads for fio test
fiosize=1G # default size of the fio test file
fiofilename=fiofile # default name of the fio test file
fioiodepth=64 # default number of I/O operations to keep in flight
fioioengine=libaio # default I/O engine for fio test

# Functions
# ---------


# Inputs
# ------

# Ask which disk(s) to test. Show a list of available disks and let the user choose one or more disks. Save in selecteddisks variable

echo "Which disk(s) do you want to test?"
echo "Available disks are:"
lsblk -d -n -p -o NAME,SIZE,TYPE | grep disk
echo "Enter the disk(s) you want to test. Separate multiple disks with a space."
read selecteddisks

# Check if the selected disk(s) exist. If not, repeat the question until the user enters a valid disk(s)

while [ ! -b "$selecteddisks" ]; do
        echo "The disk(s) you entered do not exist. Please enter a valid disk(s)."
        read selecteddisks
done

# show disks that will be tested and ask for confirmation

echo "The following disk(s) will be tested:"
lsblk -d -n -p -o NAME,SIZE,TYPE | grep disk | grep "$selecteddisks"
echo "Do you want to continue? (y/n)"
read confirmation

# If the user does not confirm, exit the script

if [ "$confirmation" != "y" ]; then
        echo "You did not confirm. Exiting the script."
        exit 1
fi

# Ask for the number of threads to use for the fio test. Set to 16 if no input is given. Save in threads variable. Number must be 

echo "How many threads do you want to use for the fio test? (1-64) - default is $(fiothreads)"
read fiothreads

# Check if the number of threads is between 1 and 64. If not, repeat the question until the user enters a valid number

while [ "$fiothreads" -lt 1 ] || [ "$fiothreads" -gt 64 ]; do
        echo "The number of threads must be between 1 and 64. Please enter a valid number."
        read fiothreads
done


# Main Program
# ------------

echo "Starting the disk test. This will take a while. Please wait."
