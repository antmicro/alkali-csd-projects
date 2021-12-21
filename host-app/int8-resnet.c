static void (*print)(char*) = (void *)1;
static void (*tflite_apu)(char*, char*, int, int, int) = (void *)2;
static void (*tflite_vta)(char*, char*, int, int, int) = (void *)3;

int bpf_prog(char *imem, char *omem)
{
	const int model_size = 26294360;
	const int input_size = 224*224*3*1;
	const int output_size = 1000*1;

	char msg[] = "VTA Test (int8-resnet)\n";
	print(msg);

	tflite_vta(imem, omem, input_size, output_size, model_size);

	return 0;
}
