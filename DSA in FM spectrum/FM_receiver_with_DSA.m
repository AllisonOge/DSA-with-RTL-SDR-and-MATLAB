%% FM receiver with Dynamic Spectrum access
% This is a project related work
% code by Allison Ogechukwu
%%
function FM_receiver_with_DSA
%FM_receive_with_DSA demonstrates DSA in the FM spectrum with 5 channels
% the program uses energy detection for sensing and predictive channel 
% selection algorithm for selecting the best one of the 5 channels
%
clear
clc
% parameters can change
rtlsdr_id           = '0';          %RTL-SDR ID
start_freq          = 97.3e6;       %RTL-SDR start frequency in Hz
rtlsdr_gain         = 25;           %RTL-SDR tuner gain in dB
rtlsdr_datatype     = 'single';     %RTL-SDR output data type
rtlsdr_ppm          = 0;            %RTL-SDR tuner PPM correction
Pf                  = 0.01;         %probability of false alarm for channel sensing
sim_time            = 600;           %simulation time in seconds
process_time        = 0;            %performance measurement

%  parameters (can change but may break code)
freq_bw             = 200e3;        %FM channel bandwidth
rtlsdr_fs           = 1e6;          %RTL-SDR sampling rate in Hz
rtlsdr_frmsize      = 256*25*5*6;   %RTL-SDR samples per frame
audio_rate          = 48e3;         % sample rate of audio player

%system object
% audio save
audio_save = dsp.AudioFileWriter('result/audio_file_DSA_test.wav','SampleRate', audio_rate);

% calculations
freq_range = start_freq:freq_bw:start_freq+5*freq_bw;     % create 5 channels
% timer for backup
nbackoff = 0;
backoff = timer;
%% assumptions on 5 channels using exponential OFF time model
% p11 and p01 computation
MeanOFFtime = [800, 800, 800, 800, 800];   % mean time in seconds
OFF_rate =  1 ./ MeanOFFtime;
% enter the OFF state probability ie (1-duty cycle)
duty_cycle = [.6, .6, .6, .6, .6];
inv_V = 1 - duty_cycle;
ON_rate = ((1-inv_V)/inv_V).*OFF_rate;
dt = 2000;
P_off_off = inv_V + (1-inv_V).*exp(-(OFF_rate + ON_rate)*dt);
P_on_off = inv_V - inv_V.*exp(-(OFF_rate + ON_rate)*dt);
%%
while process_time < sim_time   % run program for a max simulation time
    result = 1;     % start with no assumed free channel
    % assume all 5 channel starts at OFF state
    belief_vec = single.empty;
    disp('      initialize belief vector and result array...')
    for n = 1:5
        belief_vec(n) = P_off_off(n)*0 + P_on_off(n)*1;
    end
    nselection = [0, 0, 0, 0, 0];
    result_arr = [0, 0, 0, 0, 0];
    if backoff.Running == 'off'
        backoff_timer = 0;
    else
        backoff_timer = 1;
    end
    while (backoff_timer == 0 || process_time > 0 || result == 0) && process_time < sim_time
        tic;
        disp('      select a channel of maximum on state...')
        % select a channel from max of P_idlechan
        max_belief_vec = max(belief_vec);
        % get channel index
        selected_index = getIndex(max_belief_vec, belief_vec);
        selected_chan = freq_range(selected_index);
        % sense the selected channel
        result = sensing(selected_chan);
        % update belief vector
        disp('      update belief vector...')
        [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, selected_index, result);
        % is channel free
        if result == 0
            % store frequency of selection of all 5 channels in an arr
            nselection(selected_index) = nselection(selected_index) + 1;
            % receive data
            receive(selected_chan);
            % update belief vector
            disp('      update belief vector...')
            [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, selected_index, result);

            while result == 0
                % is selected channel still free
                disp('      checking if selected channel is still free...')
                result = sensing(selected_chan);
                disp('      update belief vector...')
                [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, selected_index, result);
                process_time = process_time + toc;
                if result == 1 || process_time >= sim_time
                    break;
                end
                % store frequency of selection of all 5 channels in an arr
                nselection(selected_index) = nselection(selected_index) + 1;
                % receive data
                receive(selected_chan);
            end
            
        else 
            % sense all channels    
            disp('      channels are mostly busy, sensing all channels...')
            for chan = 1:length(belief_vec)
               % get channel freq
               selected_chan = freq_range(chan);     % channel_freq
               result = sensing(selected_chan);
               disp('      update belief vector...')
               [belief_vec, result_arr] = updateVec(P_off_off, P_on_off, result_arr, chan, result);
               process_time = process_time + toc;
               if result == 0 || process_time > sim_time
                   break;
               end
            end
            % set backoff timer
            if result == 1 && process_time < sim_time
                backoff.StartFcn= @(~, thisEvent)disp('     starting backoff mode for 1s...');
                backoff.TimerFcn = @(myTimerObj, thisEvent)disp('     ending backoff mode...');
                backoff.TasksToExecute = 2;
                start(backoff);
                process_time = process_time + 1;    % add 1 second to process time
                nbackoff = nbackoff + 1;
            end
        end
    end
end
release(audio_save) % release audio
%plot results
figure
duty_cyc = categorical({[num2str(freq_range(1)/1e6), 'MHz'], [num2str(freq_range(2)/1e6), 'MHz'],...
    [num2str(freq_range(3)/1e6), 'MHz'], [num2str(freq_range(4)/1e6), 'MHz'],...
    [num2str(freq_range(5)/1e6), 'MHz']});

bar(duty_cyc, nselection)
xlabel('FM stations')
ylabel('Frequency of selection')
filename = ['Predictive_CSA_freq_', num2str(freq_range(1)/1e6), 'MHz_', num2str(freq_range(2)/1e6), 'MHz_',...
    num2str(freq_range(3)/1e6), 'MHz_', num2str(freq_range(4)/1e6), 'MHz_', num2str(freq_range(5)/1e6), 'MHz.fig'];

