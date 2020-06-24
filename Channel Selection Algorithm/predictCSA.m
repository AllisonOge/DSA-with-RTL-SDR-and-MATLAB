% a script to simulate the predictive CSA for 5 channels of different duty
% cycles and inter-sensing time
% PU OFF time is assumed to be hyper-exponential


%% for a particular inter-sensing time test CSA and show results based on percentage of selected channel and throughput(packets transmitted) real time plot in time scope
clc
clear
%init
samp_rate = 1e6;    %sample rate
nsamp = 4098;       % number of sample per frame
dtype = 'single';     % output data type
% system object
% sine system object
sine1 = dsp.SineWave('Amplitude', 2, 'Frequency', 3000,...
    'SampleRate', samp_rate, ...
    'SamplesPerFrame', nsamp, 'OutputDataType', dtype); 
sine2 = dsp.SineWave('Amplitude', 1.5, 'Frequency', 9000,...
    'SampleRate', samp_rate, ...
    'SamplesPerFrame', nsamp, 'OutputDataType', dtype);

noise = wgn(nsamp, 1, -104, 50);
signal = sine1() + sine2() + noise;

% time scope object
timeScope = dsp.TimeScope(...
    'NumInputPorts', 1,...
    'SampleRate', samp_rate, 'YLimits', [-3 3]);
% p11 and p01 computation
% uncomment the corresponding meanofftime and duty cycle to have a
% consistent result
% MeanOFFtime = [1600, 200, 1400, 800, 600];   % mean time in seconds
MeanOFFtime = [1000, 200, 1400, 800, 400];  
% MeanOFFtime = [1, 60, 1920, 1200, 20];  
% MeanOFFtime = [40, 60, 1920, 1200, 20];   
% MeanOFFtime = [4, 60, 1920, 1200, 20];   



% Enter the OFF state probability ie (1-duty cycle)
% duty_cycle = [.2, .9, .3, .6, .7];
duty_cycle = [.5, .9, .3, .6, .8];
% duty_cycle = [1, .97, .04, .4, .99];
% duty_cycle = [.98, .97, .04, .4, .99];
% duty_cycle = [.998, .97, .04, .4, .99];

OFF_rate =  1 ./ MeanOFFtime;
inv_V = 1 - duty_cycle;
ON_rate = ((1-inv_V)/inv_V).*OFF_rate;
dt = 600;
P_off_off = inv_V + (1-inv_V).*exp(-(OFF_rate + ON_rate)*dt);
P_on_off = inv_V - inv_V.*exp(-(OFF_rate + ON_rate)*dt);
nstep = 0;
nbackoff = 0;
backoff = timer;
niteration = 1000;
while  nstep < niteration
    result = 1;
    % assume all 10 channel starts at OFF state
    belief_vec = single.empty;
    nselection = [0, 0, 0, 0, 0];
    disp('      initialize belief vector and result array...')
    for n = 1:5
        belief_vec(n) = P_off_off(n)*0 + P_on_off(n)*1;
    end
    result_arr = [0, 0, 0, 0, 0];
    if backoff.Running == 'off'
        backoff_timer = 0;
    else
        backoff_timer = 1;
    end
    % check backoff timer
    while (backoff_timer == 0 || nstep > 1 || result == 0) && nstep <=niteration
        disp('      select a channel of maximum on state...')
        % select a channel from max of P_idlechan
        max_belief_vec = max(belief_vec);
        % get channel index
        selected_chan = getIndex(max_belief_vec, belief_vec);
        % sense the selected channel
        % sensing algorithm is simplified to focus attention on selection algorithm
        % by choosing a threshold of 600ms 

        disp('      sensing channel...')
        [result, nstep] = sensing_block( selected_chan, nstep);
        % update belief vector
        disp('      update belief vector...')
        [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, selected_chan, result);
        % is channel free
        if(result == 0)
            % store frequency of selection of all 10 channels in an arr
            nselection(selected_chan) = nselection(selected_chan) + 1;
            % send data to time scope
            timeScope(signal);
            %wait for 600ms
            t = timer;
            t.StartFcn = @(~, thisEvent)disp('     starting transmission for 600ms...');
            t.TimerFcn = @(myTimerObj, thisEvent)disp('     ending transmission...');
            t.Period = .6;
            t.ExecutionMode = 'singleShot';
            t.TasksToExecute = 2;
            start(t);
            delete(t)
            

            while result == 0
                % is selected channel still free
                disp('      checking if selected channel is still free...')
                [result, nstep] = sensing_block(selected_chan, nstep);
                disp('      update belief vector...')
                [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, selected_chan, result);
                if result == 1 || nstep >= niteration
                    break;
                end
                % store frequency of selection of all 10 channels in an arr
                nselection(selected_chan) = nselection(selected_chan) + 1;
                % send data to time scope
                timeScope(signal);
                %wait for 600ms
                t = timer;
                t.StartFcn = @(~, thisEvent)disp('     starting transmission for 600ms...');
                t.TimerFcn = @(myTimerObj, thisEvent)disp('     ending transmission...');
                t.Period = .6;
                t.TasksToExecute = 2;
                start(t);
                delete(t)
            end
            
        else 
            

            % sense all channels    
            disp('      channels are mostly busy, sensing all channels...')
            for chan = 1:length(belief_vec)
               disp('      sensing channel...')
               [result, nstep] = sensing_block(chan, nstep);
               disp('      update belief vector...')
               [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, chan, result);
               if result == 0 || nstep >= niteration
                   break;
               end
            end
     
            % set backoff timer
            if result == 1 && nstep <= niteration
                backoff.StartFcn= @(~, thisEvent)disp('     starting backoff mode for 1s...');
                backoff.TimerFcn = @(myTimerObj, thisEvent)disp('     ending backoff mode...');
                backoff.TasksToExecute = 2;
                start(backoff);
                nstep = nstep + 1;
                nbackoff = nbackoff + 1;
            end
        end
        
    end
end% run simulation for 10000 steps for intersensing time of 600ms

%plot results
figure
duty_cyc = categorical({[num2str(duty_cycle(1)*100), '%'], [num2str(duty_cycle(2)*100), '%'],...
    [num2str(duty_cycle(3)*100), '%'], [num2str(duty_cycle(4)*100), '%'],...
    [num2str(duty_cycle(5)*100), '%']});

bar(duty_cyc, nselection)
xlabel('Duty cycle')
ylabel('Frequency of selection')
filename = ['Predictive_CSA_duty_cyles_', num2str(duty_cycle(1)*100), '%_', num2str(duty_cycle(2)*100), '%_',...
    num2str(duty_cycle(3)*100), '%_', num2str(duty_cycle(4)*100), '%_', num2str(duty_cycle(5)*100), '%.fig'];

savefig(filename);