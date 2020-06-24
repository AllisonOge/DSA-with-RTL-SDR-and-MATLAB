function [result,nsteps] = sensing_block(channel,nsteps)
%SENSING_BLOCK Summary of this function goes here
%   Detailed explanation goes here
% mean_OFF_time = [1600, 200, 1400, 800, 600];
mean_OFF_time = [800, 800, 800, 800, 800];   % mean time in seconds
distro = makedist('exponential', mean_OFF_time(channel));
OFF_time = random(distro);
if OFF_time < 600
    result = 1;
else
    result = 0;
end
nsteps = nsteps + 1;
end

