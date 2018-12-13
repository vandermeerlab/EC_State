%%
restoredefaultpath;
addpath(genpath('C:\Users\mvdm\Documents\GitHub\vandermeerlab\code-matlab\shared'));
%addpath(genpath('D:\My_Documents\GitHub\vandermeerlab\code-matlab\shared'));
addpath('C:\Users\mvdm\Documents\GitHub\EC_state\Basic_functions');
%addpath('D:\My_Documents\GitHub\EC_state\Basic_functions');

%cd('D:\data\EC_state\M14_2018-12-01_vStr_light_min');
cd('C:\data\state-dep\M14_2018-12-01_vStr_light_min');
%cd('D:\data\EC_state\M13-2018-12-05_dStr_2p2_light_min');
cd('C:\data\state-dep\M13-2018-12-05_dStr_2p2_light_min');
%% load CSC
cfg = [];
cfg.decimateByFactor = 30;
this_csc = LoadCSC(cfg);
Fs = 1 ./ median(diff(this_csc.tvec));

%% load events
cfg = [];
cfg.eventList = {'TTL Input on AcqSystem1_0 board 0 port 2 value (0x000A).'}; 
cfg.eventLabel = {'laser on'};
laser_on = LoadEvents(cfg);

cfg = [];
cfg.eventList = {'Starting Recording', 'Stopping Recording'};
cfg.eventLabel = {'start', 'stop'};
start_stop = LoadEvents(cfg);

laser_on = restrict(laser_on, start_stop.t{1}(4), start_stop.t{2}(4)); % need to automate what is right epoch to get

%% inspect stim artifact
this_stim_binned = zeros(size(this_csc.tvec));
idx = nearest_idx3(laser_on.t{1}, this_csc.tvec);
this_spk_binned(idx) = 1;
[xc, tvec] = xcorr(this_csc.data, this_spk_binned, 500);
tvec = tvec ./ Fs;

figure;
plot(tvec, xc, 'k', 'LineWidth', 2);


%% load spikes
cfg = []; cfg.getTTnumbers = 0;
S = LoadSpikes(cfg);

%% make psd
wSize = 1024;
[Pxx,F] = pwelch(this_csc.data, rectwin(wSize), wSize/2, [], Fs);

%% select a cell
iC = 2;
this_S = SelectTS([], S, iC);

%% overall PETH
cfg = [];
cfg.binsize = 0.0005;
cfg.max_t = 0.02;
[this_ccf, tvec] = ccf(cfg, laser_on.t{1}, this_S.t{1});

figure(1);
subplot(321);
plot(tvec, this_ccf, 'k', 'LineWidth', 2); h = title(sprintf('all stim PETH %s', this_S.label{1})); set(h, 'Interpreter', 'none');
set(gca, 'FontSize', fs); xlabel('time (s)'); ylabel('spike count');

%% get some LFP phases (filtfilt)
fs = 18;
f_list = {[3 5], [6.5 9.5], [30 40], [60 80]};
nShuf = 100;

for iF = 1:length(f_list) % loop across freqs
   
    % filter & hilbertize
    cfg_filt = []; cfg_filt.type = 'fdesign'; cfg_filt.f  = f_list{iF};
    csc_f = FilterLFP(cfg_filt, this_csc);
    
    %%% SHUFFLE WOULD DO SOME KIND OF RANDOM CIRCSHIFT HERE %%%
    
    csc_f.data = angle(hilbert(csc_f.data));
    
    for iS = nShuf:-1:1
        
        csc_shuf = csc_f;
        csc_shuf.data = circshift(csc_shuf.data, round(rand(1) .* 0.5*length(csc_shuf.data)));
        
        stim_phase_idx = nearest_idx3(laser_on.t{1}, csc_shuf.tvec);
        stim_phase_shuf(iS, :) = csc_shuf.data(stim_phase_idx);
        
    end % of shuffles
    
    % get phase for each laser stim (actual)
    stim_phase_idx = nearest_idx3(laser_on.t{1}, csc_f.tvec);
    stim_phase = csc_f.data(stim_phase_idx);
    
    % STIM PHASE HISTO THIS IS IMPORTANT
    figure(2); subplot(2, 2, iF);
    hist(stim_phase, 36); title(sprintf('stim phase histo (%.1f-%.1f Hz)', f_list{iF}(1), f_list{iF}(2)));
    
    figure(1)
    subplot(322); 
    plot(F, 10*log10(Pxx), 'k', 'LineWidth', 2);
    set(gca, 'XLim', [0 150], 'FontSize', fs); grid on;
    xlabel('Frequency (Hz)');
    
    % example phase split
    phase_low_idx = find(stim_phase < 0);
    phase_high_idx = find(stim_phase >= 0);
    
    [this_ccf_low, tvec] = ccf(cfg, laser_on.t{1}(phase_low_idx), this_S.t{1});
    [this_ccf_high, ~] = ccf(cfg, laser_on.t{1}(phase_high_idx), this_S.t{1});
    
    % same for shuffles
    for iS = nShuf:-1:1
        
        phase_low_idx = find(stim_phase_shuf(iS,:) < 0);
        phase_high_idx = find(stim_phase_shuf(iS,:) >= 0);
        
        [ccf_low_shuf(iS,:), ~] = ccf(cfg, laser_on.t{1}(phase_low_idx), this_S.t{1});
        [ccf_high_shuf(iS,:), ~] = ccf(cfg, laser_on.t{1}(phase_high_idx), this_S.t{1});
        
    end % of shuffles
    
    figure(1);
    subplot(3, 2, 2 + iF);
    h(1) = plot(tvec, this_ccf_low, 'b', 'LineWidth', 2); hold on;
    h(2) = plot(tvec, this_ccf_high, 'r', 'LineWidth', 2);
    
    plot(tvec, nanmean(ccf_low_shuf), 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    plot(tvec, nanmean(ccf_low_shuf) + 1.96*nanstd(ccf_low_shuf), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    plot(tvec, nanmean(ccf_low_shuf) - 1.96*nanstd(ccf_low_shuf), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    
    legend(h, {'phase < 0', 'phase >= 0'}, 'Location', 'Northwest'); legend boxoff;
    set(gca, 'FontSize', fs); xlabel('time (s)'); ylabel('spike count');
    title(sprintf('phase split %.1f-%.1f Hz', f_list{iF}(1), f_list{iF}(2)));
        
    figure(3);
    subplot(3, 2, 2 + iF);
    plot(tvec, this_ccf_low - this_ccf_high, 'g', 'LineWidth', 2); hold on;
 
    plot(tvec, nanmean(ccf_low_shuf - ccf_high_shuf), 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    plot(tvec, nanmean(ccf_low_shuf - ccf_high_shuf) + 1.96*nanstd(ccf_low_shuf - ccf_high_shuf), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    plot(tvec, nanmean(ccf_low_shuf - ccf_high_shuf) - 1.96*nanstd(ccf_low_shuf - ccf_high_shuf), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
    
    set(gca, 'FontSize', fs); xlabel('time (s)'); ylabel('spike count');
    title(sprintf('phase split diff %.1f-%.1f Hz', f_list{iF}(1), f_list{iF}(2)));
    
end % of freq loop