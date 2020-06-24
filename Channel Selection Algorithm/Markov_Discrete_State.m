function [result, num_of_steps] = Markov_Discrete_State(Pr_01, Pr_11, channel,num_of_steps)
%SENSING_BLOCK Summary of this function goes here
%   Detailed explanation goes here

% variables
state = [0; 1];     % initial state
% form markov matrix
markov_A = [1-Pr_01(channel), 1-Pr_11(channel); Pr_01(channel), Pr_11(channel)];
% compute eigenvalues and vectors and fill the array
[eigen_vec, eigen_val] = eig(markov_A);
% compute the constants 
constants = linsolve(eigen_vec, state);

% sensing
prb_of_ON = constants(1)* eigen_val(1,1)^num_of_steps * eigen_vec(1,1) + constants(2) * ...
    eigen_val(2,2)^num_of_steps * eigen_vec(1,2);

result = prb_of_ON;
num_of_steps =  num_of_steps + 1;
end

