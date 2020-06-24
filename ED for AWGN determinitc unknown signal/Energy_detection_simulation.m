% This code is to plot the following :
%           receiver operating characteristic curve 
%           fft of signal and noise 
% for simple energy detection considering a deterministic unknown signal
% with additive white real Gaussian noise. Here,
% the threshold is computed analytically using a derived formular for a
% -10dB SNR_wall whose signal strength is as low as -177.2136dBm according
% to IEEE 802.22 standard
% Code written by: Allison Ogechukwu, University of Benin, Nigeria.

clc
close all
clear
snr_dB = 5; % SNR in decibels
snr = 10^(snr_dB/10); % Linear Value of SNR
Pf = 0.01:0.01:1; % Pf = Probability of False Alarm
%% Simulation to plot Probability of Detection (Pd) vs. Probability of False Alarm (Pf) 
Pd = double.empty;
test_stat = single.empty;
N = 2^nextpow2(2376.3034); %minimum num_of_samp
fs = 1024; %sampling freq
if N < fs
    N = fs;
end
ts = 1/N;  
t = ts:ts:1;
signal = 0.0007*(0.05*sin(2*pi*10*t) + 0.048*sin(2*pi*30*t) + 0.04*sin(2*pi*50*t) + 0.032*sin(2*pi*70*t) + 0.015*sin(2*pi*90*t) + 0.01*sin(2*pi*110*t)); %10Hz+30Hz+50Hz+70Hz+90Hz+110Hz signal
sig_power = sum(abs(signal).^2)/length(signal);  %linear power of sig
sig_power_dB = 10*log10(sig_power);
noise_power = sig_power/snr;
disp(['Signal power is ',num2str(sig_power_dB - 30),'dBm and the noise power is ',...
    num2str(10*log10(noise_power) - 30), ' dBm'])
% for awgn channel
noise = wgn(1, N, noise_power, 1, 'linear');
y = signal + noise;
progress = 0;
for m = 1:length(Pf)
    i = 0;
    for s=1:10000 % Number of Monte Carlo Simulations or sensing time
     test_stat = sum(abs(y).^2); % Test Statistic for the energy detection
     thresh = (qfuncinv(Pf(m)) + sqrt(N))*sqrt(N)*noise_power; % calculate threshold
     if(test_stat > thresh)  % Check whether the received energy is greater than threshold, if so, increment Pd (Probability of detection) counter by 1
         i = i+1;
     end
    end
    Pd(m) = i/s; 
    % UX design
    if floor(m*10/length(Pf)) ~= progress
        progress  = floor(m*10/length(Pf));
        disp( ['Please wait...',num2str(progress*10),'%'])
    end
end

figure
plot(Pf, Pd)
title(['Receiver Operating Characteristics Curve: plot of P_{FA} against P_D for SNR of ', num2str(snr_dB),'dB and N =', num2str(N)])
xlabel('Probability of false alarm (P_{FA})')
ylabel('Probability of detection (P_D)')
hold on

%% Theoretical expression of Probability of Detection; refer above reference.
thresh = (qfuncinv(Pf) + sqrt(N)).*sqrt(N).*noise_power;
Pd_the = qfunc(qfuncinv(Pf)./sqrt(1+2*snr)-(sqrt(N)*snr)/sqrt(1+2*snr));
plot(Pf, Pd_the, 'r')
legend('Simulation','Theoretical')
%% Time and frequency domain plots
figure
s(1) = subplot(211);
plot(t,signal)
xlabel('time(sec)')
ylabel('amplitude')
hold on
plot(t,y, 'r-')
legend('signal', 'signal+noise')

s(2) = subplot(212);
Nfft = 1024; 
FFT = fft(y, Nfft);
f = 0:fs/Nfft:fs/2-1;
Normalized_FFT = 20*log10((abs(FFT).^2)/max(abs(FFT).^2)*5000);
plot(f,Normalized_FFT(1: Nfft/2))
title(s(1),['Plot of signal in the time domain for an SNR of ', num2str(snr_dB),'dB'])
title(s(2),['Plot of signal in the frequency domain for an SNR of ', num2str(snr_dB),'dB'])
xlabel('frequency(Hz)')
ylabel('Normalized magnitude')
