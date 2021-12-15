static void (*print)(char*) = (void *)1;
static void (*tflite)(char*, char*, int, int) = (void *)2;
static void (*tflite_float)(char*, char*, int, int, int) = (void *)3;
static void (*tflite_uint)(char*, char*, int, int, int) = (void *)4;
static void (*tflite_vta)(char*, char*, int, int, int) = (void *)5;

int bpf_prog(char *imem, char *omem)
{
       const int model_size = 102163764;
       const int input_size = 224*224*3*4;
       const int output_size = 1000*4;

       char msg[] = "VTA Test\n";
       print(msg);

       tflite_float(imem, omem, input_size, output_size, model_size);

       return 0;
}