savefig(filename);

    % sense the selected channel
    function result = sensing(selected_freq)
        % start timer 
        tic;
        % system objects
        % rtlsdr
        rtlsdr = comm.SDRRTLReceiver(...
            rtlsdr_id,...
            'CenterFrequency', selected_freq,... 
            'EnableTunerAGC', false,...
            'TunerGain', rtlsdr_gain,...
            'SampleRate', rtlsdr_fs, ...
            'SamplesPerFrame', rtlsdr_frmsize, ...
            'OutputDataType', rtlsdr_datatype,...
            'FrequencyCorrection', rtlsdr_ppm);
        % calculation 
        %assume gaussian noise at -40.53dB 
        noise = wgn(rtlsdr_frmsize, 1, -40.53);
        noise_power = var(noise);
        % checks
        if isempty(sdrinfo(rtlsdr.RadioAddress))
            error(['RTL-SDR failure. Please check that connection is establised'...
                    'to MATLAB using "sdrinfo" command']);
        end 

        % sense the selected channel
        disp(['      sensing ', num2str(round(selected_freq/1e6,1)),'MHz...'])
        sense_dat = rtlsdr();
        N = length(sense_dat);
        %the test statistics is    
        test_stats = sum(abs(sense_dat).^2); 
        thres = (qfuncinv(Pf) + sqrt(N))*sqrt(N)*noise_power;
        %dectect PU presence
        if test_stats >= thres
            result = 1;
        else
            result = 0;
        end
        process_time = process_time +  toc;
        release(rtlsdr)
    end
    %receive, demodulate to audio signal and save
    function receive(selected_freq)
        % start timer 
        tic;
        % system objects
        % rtlsdr
        rtlsdr = comm.SDRRTLReceiver(...
            rtlsdr_id,...
            'CenterFrequency', selected_freq,... 
            'EnableTunerAGC', false,...
            'TunerGain', rtlsdr_gain,...
            'SampleRate', rtlsdr_fs, ...
            'SamplesPerFrame', rtlsdr_frmsize, ...
            'OutputDataType', rtlsdr_datatype,...
            'FrequencyCorrection', rtlsdr_ppm);
        % delay object
        delay_block = dsp.Delay();

        % decimator for decimating and filtering to 200kHz MPX signal
        decimate_block = dsp.FIRDecimator( 5,...
            'Numerator', fir1(50, .3, 'low', blackmanharris(51)));

        % FIRfilter lowpass for 15kHz audio signal within 200kHz (15/200)
        filter_fir_mono = dsp.FIRFilter(fir1(200, 0.075,'low', blackmanharris(201)));

        % FIRfilter bandpass for 19kHz pilot signal within 200kHz (19/200)
        filter_fir_pilot = dsp.FIRFilter(fir1(200, [0.09 0.1], 'bandpass', blackmanharris(201)));

        % FIRfilter bandpass for 30kHz stereo signal between 23kHz-53kHz within 200kHz (23/200 - 53/200)
        filter_fir_stereo = dsp.FIRFilter(fir1(200, [0.115 0.265], 'bandpass', blackmanharris(201)));

        % decimator from 200kHz to 48kHz and filtering (48/200)
        dec_filter = dsp.FIRDecimator( 25, fir1(50, 0.24, 'low', blackmanharris(51)));

        % deemphasis filter for US is 75 microsecs or 2122.2Hz (2.1222/48)
        deemph_filter_us = dsp.FIRFilter(fir1(50, 0.0442, 'low', blackmanharris(51)));
        
        
        % checks
        if isempty(sdrinfo(rtlsdr.RadioAddress))
            error(['RTL-SDR failure. Please check that connection is establised'...
                    'to MATLAB using "sdrinfo" command']);
        end 
        time = 5;
        % start receiving
        disp(['      start receiving samples from ', num2str(round(selected_freq/1e6,1)), 'MHz, '...
                'processing time is ', num2str(process_time), 's']);
        while toc < time   % receive for 2 seconds
            
            rtl_sig = rtlsdr();     % extract length of samples

            rtl_sig_delay = delay_block(rtl_sig); % delay by one sample
            rtl_conj = conj(rtl_sig);   % obtain the conjugate of the samples
            mixer_out = rtl_sig_delay .* rtl_conj;  % mix respective outputs
            arg = angle(mixer_out);     % obtain angle
            arg = arg - mean(arg);      % remove dc

            signal_mpx = decimate_block(arg);

            % FM MPX mono audio channel
            mono_extract = filter_fir_mono(signal_mpx);    
            pilot_extract = filter_fir_pilot(signal_mpx);
            stereo_filtered = filter_fir_stereo(signal_mpx);

            stereo_mixed = stereo_filtered .* (2.*pilot_extract);
            stereo_extract = filter_fir_mono(stereo_mixed);

            % audio left signal extract
            audio_left = stereo_extract + mono_extract;
            audio_left_8k = dec_filter(audio_left);
            audio_left_48k = upsample(audio_left_8k, 6);
            % de-emphasis
            audio_left_48k = deemph_filter_us(audio_left_48k);
            % save in file
            audio_save(audio_left_48k);
            process_time = process_time + toc;
        end
        % release objects
        release(rtlsdr)
        release(delay_block)
        release(decimate_block)
        release(filter_fir_mono)
        release(filter_fir_pilot)
        release(filter_fir_stereo)
        release(dec_filter)
        release(deemph_filter_us)
        disp(['      audio samples received after ', num2str(time), 'seconds, processing time is ', num2str(process_time), 's'])
    end
end

