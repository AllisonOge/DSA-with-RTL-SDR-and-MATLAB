`% noise estimation

clear
clc
% access saved data
sig_filtered_real = load('rtl_filtered_real.mat');
sig_received_real = load('rtl_received_signal.mat');

% compute dB relative to 50 Ohms load
sig_filtered_dB = 10*log10(abs(sig_filtered_real.rtlfilt_real).^2/50);
sig_received_dB = 10*log10(abs(sig_received_real.rtlsdr_real).^2/50);

len = 4096; % length of signal samples

% get their fft plots
% fft length of 1024
nfft = 1024;
sig_recv_fft = fft(sig_received_real.rtlsdr_real, nfft);
sig_filt_fft = fft(sig_filtered_real.rtlfilt_real, nfft);


% sys obj
hist_custom = dsp.Histogram('LowerLimit', -200, 'UpperLimit', 0, ...
                            'NumBins', 100, 'Normalize', true);

dB_scale = -199:2:0;    % generate dB scale for the x axis
frequency = 1:len/nfft:len/2; % frequency scale
% plot distribution
figure
plot(dB_scale, hist_custom(sig_received_dB),'LineWidth', 1)
hold on
plot(dB_scale, hist_custom(sig_filtered_dB),'LineWidth', 1)
legend('signal + noise', 'filtered signal')


figure
subplot(211)
plot(frequency, abs(sig_recv_fft(1:nfft/2)),'LineWidth', 1)
hold on
plot(frequency, abs(sig_filt_fft(1:nfft/2)),'LineWidth', 1)
legend('signal + noise', 'filtered signal')
title('fft with linear scale')
subplot(212)
plot(frequency, 10*log10(abs(sig_recv_fft(1:nfft/2)).^2/50),'LineWidth', 1)
hold on
plot(frequency, 10*log10(abs(sig_filt_fft(1:nfft/2)).^2/50),'LineWidth', 1)
legend('signal + noise', 'filtered signal')
title('fft with log scale relative to 50 Ohms')

% noise estimate at 25dB gain is -38.49
% generate noise samples
noise = wgn(len, 1, -40.53);
noise_dB = 10*log10(abs(noise).^2/50);

release(hist_custom)
figure
plot(dB_scale, hist_custom(noise_dB),'LineWidth', 1)
release(hist_custom)
hold on
plot(dB_scale, hist_custom(sig_filtered_dB),'LineWidth', 1)
legend('estimated noise', 'filtered signal')