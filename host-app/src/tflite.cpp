#include "tensorflow/lite/interpreter.h"
#include "tensorflow/lite/kernels/register.h"
#include "tensorflow/lite/model.h"

#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <unistd.h>
#include <fcntl.h>
#include <memory>
#include <iostream>

int save_file(char *fname, char *buf, int len)
{
	int fd = open(fname, O_WRONLY, O_CREAT | O_TRUNC);

	if(fd == -1) {
		printf("Failed to open file: %s\n", fname);
		return -1;
	}
	
	int wlen = write(fd, buf, len);

	close(fd);

	if(wlen != len) {
		printf("Failed to write output file! (%d != %d)\n", wlen, len);
		return -1;
	}

	return 0;
}

int load_file(char *fname, char **buf, int *len)
{
	int fd = open(fname, O_RDONLY);

	if(fd == -1) {
		printf("Failed to open file: %s\n", fname);
		return -1;
	}

	*len = lseek(fd, 0, SEEK_END);
	lseek(fd, 0, SEEK_SET);

	*buf = (char*) malloc(*len);

	int rlen = read(fd, *buf, *len);

	if(rlen != *len) {
		printf("Failed to read input file! (%d != %d)\n", rlen, *len);
		return -1;
	}

	close(fd);

	return 0;
}

int main(int argc, char *argv[])
{
	if(argc != 4) {
		printf("Usage: %s <model_file> <input file> <output file>\n", argv[0]);
		return -1;
	}

	struct timespec ts[2];

	char *model_fname  = argv[1];
	char *input_fname  = argv[2];
	char *output_fname = argv[3];

	char *model_buf, *input_buf;
	int model_len, input_len, output_len = 1000;

	int8_t *input_tensor, *output_tensor;

	if(load_file(model_fname, &model_buf, &model_len)) {
		printf("Failed to load model!\n");
		return -1;
	}

	if(load_file(input_fname, &input_buf, &input_len)) {
		printf("Failed to load model!\n");
		return -1;
	}

	std::unique_ptr<tflite::FlatBufferModel> model = tflite::FlatBufferModel::BuildFromBuffer(model_buf, model_len);

	// Build the interpreter
	tflite::ops::builtin::BuiltinOpResolver resolver;
	std::unique_ptr<tflite::Interpreter> interpreter;
	tflite::InterpreterBuilder(*model, resolver)(&interpreter);

	// Resize input tensors, if desired.
	interpreter->AllocateTensors();
	input_tensor = interpreter->typed_input_tensor<int8_t>(0);

	std::copy(input_buf, input_buf+input_len, input_tensor);

	timespec_get(&ts[0], TIME_UTC);

	// run model
	interpreter->Invoke();

	timespec_get(&ts[1], TIME_UTC);

#ifdef DEBUG
	for(int i = 0; i < interpreter->tensors_size(); i++) {
		std::cout << "name: " << interpreter->tensor(i)->name << " type: " << interpreter->tensor(i)->type << " size: " << interpreter->tensor(i)->bytes << std::endl;
	}

	auto in = interpreter->input_tensor(0);
	auto out = interpreter->output_tensor(0);

	printf("Input tensor bytes: %d name: %s\n", in->bytes, in->name);
	printf("Output tensor bytes: %d name: %s\n", out->bytes, out->name);
#endif

	const uint64_t duration = (ts[1].tv_sec * 1000000000 + ts[1].tv_nsec) - (ts[0].tv_sec * 1000000000 + ts[0].tv_nsec);

	printf("Model processing took %llu ns\n", duration);

	// get pointer to outputs
	output_tensor = interpreter->typed_output_tensor<int8_t>(0);

	save_file(output_fname, (char*)output_tensor, output_len);
}
