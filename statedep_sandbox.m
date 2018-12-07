%%
restoredefaultpath;
addpath(genpath('C:\Users\mvdm\Documents\GitHub\vandermeerlab\code-matlab\shared'));

cd('C:\data\state-dep\M14_2018-12-01_vStr_light_min');
%%
cfg = [];
cfg.decimateByFactor = 30;
this_csc = LoadCSC(cfg);
Fs = 1 ./ median(diff(this_csc.tvec));

%%
cfg = [];
cfg.eventList = {'TTL Input on AcqSystem1_0 board 0 port 2 value (0x000A).'}; 
cfg.eventLabel = {'laser on'};
laser_on = LoadEvents(cfg);

cfg = [];
cfg.eventList = {'Starting Recording', 'Stopping Recording'};
cfg.eventLabel = {'start', 'stop'};
start_stop = LoadEvents(cfg);

laser_on = restrict(laser_on, start_stop.t{1}(4), start_stop.t{2}(4)); % need to automate what is right epoch to get

%%
cfg = [];
cfg.getTTnumbers = 0;
S = LoadSpikes(cfg);

%% make psd
wSize = 1024;
[Pxx,F] = pwelch(this_csc.data, rectwin(wSize), wSize/2, [], Fs);

figure;
plot(F, 10*log10(Pxx));
set(gca, 'XLim', [0 150]);

%% 
cfg = [];
cfg.binsize = 0.0005;
cfg.max_t = 0.02;

this_S = SelectTS([], S, 2);
[this_ccf, tvec] = ccf(cfg, this_S.t{1}, laser_on.t{1});
this_ccf = this_ccf ./ length(laser_on.t{1});

figure;
subplot(321);
plot(tvec, this_ccf, 'k', 'LineWidth', 2); title(sprintf('all stim PETH %s', this_S.label{1}));
set(gca, 'FontSize', fs); xlabel('time (s)'); ylabel('spike count');


%% get some LFP phases 
fs = 18;
f_list = {[3 5], [6.5 9.5], [30 40], [60 80]};

for iF = 1:length(f_list) % loop across freqs
   
    % filter & hilbertize
    cfg_filt = []; cfg_filt.type = 'fdesign'; cfg_filt.f  = f_list{iF};
    csc_f = FilterLFP(cfg_filt, this_csc);
    
    csc_f.data = angle(hilbert(csc_f.data));
    
    % get phase for each laser stim
    stim_phase_idx = nearest_idx3(laser_on.t{1}, csc_f.tvec);
    stim_phase = csc_f.data(stim_phase_idx);
    
    subplot(322); 
    % STIM PHASE HISTO THIS IS IMPORTANT
    %hist(stim_phase, 36); title(sprintf('stim phase histo (%d-%d Hz)', f_list{iF}(1), f_list{iF}(2)));
    plot(F, 10*log10(Pxx));
    set(gca, 'XLim', [0 150], 'FontSize', 18); grid on;

    
    set(gca, 'FontSize', fs);
    
    for iP = 1 % loop across some phase splits
    
        phase_low_idx = find(stim_phase < 0);
        phase_high_idx = find(stim_phase >= 0);
        
        [this_ccf_low, tvec] = ccf(cfg, this_S.t{1}, laser_on.t{1}(phase_low_idx));
        this_ccf_low = this_ccf_low ./ length(laser_on.t{1}(phase_low_idx));
        [this_ccf_high, tvec] = ccf(cfg, this_S.t{1}, laser_on.t{1}(phase_high_idx));
        this_ccf_high = this_ccf_high ./ length(laser_on.t{1}(phase_high_idx));
        
        subplot(3, 2, 2 + iF);
        h(1) = plot(tvec, this_ccf_low, 'b', 'LineWidth', 2); hold on;
        h(2) = plot(tvec, this_ccf_high, 'r', 'LineWidth', 2);
        
        legend(h, {'phase < 0', 'phase >= 0'}, 'Location', 'Northwest'); legend boxoff;
        set(gca, 'FontSize', fs); xlabel('time (s)'); ylabel('spike count');
        title(sprintf('phase split %d-%d Hz', f_list{iF}(1), f_list{iF}(2)));
    
    end
    
end % of freq loop