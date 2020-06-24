%% Threshold plot
clc
clear all

Pf = 0:0.1:1;
N = 1:2^21;
% assume gaussian noise at -79.47dB for 50 Ohm load
noise = wgn(length(N), 1, -79.47, 50);
noise_power = var(noise);
noise_dB = 10*log10(noise_power);
msg = ['The noise power is ', num2str(noise_dB), 'dB'];
disp(msg);
figure
for i = 1:length(Pf)
    thres = (qfuncinv(Pf(i)) + sqrt(N)).*sqrt(N)*noise_power;
    ylabel('Threshold')
    xlabel('Number of samples')
    title('Plot of Threshold against Number of samples for different Pf')
    plot(N,thres)
    hold on
end
