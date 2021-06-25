#include <cstdio>
#include <unistd.h>
#include <linux/nvme_ioctl.h>
#include <sys/ioctl.h>
#include <fcntl.h>

#include "vendor.h"

static void global_control(int fd, bool enable) {	

	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_GLBL_CTL,
		.cdw12 = (enable) ? ACC_EN : ACC_DIS,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_ADMIN_CMD, &cmd);


}

int main(int argc, char *argv[])
{
	if(argc < 2)
		return -1;

	printf("Opening device: %s\n", argv[1]);

	int fd = open(argv[1], O_RDWR);

	if(fd == -1) {
		printf("Failed to open NVMe device!\n");
		return -1;
	}

	global_control(fd, true);

	close(fd);

	return 0;
}
