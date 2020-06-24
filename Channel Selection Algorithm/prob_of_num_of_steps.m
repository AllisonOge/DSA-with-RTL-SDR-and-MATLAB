% This script plots the probality of the number of steps in a markov model
% of any of the respective p11 and p01
clc
clear
% p11 and p01 of 5 channels
P_off_off = [0.2, 0.9, 0.3, 0.6, 0.1];
P_on_off = [0.2, 0.9, 0.3, 0.6, 0.1];

prb = single.empty;
figure
steps = 1:1:15;
% considering 15 steps
for n = 1:5
    str = ['Considering channel...', num2str(n)];
    disp(str)
    for k = 1:15
       prb(k) = Markov_Discrete_State(P_on_off, P_off_off, n, k);
    end
    plot(steps,prb, '-.*')
    hold on
end

title("Probability of the number of steps of a markov model")
xlabel("Number of steps")
ylabel("Probability")
legend('20% duty cycle', '90% duty cycle', '30% duty cycle', '60% duty cycle', ...
        '10% duty cycle')