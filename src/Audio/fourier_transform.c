//
//  fourier_transform.c
//  Luxamp
//
//  Created by Jaden Bernal on 1/20/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

#include <Accelerate/Accelerate.h>
#include "fourier_transform.h"


void initialize_fft_setup(LuxampFFTSetup* setup, int fftSize, int log2fftSize) {
	setup->n = fftSize;
	setup->log2n = log2fftSize;
	setup->fftSetup = vDSP_create_fftsetup(log2fftSize, FFT_RADIX2);
	
	setup->complex_split.realp = (float *)malloc((fftSize/2) * sizeof(float));
	setup->complex_split.imagp = (float *)malloc((fftSize/2) * sizeof(float));
	
	setup->hann_window = (float *)malloc(fftSize * sizeof(float));
	memset(setup->hann_window, 0, fftSize * sizeof(float));
	vDSP_hann_window(setup->hann_window, fftSize, vDSP_HANN_DENORM);
	
	setup->windowed_buf = (float *)malloc(fftSize * sizeof(float));
}


void destroy_fft_setup(LuxampFFTSetup setup) {
	free(setup.hann_window);
	free(setup.windowed_buf);
	free(setup.complex_split.realp);
	free(setup.complex_split.imagp);
	vDSP_destroy_fftsetup(setup.fftSetup);
}


void perform_fft(const LuxampFFTSetup* setup, const float* in_buffer, float* out_magnitude) {
	float norm_factor = 2.0f / (float)setup->n;
	
	vDSP_vmul(in_buffer, 1, setup->hann_window, 1, setup->windowed_buf, 1, setup->n);
	vDSP_ctoz((COMPLEX *) setup->windowed_buf, 2, &setup->complex_split, 1, setup->n/2);
	vDSP_fft_zrip(setup->fftSetup, &setup->complex_split, 1, setup->log2n, FFT_FORWARD);
	
	setup->complex_split.imagp[0] = 0.0;
	
	for (int i = 0; i < setup->n/2; i++) {
		float power = setup->complex_split.realp[i] * setup->complex_split.realp[i] +
		setup->complex_split.imagp[i] * setup->complex_split.imagp[i];
		
		out_magnitude[i] = sqrtf(power) * norm_factor;
	}
}
