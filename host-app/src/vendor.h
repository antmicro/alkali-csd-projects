#ifndef VENDOR_H
#define VENDOR_H

#include <stdint.h>

#define TIMEOUT		5000
#define FW_ID		0

#define BUF_SIZE	4096

#define CMD_GLBL_CTL	0xC0
#define CMD_IDENT	0xC2
#define CMD_GET_STAT	0xC6

#define ACC_EN		0x00U
#define ACC_DIS		0x01U

#define CMD_SEND_DATA	0x81
#define CMD_GET_DATA	0x82
#define CMD_SEND_FW	0x85
#define CMD_GET_FW	0x86
#define CMD_LBA_IN	0x88
#define CMD_LBA_OUT	0x8C
#define CMD_CTL		0x91

#define CTL_START	0x01U
#define CTL_SEL_FW	0x03U

typedef struct ident_head {
	uint8_t magic[4];
	uint32_t len;
	uint8_t rsvd[8];
} ident_head_t;

typedef struct status_head {
	uint32_t len;
	uint32_t id;
	uint32_t rsvd[6];
} status_head_t;

#endif
