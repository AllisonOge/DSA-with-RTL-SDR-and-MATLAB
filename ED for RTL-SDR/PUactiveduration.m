% This code implements the energy detector design for -10dB SNR in the time
% domain for a maximum sensing time of 2 secs using as gain of 25dB with
% estimated noise power of -40.53dB

clc
clear
%% rtl-sdr initial config
% parameters (you can only change frequency for the same energy detector
% design) changing other parameters changes the design
rtlsdr_id           = '0';        %RTL-SDR ID
rtlsdr_freq         = 93.7e6;     %RTL-SDR tuner frequency in Hz
rtlsdr_gain         = 25;         %RTL-SDR tuner gain in dB
rtlsdr_fs           = 300e3;      %RTL-SDR sampling rate in Hz
rtlsdr_datatype     = 'single';   %RTL-SDR output data type
rtlsdr_frmsize      = 4096;       %RTL-SDR samples per frame
rtlsdr_ppm          = 0;        %RTL-SDR tuner PPM correction
niteration          = 146;    %number of Monte Carlo simulations
Pf                  = 0.01;     % probability of false alarm
% system objects
% rtl-sdr object
rtlsdr_obj = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency', rtlsdr_freq,... 
    'EnableTunerAGC', false,...
    'TunerGain', rtlsdr_gain,...
    'SampleRate', rtlsdr_fs, ...
    'SamplesPerFrame', rtlsdr_frmsize, ...
    'OutputDataType', rtlsdr_datatype,...
    'FrequencyCorrection', rtlsdr_ppm); 
% calculations
rtlsdr_frmtime = rtlsdr_frmsize/rtlsdr_fs;
% estimated noise power is -40.53dB
noise = wgn(rtlsdr_frmsize, 1, -40.53);
noise_power = var(noise);
% simulation
% checks
if isempty(sdrinfo(rtlsdr_obj.RadioAddress))
    error(['RTL-SDR failure. Please check that connection is establised'...
            'to MATLAB using "sdrinfo" command']);
end 
%% energy detector
stats_buff = int16.empty;
progress = 0;
duty_cycle = 0;
for i = 1:niteration 
    % fetch data from obj
    rtlsdr_data = rtlsdr_obj();
    N = length(rtlsdr_data);
    %the test statistics is    
    test_stats = sum(abs(rtlsdr_data).^2); 
    thres = (qfuncinv(Pf) + sqrt(N))*sqrt(N)*noise_power;
    %dectect PU presence
    if test_stats >= thres
        stats_buff(i) = 1;
        duty_cycle = duty_cycle +1;
    else
        stats_buff(i) = 0;
    end
    % show progress only if at an n10% value
    if floor(i*10/niteration) ~= progress
        progress = floor(i*10/niteration);
        str = ['    Please wait...', num2str(progress*10), '%'];
        disp(str);
    end
end
% for 10000 iterations of 4096 samples at 1MS/s
time = 0.001:2/niteration:2;
% compute duty cylce
duty_cycle = duty_cycle/niteration;
%% plot results
figure
plot(time,stats_buff, '-r', 'LineWidth', 2)
title(['PU activity of FM station ', num2str(rtlsdr_freq/1e6),...
    ' MHz for 2 seconds gives duty cycle of ', num2str(duty_cycle*100),'%'])
xlabel('time in seconds')
ylabel('PU activity')

% save figure
filename = ['FM_station_activity_', num2str(rtlsdr_freq/1e6),...
    '_MHz_duty_cycle_', num2str(duty_cycle*100), '%.fig'];
savefig(filename);
