clear
clc

snr_dB = 50; % SNR in decibels
snr = 10^(snr_dB/10); % Linear Value of SNR
N = 2^nextpow2(1023); %minimum num_of_samp
fs = 1024; %sampling freq
ts = 1/fs;  
t = 0.0001:ts:1;
signal = 0.1*sin(2*pi*10*t) + 0.096*sin(2*pi*30*t) + 0.08*sin(2*pi*50*t) + 0.064*sin(2*pi*70*t) + 0.03*sin(2*pi*90*t) + 0.02*sin(2*pi*110*t); %10Hz+30Hz+50Hz+70Hz+90Hz+110Hz signal
sig_power = var(signal);  %linear power of sig
sig_power_dB = 20*log10(sig_power/1000);
str = ['Signal power is ',num2str(sig_power_dB),'dBm'];
disp(str);
noise_power = sig_power/snr;
Pf = 0:0.001:1;
thresh = (qfuncinv(Pf) + sqrt(N))*sqrt(N)*noise_power;
figure 
plot(Pf,thresh)