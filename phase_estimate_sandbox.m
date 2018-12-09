%% hilbert phase is accurate up to last sample of perfect sine wave
dt = 0.001;
tvec = 0:dt:2;

y = sin(2*pi*4*tvec);

plot(tvec, y); hold on;

phi = angle(hilbert(y));
plot(tvec, phi ./ pi, 'r');

%% what about some actual data? (note requires statedep_sandbox to have been run)
offs = 300; % plot some example stim events starting at this event number
for iE = 1:9

temp = restrict(this_csc, laser_on.t{1}(iE+offs)-2.5, laser_on.t{1}(iE+offs)+0.5);
this_idx = nearest_idx3(laser_on.t{1}(iE+offs), temp.tvec);

subplot(3, 3, iE);
plot(temp); hold on;
plot(temp.tvec(this_idx), temp.data(this_idx), '.k', 'MarkerSize', 10);
axis tight; box off;

end

%% idea: run forward filter up to time of stim to obtain phase estimate
fs = 18;
fpass_list = {[3 5], [7 9], [30 40], [65 80]};
fstop_list = {[2.5 5.5], [6 10], [28 42], [60 85]};

for iF = 1:length(f_list) % loop across freqs
   
    % set up filter
    cfg_filt = [];
    cfg_filt.fpass = fpass_list{iF};
    cfg_filt.fstop = fstop_list{iF};
    cfg_filt.debug = 1;
    
    stim_phase = FindPreStimPhase(cfg_filt, laser_on, this_csc);
    
    % STIM PHASE HISTO THIS IS IMPORTANT
    figure(2); subplot(2, 2, iF);
    hist(stim_phase, 36); title(sprintf('stim phase histo (%.1f-%.1f Hz)', f_list{iF}(1), f_list{iF}(2)));
    
    figure(1)
    subplot(322); 
    plot(F, 10*log10(Pxx), 'k', 'LineWidth', 2);
    set(gca, 'XLim', [0 150], 'FontSize', fs); grid on;
    xlabel('Frequency (Hz)');
    
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
        title(sprintf('phase split %.1f-%.1f Hz', f_list{iF}(1), f_list{iF}(2)));
    
    end
    
    drawnow;
    
end % of freq loop