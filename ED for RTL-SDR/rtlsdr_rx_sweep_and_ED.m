%RTL-SDR Spectrum Sweep and Energy detector
% - You can use this script to sweep and record the RF spectrum with your
%   RTL-SDR as well as compare results with a energy detector design
% - Change the "location" parameter (line 22) to something that identifies
%   your location, eg Benin City
% - You may change range that the RTL-SDR will sweep over by changing the
%   values of "start_freq" and "stop_freq" (lines 23 and 24) however this
%   project was designed for the FM spectrum
% - If you wish, you can also change the RLT-SDR sampling rate by changing
%   "rtlsdr_fs", and the tuner gain by modifying "rtlsdr_gain" (lines 26
%   and 27)
% - At the end of the simulation, the recorded data and the detector stats 
%   will be processed and plotted in a popup figure
% - This figure will be saved to the MATLAB 'current folder' for later
%   viewing
% - NOTE: to end simulation early, use |Ctrl| + |C|

function rtlsdr_rx_sweep_and_ED

% PARAMETERS (can change)
location            = 'Benin City';    % location used for figure name
start_freq          = 87.5e6;         % sweep start frequency
stop_freq           = 108e6;       % sweep stop frequency
rtlsdr_id           = '0';          % RTL-SDR stick ID
rtlsdr_fs           = 300e3;        % RTL-SDR sampling rate in Hz
rtlsdr_gain         = 25;           % RTL-SDR tuner gain in dB
rtlsdr_frmlen       = 4096;         % RTL-SDR output data frame size
rtlsdr_datatype     = 'single';     % RTL-SDR output data type
rtlsdr_ppm          = 0;            % RTL-SDR tuner parts per million correction
% PARAMETERS (can change, but may break code)
nfrmhold            = 30;           % number of frames to receive
fft_hold            = 'avg';        % hold function "max" or "avg"
nfft                = 1024;         % number of points in FFTs (2^something)
dec_factor          = 16;           % output plot downsample
overlap             = 0.5;          % FFT overlap to counter rolloff
nfrmdump            = 100;          % number of frames to dump after retuning (to clear buffer)
Pf                  = 0.01;         % probability of false alarm

% CALCULATIONS
rtlsdr_tunerfreq  = start_freq:rtlsdr_fs*overlap:stop_freq;     % range of tuner frequency in Hz
if( max(rtlsdr_tunerfreq) < stop_freq )                         % check the whole range is covered, if not, add an extra tuner freq
    rtlsdr_tunerfreq(length(rtlsdr_tunerfreq)+1) = max(rtlsdr_tunerfreq)+rtlsdr_fs*overlap;
end
nretunes = length(rtlsdr_tunerfreq);                            % calculate number of retunes required
freq_bin_width = (rtlsdr_fs/nfft);                              % create xaxis
freq_axis = (rtlsdr_tunerfreq(1)-rtlsdr_fs/2*overlap  :  freq_bin_width*dec_factor  :  (rtlsdr_tunerfreq(end)+rtlsdr_fs/2*overlap)-freq_bin_width)/1e6;
stats_buff          = zeros(nfrmhold, 1);                       % buffer for decision stats from ED
desc_stats = zeros(nretunes,nfft*overlap/dec_factor);           % store zeros in decision stats

% create spectrum figure
h_spectrum = create_spectrum;

% run capture and plot
capture_and_plot;

% make spectrum visible
h_spectrum.fig.Visible = 'on';

% save data
filename = ['rtlsdr_rx_specsweep_and_ed_6_',num2str(start_freq/1e6),'MHz_',num2str(stop_freq/1e6),'MHz_',location,'.fig'];
savefig(filename);


