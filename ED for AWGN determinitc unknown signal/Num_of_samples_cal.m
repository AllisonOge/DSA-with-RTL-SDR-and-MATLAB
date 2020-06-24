% calcualtes the number of samples given a snr wall and desired
% probabilities of detection and false alarm

clear
clc
SNR_min_dB = -10; % minimum SNR for a signal of -116dBm and noise floor of -106dBm
SNR_min = 10^(SNR_min_dB/10);
Pf = 0.01;  % maximum probability of false alarm
num_of_samp = (qfuncinv(Pf)- qfuncinv(1-Pf)*sqrt(2*SNR_min + 1))^2 * SNR_min^(-2);
disp(['The minimum number of samples required for an ',...
    'energy detector of SNR wall of -10dB is ', num2str(num_of_samp)])