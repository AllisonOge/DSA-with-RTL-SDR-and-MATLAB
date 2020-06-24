% Visualization of FM channel
% by Allison Ogechukwu
% Stop the program with |Ctrl| + |C| in the terminal window
clc
clear
% using time scope tool in dsp toolbox
% parameters
rtlsdr_id           = '0';        %RTL-SDR ID
rtlsdr_freq         = 97.3e6;     %RTL-SDR tuner frequency in Hz
rtlsdr_gain          = 25;         %RTL-SDR tuner gain in dB
rtlsdr_fs           = 902e3;      %RTL-SDR sampling rate in Hz
rtlsdr_datatype     = 'single';   %RTL-SDR output data type
rtlsdr_frmsize      = 4096;       %RTL-SDR samples per frame
rtlsdr_ppm          = 0;        %RTL-SDR tuner PPM correction
sim_time            = 60;         %simulation time in seconds
% calculations
rtlsdr_frmtime = rtlsdr_frmsize/rtlsdr_fs;
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
% time scope object
timeScope = dsp.TimeScope(...
    'NumInputPorts', 2,...
    'SampleRate', rtlsdr_fs,...
    'TimeSpan', (rtlsdr_frmtime/rtlsdr_fs)*1e6,...
    'TimeDisplayOffset', [0 25/rtlsdr_fs],...
    'TimeSpanOverrunAction', 'Scroll');
% spectrum analyzer object
realSpecAnal = dsp.SpectrumAnalyzer(...
    'ViewType', 'Spectrum and Spectrogram',...
    'SampleRate', rtlsdr_fs,...
    'PlotAsTwoSidedSpectrum', false);
% filter object
fir_filter = dsp.FIRFilter('Numerator', fir1(50, 0.44,'low'));
% simulation
% checks
if isempty(sdrinfo(rtlsdr_obj.RadioAddress))
    error(['RTL-SDR failure. Please check that connection is establised'...
            'to MATLAB using "sdrinfo" command']);
end 

run_time = 0;
update = 0;

while run_time < sim_time
   rtlsdr_data = rtlsdr_obj();
   rtlsdr_real = real(rtlsdr_data);
   % pass data through filter
   rtlsdr_filtered = fir_filter(rtlsdr_data);
   rtlfilt_real = real(rtlsdr_filtered);
   % pass data to time scope
   timeScope(rtlsdr_real, rtlfilt_real);
   % pass data to spectrum analyzer
   realSpecAnal(rtlsdr_real);
   run_time = run_time + rtlsdr_frmtime;
   update = update + 1;
end