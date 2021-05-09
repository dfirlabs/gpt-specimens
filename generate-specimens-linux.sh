#!/bin/bash
#
# Script to generate GUID Partition Table (GPT) test files
# Requires Linux gdisk and fdisk

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

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

# Create a GPT with multiple partition
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

# TODO: create gpt with corrupt partition table header but valid backup
# TODO: create gpt with corrupt backup partition table header
# TODO: create gpt with partition table header and backup that pass checksum but mismatch values
# TODO: create gpt with empty first partition entry but filled second
# TODO: create gpt with mismatch backup partition entries

exit ${EXIT_SUCCESS};

