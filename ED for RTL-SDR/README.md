## Energy detection in the FM spectrum and spectrum sensing
The algorithm in the _ED for AWGN determinitic unknown_ folder is taken a step further and tested in the FM spectrum in two ways:
- Spectrum sensing across the entire FM spectrum 87.5 to 108
- PU Occupancy at one frequency
This proved very promising as the accuracy was observed to be about 90% provided the ratio of sample rate and FFT size is keep within recommended values for measurement.

Open *rtlsdr_rx_sweep_and_ED.m* file for spectrum sensing across the FM spectrum, test files are also included
Open *PUactiveduration.m* file for PU occupancy at one frequency for some seconds

Other files
*Visualization.m* - for frequency and spectrogram plot of an FM station