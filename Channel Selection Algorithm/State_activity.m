% This script plots the probality of the number of steps in a markov model
% of any of the respective p11 and p01
clc
clear

state = single.empty;
figure
steps = 1:1:15;
% considering 15 steps
for n = 1:5
    str = ['Considering channel...', num2str(n)];
    disp(str)
    for k = 1:15
       state(k) = sensing_block(n, k);
    end
    plot(steps,state, '-*')
    hold on
end

title("State activity of channels for 15 steps")
xlabel("Number of steps")
ylabel("Activity")
legend('20% duty cycle', '90% duty cycle', '30% duty cycle', '60% duty cycle', ...
        '70% duty cycle')