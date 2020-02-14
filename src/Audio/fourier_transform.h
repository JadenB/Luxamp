//
//  fourier_transform.h
//  Luxamp
//
//  Created by Jaden Bernal on 1/20/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

#ifndef fourier_transform_h
#define fourier_transform_h

#include <stdio.h>
#include <Accelerate/Accelerate.h>

typedef struct {
	FFTSetup fftSetup;
	int n;
	int log2n;
	float* hann_window;
	float* windowed_buf;
	COMPLEX_SPLIT complex_split;
} LuxampFFTSetup;

void initialize_fft_setup(LuxampFFTSetup* setup, int fftSize, int log2fftSize);
void destroy_fft_setup(LuxampFFTSetup setup);
void perform_fft(const LuxampFFTSetup* setup, const float* in_buffer, float* out_magnitude);
float root_mean_square(const LuxampFFTSetup* setup, const float* in_buffer);

#endif /* fourier_transform_h */
