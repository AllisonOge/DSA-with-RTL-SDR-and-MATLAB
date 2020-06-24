%%
% This code implements a FM demodulator using complex delay line non-coherent
% demodulator and demultiplex the stereo signal in the FM MPX
% code by Allison Ogechukwu
%%

% initialization variables
clear
clc
% parameters
rtlsdr_id           = '0';          %RTL-SDR ID
rtlsdr_freq         = 92.3e6;       %RTL-SDR tuner frequency in Hz
rtlsdr_gain         = 20;           %RTL-SDR tuner gain in dB
rtlsdr_fs           = 1e6;          %RTL-SDR sampling rate in Hz
rtlsdr_datatype     = 'single';     %RTL-SDR output data type
rtlsdr_frmsize      = 256*25*5*6;   %RTL-SDR samples per frame
rtlsdr_ppm          = 0;            %RTL-SDR tuner PPM correction
audio_rate          = 48e3;         % sample rate of audio player
sim_time            = 60;


% system objects
% rtlsdr
rtlsdr = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency', rtlsdr_freq,... 
    'EnableTunerAGC', false,...
    'TunerGain', rtlsdr_gain,...
    'SampleRate', rtlsdr_fs, ...
    'SamplesPerFrame', rtlsdr_frmsize, ...
    'OutputDataType', rtlsdr_datatype,...
    'FrequencyCorrection', rtlsdr_ppm);

% delay object
delay_block = dsp.Delay();

% spectrum analyzer
SA = dsp.SpectrumAnalyzer(...
    'Name', 'Spectrum plot of Received Signal',...
    'Title', 'Spectrum plot of Received Signal',...
    'SampleRate', rtlsdr_fs,...
    'SpectrumType', 'Power density',...
    'FrequencySpan', 'span and center frequency');
% SA decimated
SA_decr = dsp.SpectrumAnalyzer(...
    'Name', 'Spectrum plot of MPX signal',...
    'Title', 'Spectrum plot of MPX signal',...
    'SampleRate', rtlsdr_fs/5,...
    'PlotAsTwoSidedSpectrum', false);

% SA audio
SA_audio = dsp.SpectrumAnalyzer(...
    'Name', 'Audio signal',...
    'Title', 'Audio signal',...
    'SampleRate', audio_rate,...
    'PlotAsTwoSidedSpectrum', false);

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

% audio save
audio_save = dsp.AudioFileWriter('audio_file.wav','SampleRate', audio_rate);

% calculations
rtlsdr_frmtime = rtlsdr_frmsize/rtlsdr_fs;


% simulation
% checks
if isempty(sdrinfo(rtlsdr.RadioAddress))
    error(['RTL-SDR failure. Please check that connection is establised'...
            'to MATLAB using "sdrinfo" command']);
end 
runtime = 0;
while runtime < sim_time    % run program within 60 seconds
        
    % non-coherent demodulator
    rtl_sig = rtlsdr();     % extract length of samples
    
    % visualize rtl signal
    SA(rtl_sig);
    rtl_sig_delay = delay_block(rtl_sig); % delay by one sample
    rtl_conj = conj(rtl_sig);   % obtain the conjugate of the samples
    mixer_out = rtl_sig_delay .* rtl_conj;  % mix respective outputs
    arg = angle(mixer_out);     % obtain angle
    arg = arg - mean(arg);      % remove dc
    
    signal_mpx = decimate_block(arg);

    %visualize mpx signal
    SA_decr(signal_mpx);
    
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
    
    % visualize audio
    SA_audio(audio_left_48k);
    
    % save in file
    audio_save(audio_left_48k);
    
    runtime = runtime + rtlsdr_frmtime + nstep;
end