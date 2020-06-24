### Channel selection algorithm (CSA) implementation with 5 channels
This section shows CSA in 5 analytical determined channel of different duty cycles whose idle time is modelled as a exponential distribution. 
Open the file *PredictCSA.m* file to test the algorithm on the 5 channels and observe the command line for comments to show its steps. Also there is a realtime visualizatiion of a time plot as the algorithm is running to simulate SU transmission.
Some of the test results showing the frequency of selection of the channels is shown in *PredictiveCSA_for_5_channels.fig* files for you to observe.

Other files include 
*HED.m* - shows exponential plots of the 5 channels with respect to intersensing time
*Markov_Discrete_State.m*, *State_activity.m* - works with the *prob_of_num_of_steps.m* file 
*prob_of_num_of_steps.m* - computes and plots the Markov state of the 5 channels given the choice of duty cycle (determinitic approach)
*sensing_block.m*, *updateVec.m*, *getIndex.m* - works with *PredictCSA.m* file
 
