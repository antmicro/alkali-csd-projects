#include <cstdio>
#include <unistd.h>
#include <linux/nvme_ioctl.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <cassert>

#include "vendor.h"

static void global_control(int fd, bool enable)
{
	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_GLBL_CTL,
		.cdw12 = (enable) ? ACC_EN : ACC_DIS,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_ADMIN_CMD, &cmd);
}

static void printhex(unsigned char *buf, uint32_t len)
{
	for(uint32_t i = 0; i < len; i++) {
		printf("%02x ", buf[i]);
		if((i % 16) == 15)
			printf("\n");
	}
	printf("\n");
}

const char magic[] = "WDC0";

int acc_identify(int fd)
{
	uint32_t len = sizeof(ident_head_t);
	uint8_t *buf = (uint8_t*)malloc(len);

	if(!buf)
		return 1;

	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_IDENT,
		.addr = (uint64_t)buf,
		.data_len = len,
		.cdw10 = len / 4,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_ADMIN_CMD, &cmd);

	ident_head_t *head = (ident_head_t*)buf;

	if(memcmp(head->magic, magic, 4)) {
		printf("Invalid magic value!\n");
		return 1;
	}

	printhex(buf, len);

	len = head->len;

	free(buf);

	buf = (uint8_t*)malloc(len);

	cmd.addr = (uint64_t)buf;
	cmd.data_len = len;
	cmd.cdw10 = len / 4;

	ioctl(fd, NVME_IOCTL_ADMIN_CMD, &cmd);

	printhex(buf, len);

	free(buf);

	return 0;
}

int send_fw(int fd, char *fw)
{
	int fw_fd = open(fw, O_RDONLY);

	if(fw_fd == -1) {
		printf("Failed to open FW file!\n");
		return 1;
	}

	uint32_t len = lseek(fw_fd, 0, SEEK_END);

	void *buf = malloc(len);

	lseek(fw_fd, 0, SEEK_SET);

	uint32_t rlen = read(fw_fd, buf, len);

	if(rlen != len) {
		printf("Failed to read FW file! (got: %d, expected: %d)\n", rlen, len);
		return 1;
	}

	close(fw_fd);

	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_SEND_FW,
		.addr = (uint64_t)buf,
		.data_len = len,
		.cdw10 = len / 4,
		.cdw13 = FW_ID,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_IO_CMD, &cmd);

	free(buf);

	return 0;
}

void set_input_buffer(int fd)
{
	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_LBA_IN,
		.cdw12 = 0,
		.cdw13 = 0,
		.cdw14 = 1,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_IO_CMD, &cmd);
}

void set_output_buffer(int fd)
{
	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_LBA_OUT,
		.cdw12 = 1,
		.cdw13 = 0,
		.cdw14 = 1,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_IO_CMD, &cmd);
}

int setup_buffers(int fd, char *ifile)
{
	int ifd = open(ifile, O_RDONLY);
	uint32_t len = lseek(ifd, 0, SEEK_END);

	assert(len == BUF_SIZE);

	void *buf = malloc(len);

	lseek(ifd, 0, SEEK_SET);

	uint32_t rlen = read(ifd, buf, len);

	if(rlen != len) {
		printf("Failed to read input file! (got: %d, expected: %d)\n", rlen, len);
		return 1;
	}

	close(ifd);

	lseek(fd, 0, SEEK_SET);

	uint32_t wlen = write(fd, buf, len);

	free(buf);

	if(wlen != len) {
		printf("Failed to write to NVMe! (got: %d, expected: %d)\n", wlen, len);
		return 1;
	}

	set_input_buffer(fd);

	set_output_buffer(fd);

	return 0;
}

int copy_output(int fd, char *ofile)
{
	int ofd = open(ofile, O_WRONLY, O_CREAT | O_TRUNC);

	if(ofd == -1) {
		printf("Failed to open output file!\n");
		return 1;
	}

	uint32_t len = BUF_SIZE;

	void *buf = malloc(len);

	lseek(fd, len, SEEK_SET);

	uint32_t rlen = read(fd, buf, len);

	if(rlen != len) {
		printf("Failed to read input file! (got: %d, expected: %d)\n", rlen, len);
		return 1;
	}

	uint32_t wlen = write(ofd, buf, len);

	close(ofd);

	if(wlen != len) {
		printf("Failed to read input file! (got: %d, expected: %d)\n", wlen, len);
		return 1;
	}

	return 0;
}

void acc_ctl(int fd, uint32_t op, uint32_t id = 0)
{
	struct nvme_passthru_cmd cmd = {
		.opcode = CMD_CTL,
		.cdw13 = op,
		.cdw14 = id,
		.timeout_ms = TIMEOUT,
	};

	ioctl(fd, NVME_IOCTL_IO_CMD, &cmd);
}

int check_acc(int fd)
{
	return 0;
}

int main(int argc, char *argv[])
{
	if(argc < 5) {
		printf("Usage: %s <nvme device> <firwmare file> <input file> <output file>\n", argv[0]);
		return -1;
	}

	printf("Opening device: %s\n", argv[1]);

	int fd = open(argv[1], O_RDWR);

	if(fd == -1) {
		printf("Failed to open NVMe device!\n");
		return -1;
	}

	if(acc_identify(fd)) {
		printf("Identify failed!\n");
	}

	global_control(fd, true);

	printf("Sending FW: %s\n", argv[2]);

	send_fw(fd, argv[2]);

	setup_buffers(fd, argv[3]);

	acc_ctl(fd, CTL_SEL_FW);

	acc_ctl(fd, CTL_START);

	//while(check_acc(fd)){
	sleep(1);
	//}

	copy_output(fd, argv[4]);

	close(fd);

	return 0;
}
