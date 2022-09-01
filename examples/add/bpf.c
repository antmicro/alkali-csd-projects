/*
 * Copyright 2021-2022 Western Digital Corporation or its affiliates
 * Copyright 2021-2022 Antmicro
 *
 * SPDX-License-Identifier: Apache-2.0
 */

static void (*print)(char*) = (void *)1;
static void (*tflite_apu)(char*, char*, int, int, int) = (void *)2;
static void (*tflite_vta)(char*, char*, int, int, int) = (void *)3;

int bpf_prog(char *imem, char *omem)
{
	const int model_size = 1024;
	const int input_size = 8;
	const int output_size = 4;
	char expected_output[] = {0x7, 0xC, 0x4, 0x5};

	char msg[] = "VTA test of ADD operation\n";
	print(msg);

	tflite_vta(imem, omem, input_size, output_size, model_size);

	for (int i = 0; i < output_size; i++) {
		if (omem[i] != expected_output[i]) {
			print("ADD test failed\n");
			return i;
		}
	}

	print("ADD test passed\n");
	return -1;
}
