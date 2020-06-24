%% plot of exponential and hyper-exponential distributions for different duty cyles
clc
clear

MeanOFFtime = [1600, 200, 1400, 800, 1800];   % mean time in seconds
OFF_rate =  1 ./ MeanOFFtime;
% enter the OFF state probability ie (1-duty cycle)
duty_cycle = [.2, .9, .3, .6, .1];
inv_V = 1 - duty_cycle;

ON_rate = ((1-inv_V)/inv_V).*OFF_rate;
% % plot of exponential distribution
dt = 0.001:0.001:2000;
figure
for i = 1:5    %for the 5 channels
    subplot(211)
    P_11 = inv_V(i) + (1-inv_V(i)).*exp(-(OFF_rate(i) + ON_rate(i)).*dt);
    grid on
    plot(dt,P_11, '-..')
    legend('20% duty cycle', '90% duty cycle', '30% duty cycle', '60% duty cycle', ...
        '10% duty cycle')
    ylabel('P_{off-off}')
    hold on
    
    subplot(212)
    P_01 = inv_V(i) - inv_V(i).*exp(-(OFF_rate(i) + ON_rate(i)).*dt);
    grid on
    plot(dt, P_01, '-..')
    legend('20% duty cycle', '90% duty cycle', '30% duty cycle', '60% duty cycle', ...
        '10% duty cycle')
    ylabel('P_{on-off}')
    xlabel('inter-sensing time (ms)')
    hold on
end    