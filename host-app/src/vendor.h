#ifndef VENDOR_H
#define VENDOR_H

#define TIMEOUT		500

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

#endif