%% FUNCTION to create spectrum window
    function h_spectrum = create_spectrum
        
        % colours
        h_spectrum.line_blue = [0.0000 0.4470 0.7410];      % spectrum analyzer blue
        h_spectrum.line_orange = [1.0000 0.5490 0.0000];    % spectrum analyzer orange
        h_spectrum.window_grey = [0.95 0.95 0.95];          % background light grey
        h_spectrum.axes_grey = [0.1 0.1 0.1];               % dark grey for axes titles etc
        h_spectrum.plot_white = [1 1 1];                    % white for plot background
        
        % sizes
        fig_w = 1200;
        fig_h = 600;
        scnsize = get(0,'ScreenSize');                      % find monitor 1 size
        if scnsize(3) < fig_w                               % if monitor is not fig_w wide
            fig_w = scnsize(3);                             % reduce fig_w
        end
        if scnsize(4) < fig_h                               % if monitor is not fig_h tall
            fig_h = scnsize(h);                             % reduce fig_h
        end
        fig_pos = [(scnsize(3)-fig_w)/2 (scnsize(4)-fig_h)/2 fig_w fig_h];   % set to open in middle of monitor 1
        
        % create new figure
        h_spectrum.fig = figure(...
            'Color',h_spectrum.window_grey,...
            'Position',fig_pos,...
            'SizeChangedFcn',@resize_spectrum,...
            'Name',['RTL-SDR Spectrum Sweep: ',location],...
            'Visible', 'off');
        h_spectrum.fig.Renderer = 'painters';
        
        % subplot 1
        h_spectrum.axes1 = axes(...
            'Parent',h_spectrum.fig,...
            'YGrid','on','YColor',h_spectrum.axes_grey,...
            'XGrid','on','XColor',h_spectrum.axes_grey,...
            'GridLineStyle','--',...
            'Color',h_spectrum.plot_white);
        box(h_spectrum.axes1,'on');
        hold(h_spectrum.axes1,'on');
        xlabel(h_spectrum.axes1,'Frequency (MHz)');
        ylabel(h_spectrum.axes1,'Power Ratio (dBm)  [relative to 50 \Omega load]  ');
        xlim(h_spectrum.axes1,[start_freq/1e6,stop_freq/1e6]);
        
        % subplot 2
        h_spectrum.axes2 = axes(...
            'Parent',h_spectrum.fig,...
            'YGrid','on','YColor',h_spectrum.axes_grey,...
            'XGrid','on','XColor',h_spectrum.axes_grey,...
            'GridLineStyle','--',...
            'Color',h_spectrum.plot_white);
        box(h_spectrum.axes2,'on');
        hold(h_spectrum.axes2,'on');
        xlabel(h_spectrum.axes2,'Frequency (MHz)');
        ylabel(h_spectrum.axes2,'PU Occupancy');
        xlim(h_spectrum.axes2,[start_freq/1e6,stop_freq/1e6]);
        
        % figure title
        title(h_spectrum.axes1,['RTL-SDR Spectrum Sweep and ED  ||   Range = ',num2str(start_freq/1e6),'MHz to ',...
            num2str(stop_freq/1e6),'MHz   ||   Bin Width = ',num2str(freq_bin_width*dec_factor/1e3),...
            'kHz   ||   Number of Bins = ',num2str(length(freq_axis)),'   ||   Number of Retunes = ',...
            num2str(nretunes)]);
        
        % position axes
        axes_position(fig_w,fig_h);
        
        % link plots together for zooming
        linkaxes([h_spectrum.axes1,h_spectrum.axes2],'x');
        
    end

%% FUNCTION to calculate axes positions
    function axes_position(fig_w,fig_h)
        
        h_spectrum.axes1.Position = [...        % dBm axes
            70/fig_w,...                        % 70px from left
            (fig_h/2)/fig_h,...                 % at centre line
            (fig_w-100)/fig_w,...               % 100px from right
            (fig_h/2-30)/fig_h];                % 80px from top
        
        h_spectrum.axes2.Position = [...        % Watts axes
            70/fig_w,...                        % 70px from left
            50/fig_h,...                        % 50px from bottom
            (fig_w-100)/fig_w,...               % 100px from right
            (fig_h/2-100)/fig_h];               % 100px below centre line
        
    end


%% FUNCTION (callback) to resize axes in spectrum window
    function resize_spectrum(hObject,callbackdata)
        
        % find current sizes
        fig_w = h_spectrum.fig.Position(3);
        fig_h = h_spectrum.fig.Position(4);
        
        % update axes positions
        axes_position(fig_w,fig_h);
        
    end


