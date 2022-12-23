#!/bin/bash
#
# Script to generate GUID Partition Table (GPT) test files
# Requires Linux dd, fdisk and gdisk

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1;

	which ${BINARY} > /dev/null 2>&1;
	if test $? -ne ${EXIT_SUCCESS};
	then
		echo "Missing binary: ${BINARY}";
		echo "";

		exit ${EXIT_FAILURE};
	fi
}

assert_availability_binary dd;
assert_availability_binary fdisk;
assert_availability_binary gdisk;

set -e;

SPECIMENS_PATH="specimens/gdisk";

mkdir -p ${SPECIMENS_PATH};

IMAGE_SIZE=$(( 4096 * 1024 ));
SECTOR_SIZE=512;

# Create a GPT with a single partition
IMAGE_NAME="gpt_single.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

gdisk ${IMAGE_FILE} <<EOT
n
1

+64K
8300
w
y
EOT

# Create a GPT with multiple partitions
IMAGE_NAME="gpt_multi.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

gdisk ${IMAGE_FILE} <<EOT
n
1

+64K
8300
n
2

+64K
8300
n
3

+64K
8300
n
4

+64K
8300
w
y
EOT

# Create a MBR/GPT hybrid with a single partition
IMAGE_NAME="gpt_hybrid.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

gdisk ${IMAGE_FILE} <<EOT
n
1

+64K
8300
r
h
1
y

y
n
w
y
EOT

# TODO: fdisk seems to create corrupt gpt volume systems for block size > 512

for SECTOR_SIZE in 512 1024 2048 4096;
do
	# Create a GPT with a single primary partition
	IMAGE_NAME="gpt_${SECTOR_SIZE}_single.raw"
	IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

	fdisk -b ${SECTOR_SIZE} -u ${IMAGE_FILE} <<EOT
g
n
1

+64K
w
EOT

done

# Create a GPT with multiple partitions that are non-sequential
IMAGE_NAME="gpt_multi_non_sequential.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

gdisk ${IMAGE_FILE} <<EOT
n
1

+64K
8300
n
2

+64K
8300
n
3

+64K
8300
n
4

+64K
8300
d
2
w
y
EOT

# Create an empty GPT with a protective MBR
IMAGE_NAME="gpt_empty.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

gdisk ${IMAGE_FILE} <<EOT
o
y
w
y
EOT

# Create an empty GPT with multiple MBR partitions
IMAGE_NAME="gpt_empty_with_mbr.raw"
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} ))

gdisk ${IMAGE_FILE} <<EOT
o
y
w
y
EOT

# Note that fdisk will write into the GPT partition entries area if the partition start offset
# is not set correctly.
fdisk -u ${IMAGE_FILE} <<EOT
M
d
n
p
1
48
+64K
w
EOT

# TODO: create gpt with corrupt partition table header but valid backup
# TODO: create gpt with corrupt backup partition table header
# TODO: create gpt with partition table header and backup that pass checksum but mismatch values
# TODO: create gpt with empty first partition entry but filled second
# TODO: create gpt with mismatch backup partition entries

exit ${EXIT_SUCCESS};

