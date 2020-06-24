clc
clear all
%Energy detector with AWGN channel
prompt = 'Enter the length to the message signal between 1 - 63: ';
L = input(prompt);
prompt_N = 'Enter the desired length of received signal to sample (N < L): ';
N = input(prompt_N);
%generate transmitted signal
xn = randi([0, 63],1, L);   %generate message
x = pskmod(xn, 64);       % modulate with 2-psk
%add noise for a given SNR
for w = 1:10 
    prompt_SNR = 'Enter the Signal-to-Noise Ratio: ';
    SNR(w) = input(prompt_SNR);
end
for i = 1:10
    snr = 10^(SNR(i)/10);
    sig_power = (1/length(x))*sum(abs(x).^2);
    noise_power = sig_power/snr;
    noise_power_dB = 10*log10(noise_power);
    NOISE = wgn(1, length(x), noise_power_dB);
    Y = x + NOISE; %received signal
    %compare recvd sig against threshold
    thresh = (qfuncinv(0.01) + sqrt(N))*sqrt(N)*noise_power;
    k = 0;
    for j = 1:(floor(length(Y)/N))
        if (sum(abs(Y((j-1)*N+1:j*N)).^2) > thresh)
            k = k + 1;
        end
    end

    %plot values
    Pd_simulation(i) = k/floor(length(Y)/N);
    % UX design
    perStr = fix(100*(i/10));
    str = ['Please wait...', num2str(perStr), '%'];
    waitbar(i/10, str);
end
%figure
plot(SNR, Pd_simulation, 'r-');
xlabel('Signal-to-Noise ratio SNR')
ylabel('Probability of detection Pd')