%% FUNCTION to capture data from the RTL-SDR and plot it
    function capture_and_plot
        
        % START TIMER
        tic;
        disp(' ');
        
        % SYSTEM OBJECTS
        % RTL-SDR system object
        obj_rtlsdr = comm.SDRRTLReceiver(...
            rtlsdr_id,...
            'CenterFrequency',      rtlsdr_tunerfreq(1),...
            'EnableTunerAGC', 		false,...
            'TunerGain', 			rtlsdr_gain,...
            'SampleRate',           rtlsdr_fs, ...
            'SamplesPerFrame', 		rtlsdr_frmlen,...
            'OutputDataType', 		rtlsdr_datatype ,...
            'FrequencyCorrection', 	rtlsdr_ppm );
        
        % FIR decimator
        obj_decmtr = dsp.FIRDecimator(...
            'DecimationFactor',     dec_factor,...
            'Numerator',            fir1(300,1/dec_factor));
        
        % CALCULATIONS (others)
        rtlsdr_data_fft = zeros(1,nfft);                     % fullsize matrix to hold calculated fft [1 x nfft]
        fft_reorder = zeros(length(nfrmhold),nfft*overlap);  % matrix with overlap compensation to hold re-ordered ffts [navg x nfft*overlap]
        fft_dec = zeros(nretunes,nfft*overlap/dec_factor);   % matrix with overlap compensation to hold all ffts  [ntune x nfft*overlap/data_decimate]
        
        % SIMULATION        
        % check if RTL-SDR is active
        if ~isempty(sdrinfo(obj_rtlsdr.RadioAddress))
        else
            error(['RTL-SDR failure. Please check connection to ',...
                'MATLAB using the "sdrinfo" command.']);
        end
        
        % create progress variable
        tune_progress = 0;
        
        % for each of the tuner values
        for ntune = 1:1:nretunes
            
            % tune RTL-SDR to new centre frequency
            obj_rtlsdr.CenterFrequency = rtlsdr_tunerfreq(ntune);
            
            % dump frames to clear software buffer
            for frm = 1:1:nfrmdump
                % fetch a frame from the rtlsdr stick
                rtlsdr_data = obj_rtlsdr();
            end
            
            %assume gaussian noise at -40.53dB, estimated noise power
            noise = wgn(rtlsdr_frmlen, 1, -40.53, 1);
            noise_power = var(noise);
            
            % display current centre frequency
            disp(['            fc = ',num2str(rtlsdr_tunerfreq(ntune)/1e6),'MHz']);
            
            disp('            fetching frame, detecting energy and holding a few frames...');
            % loop for nfrmhold frames
            for frm = 1:1:nfrmhold
                
                % fetch a frame from the rtlsdr stick
                rtlsdr_data = obj_rtlsdr();
                
                % remove DC component
                rtlsdr_data = (rtlsdr_data - mean(rtlsdr_data))';
                
                % find fft [ +ve , -ve ]
                rtlsdr_data_fft = abs(fft(rtlsdr_data, nfft));
                
                test_stats = sum(abs(rtlsdr_data).^2); % Test Statistic for the energy detection
  
                % compute threshold
                thres = (qfuncinv(Pf) + sqrt(rtlsdr_frmlen))*sqrt(rtlsdr_frmlen)*noise_power;
                
                % dectect PU presence
                if test_stats >= thres
                    stats_buff(frm) = 1;
                else
                    stats_buff(frm) = 0;
                end
                
                % rearrange fft [ -ve , +ve ] and neglect overlap data
                fft_reorder(frm,( 1 : (overlap*nfft/2) ))      = rtlsdr_data_fft( (overlap*nfft/2)+(nfft/2)+1 : end );   % -ve
                fft_reorder(frm,( (overlap*nfft/2)+1 : end ))  = rtlsdr_data_fft( 1 : (overlap*nfft/2) );                % +ve
                
            end
            
            disp('            converting frames to a frame...');
            % process the fft data down to [1 x nfft*overlap] from [nfrmhold x nfft*overlap]
            if strcmp(fft_hold,'avg')
                % if set to average, find mean
                fft_reorder_proc = mean(fft_reorder);
                
            elseif strcmp(fft_hold,'max')
                % if set to max order hold, find max
                fft_reorder_proc = max(fft_reorder);
                
            end
            
            disp('            averaging decision stats and comparing with 0.8...');
            % average decision stats and compare against .8
            stats_buff_avg = mean(stats_buff);
            if (stats_buff_avg > .8)
                desc_stats(ntune, :) = 1;
            else
                desc_stats(ntune, :) = 0;
            end
            
            % decimate data to smooth and store in spectrum matrix
            fft_dec(ntune,:) = obj_decmtr(fft_reorder_proc')';
            
            % show progress if at an n10% value
            if floor(ntune*10/nretunes) ~= tune_progress
                tune_progress = floor(ntune*10/nretunes);
                disp(['      progress = ',num2str(tune_progress*10),'%']);
            end
            
        end
        
        % REORDER INTO ONE MATRIX
        fft_masterreshape = reshape(fft_dec',1,ntune*nfft*overlap/dec_factor);
        descStats_masterreshape = reshape(desc_stats', 1, ntune*nfft*overlap/dec_factor);
        
        % PLOT DATA
        y_data = descStats_masterreshape;
        y_data_dbm = 10*log10((fft_masterreshape.^2)/50);
        plot(h_spectrum.axes1,freq_axis,y_data_dbm,'Color',h_spectrum.line_blue,'linewidth',1.25);
        plot(h_spectrum.axes2,freq_axis,y_data,'Color',h_spectrum.line_orange,'linewidth',1.25);
        
        % STOP TIMER
        disp(' ');
        disp(['      run time = ',num2str(toc),'s']);
        disp(' ');
        release(obj_rtlsdr)
        
    end
end