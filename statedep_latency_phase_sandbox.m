function statedep_latency_phase_sandbox
% restoredefaultpath;

if isunix
    addpath(genpath('/Users/jericcarmichael/Documents/GitHub/vandermeerlab/code-matlab/shared'));
    addpath('/Users/jericcarmichael/Documents/GitHub/EC_state/Basic_functions');
    
    all_fig_dir = '/Volumes/Fenrir/State_dep/all_checks/';
    all_ccf_dir = '/Volumes/Fenrir/State_dep/all_ccf/';
    
    
else
    %     addpath(genpath('C:\Users\mvdm\Documents\GitHub\vandermeerlab\code-matlab\shared'));
    addpath(genpath('D:\Users\mvdmlab\My_Documents\GitHub\vandermeerlab\code-matlab\shared'));
    %addpath(genpath('D:\My_Documents\GitHub\vandermeerlab\code-matlab\shared'));
    %     addpath('C:\Users\mvdm\Documents\GitHub\EC_state\Basic_functions');
    addpath(genpath('D:\Users\mvdmlab\My_Documents\GitHub\EC_State'))
    %addpath('D:\My_Documents\GitHub\EC_state\Basic_functions');
    all_fig_dir = 'G:\State_data\all_checks\';
    all_ccf_dir = 'G:\State_data\all_ccf\';
    
    %     %cd('D:\data\EC_state\M14_2018-12-01_vStr_light_min');
    %     cd('C:\data\state-dep\M14_2018-12-01_vStr_light_min');
    %     %cd('D:\data\EC_state\M13-2018-12-05_dStr_2p2_light_min');
    %     cd('C:\data\state-dep\M13-2018-12-05_dStr_2p2_light_min');
    
end

mkdir(all_ccf_dir); mkdir(all_fig_dir);
%% defaults
font_size = 18;
LoadExpKeys
%% load CSC
cfg = [];
%cfg.decimateByFactor = 30;
cfg.fc = {ExpKeys.goodCSC};
this_csc = LoadCSC(cfg);
Fs = 1 ./ median(diff(this_csc.tvec));

%% load events
cfg = [];
cfg.eventList = {ExpKeys.laser_on};
cfg.eventLabel = {'laser on'};
laser_on = LoadEvents(cfg);

cfg = [];
cfg.eventList = {'Starting Recording', 'Stopping Recording'};
cfg.eventLabel = {'start', 'stop'};
start_stop = LoadEvents(cfg);

% find the longest recording
for ii = 1:length(start_stop.t{1})
    rec_times(ii) = start_stop.t{2}(ii)-start_stop.t{1}(ii);
end
[duration, main_rec_idx] = max(rec_times);
disp(['Longest Recording interval is ' num2str(duration/60) ' minutes in recording slot number ' num2str(main_rec_idx)])


laser_on = restrict(laser_on, start_stop.t{1}(main_rec_idx), start_stop.t{2}(main_rec_idx));

% check number of pulses.
if length(laser_on.t{1}) ~= 1000 && length(laser_on.t{1}) ~= 600
    warning('Wrong number of laser pulses. %0.2f when it should be 1000 or in early sessions 600',length(laser_on.t{1}))
    
end

%% load spikes
cfg = []; cfg.getTTnumbers = 0;
S = LoadSpikes(cfg);

%% select a cell
for iC = 1:length(S.label)
    
    %pick this cell
    this_S = SelectTS([], S, iC);
    cell_id = this_S.label{1}(1:end-2);
    cell_id = strrep(cell_id, '_SS', '');
    
    if strcmpi(this_S.label{1}(end-4:end-2), 'Art') % don't bother processing artifacts
        continue
    end
    %% get some LFP phases (filtfilt)
    f_list = {[3 5], [6.5 9.5],[15 25], [30 40],[40 60], [60 80]};
    f_list_label = {'3 - 5', '6.5 - 9.5', '15 - 25', '30 - 40', '40 - 60', '60 - 80'};
    nShuf = 100;
    
    for iF = 1:length(f_list) % loop across freqs
        %%  filter & hilbertize
        cfg_filt = []; cfg_filt.type = 'fdesign'; cfg_filt.f  = f_list{iF};
        csc_f = FilterLFP(cfg_filt, this_csc);
        
        % get the phase
        csc_f.data = angle(hilbert(csc_f.data));
        
        % get phase for each laser stim (actual)
        stim_phase_idx = nearest_idx3(laser_on.t{1}, csc_f.tvec);
        stim_phase = csc_f.data(stim_phase_idx);
        
        %same but for shuffle
        for iS = nShuf:-1:1
            
            csc_shuf = csc_f;
            if strcmp(version('-release'), '2014b') % version differences in how circshift is handled.
                csc_shuf.data = circshift(csc_shuf.data, round(rand(1) .* 0.5*length(csc_shuf.data)), 2);
            else
                csc_shuf.data = circshift(csc_shuf.data, round(rand(1) .* 0.5*length(csc_shuf.data)));
            end
            stim_phase_idx = nearest_idx3(laser_on.t{1}, csc_shuf.tvec);
            stim_phase_shuf(iS, :) = csc_shuf.data(stim_phase_idx);
        end % of shuffles
        
        
        %% convert to histogram of spikes relative to laser onset (based on ccf function by MvdM
        cfg_ccf =[];
        cfg_ccf.smooth = 0; % get raw values
        cfg_ccf.binsize = 0.0001;
        cfg_ccf.max_t = 0.015;
        %         [ccf_raw, tvec] = ccf(cfg_ccf, laser_on.t{1}, this_S.t{1});
        
        xbin_centers = -cfg_ccf.max_t-cfg_ccf.binsize:cfg_ccf.binsize:cfg_ccf.max_t+cfg_ccf.binsize; % first and last bins are to be deleted later
        this_ccf = zeros(size(xbin_centers));
        
        for iEvt = 1:length(laser_on.t{1})
            
            relative_spk_t = this_S.t{1} - laser_on.t{1}(iEvt);
            
            this_ccf = this_ccf + hist(relative_spk_t,xbin_centers); % note that histc puts all spikes outside the bin centers in the first and last bins! delete later.
            
            % get the latancy
            all_lat(iEvt) = this_S.t{1}(nearest_idx3(laser_on.t{1}(iEvt), this_S.t{1}, 1)) - laser_on.t{1}(iEvt);
            
        end
        
        this_ccf = this_ccf(2:end-1); % correct for everything being lumped into the first and last bins
        tvec = xbin_centers(2:end-1); % remove unwanted bins
        
        %         zero_idx = find(tvec == 0);
        %         % align to zero
        %         this_ccf = this_ccf(zero_idx:end);
        %         tvec = tvec(zero_idx:end);
        
        
        
        %% verison with phase bin loops
        n_phases = 5;
        fprintf('\nPhase split into %1d bins\n', n_phases)
        [~, edges, ~] = histcounts(-pi:pi, n_phases, 'BinLimits', [-pi, pi]);
        all_lat = NaN(n_phases,length(laser_on.t{1}));
        shuf_lat  = NaN(nShuf, length(laser_on.t{1}), n_phases);
        all_phase_labels = NaN(1,length(laser_on.t{1}));
        
        for iPhase = 1:n_phases
            [vals, this_phase_idx] = find(stim_phase > edges(iPhase) & stim_phase < edges(iPhase+1));
            N_stims{iF} = sum(vals);
            
            all_phase_labels(this_phase_idx) = iPhase;
            
            phase_inter_vals{iPhase} = linspace(edges(iPhase), edges(iPhase+1));
            
            for iEvt = this_phase_idx
                all_lat(iPhase, iEvt) = this_S.t{1}(nearest_idx3(laser_on.t{1}(iEvt), this_S.t{1}, 1)) - laser_on.t{1}(iEvt);
                if all_lat(iPhase, iEvt) >cfg_ccf.max_t
                    all_lat(iPhase, iEvt) = NaN;
                end
            end
            phase_labels{iPhase} = ['p' num2str(iPhase)];
            
            % get shuffle for each phase
            for iS = nShuf:-1:1
                [vals, this_phase_idx] = find(stim_phase_shuf(iS,:) > edges(iPhase) & stim_phase_shuf(iS,:) < edges(iPhase+1));
                
                for iEvt = this_phase_idx
                    shuf_lat(iS, iEvt, iPhase) = this_S.t{1}(nearest_idx3(laser_on.t{1}(iEvt), this_S.t{1}, 1)) - laser_on.t{1}(iEvt);
                    if shuf_lat(iS, iEvt, iPhase) >cfg_ccf.max_t
                        shuf_lat(iS, iEvt, iPhase) = NaN;
                    end
                end
            end
        end
        
        
        %         % get random
        %         for iS = nShuf:-1:1
        %             iPhase = randperm(1:n_phases,1);
        %             this_phase_idx = find(stim_phase_shuf(iS,:) > edges(iPhase) & stim_phase_shuf(iS,:) < edges(iPhase+1));
        %             %         ran_IVs = datasample(ceil(laser_on.t{1}(1)):floor(laser_on.t{1}(end)), length(laser_on.t{1}));
        %
        %             for iEvt = this_phase_idx
        %                 all_lat_shuf( iEvt, iS) = this_S.t{1}(nearest_idx3(laser_on.t{1}(iEvt), this_S.t{1}, 1)) - laser_on.t{1}(iEvt);
        %                 if all_lat_shuf(iEvt, iS) >cfg_ccf.max_t
        %                     all_lat_shuf(iEvt, iS) = NaN;
        %                 end
        %             end
        %         end
        %% center on the 'main peak'
        n_drops = zeros(size(all_lat));

        for iPhase = 1:n_phases
            bin_counts = histc(all_lat(iPhase,:),xbin_centers);
            [~,peak_idx] = max(bin_counts);
            this_peak_time{iPhase}  =[(xbin_centers(peak_idx)-0.001), (xbin_centers(peak_idx)+0.001)];
            
            for iEvt = 1:length(all_lat(iPhase,:))
                if isnan(all_lat(iPhase, iEvt))
                    continue
                else
                    if all_lat(iPhase, iEvt) > (xbin_centers(peak_idx)+0.001) || all_lat(iPhase, iEvt) < (xbin_centers(peak_idx)-0.001)
                        n_drops(iPhase, iEvt) = 1;
                        all_lat(iPhase, iEvt) = NaN;
                    end
                end
            end
            fprintf('\n %.1f events dropped in phase #', sum(n_drops(iPhase,:)))
            
            % same for shuffle
            for iS = nShuf:-1:1
                for iEvt = 1:length(shuf_lat(iS,:,iPhase))
                    if isnan(shuf_lat(iS,iEvt,iPhase))
                        continue
                    else
                        if shuf_lat(iS,iEvt,iPhase) > (xbin_centers(peak_idx)+0.001) || shuf_lat(iS,iEvt,iPhase) < (xbin_centers(peak_idx)-0.001)
                            shuf_lat(iS,iEvt,iPhase) = NaN;
                        end
                    end
                end
            end
            
        end
        
        
                %% get the stats for the shuffles
        
        all_shuf_mean = nanmean(reshape(shuf_lat, 1, numel(shuf_lat)));
        all_shuf_std = nanstd(reshape(shuf_lat, 1, numel(shuf_lat)));
        
        for iPhase = 1:n_phases
            this_shuf = shuf_lat(:,:,iPhase);
            all_shuf_phase_mean(iPhase) = nanmean(reshape(this_shuf, 1, numel(this_shuf)));
            all_shuf_phase_std(iPhase) = nanstd(reshape(this_shuf, 1, numel(this_shuf)));
            
        end
                
        %% convert daata to ms
        all_lat = all_lat*1000;
        all_shuf_mean = all_shuf_mean*1000;
        all_shuf_std = all_shuf_std*1000;
        xbin_centers = xbin_centers*1000;
        %% make a figure
        figure(1);
        c_ord = linspecer(n_phases);
        
        % try to make a colored sine wave to match the phases.
        subplot(4, ceil(n_phases/2), 1)
        hold on
        x = -pi:pi/(50*n_phases):pi;
        wave_phase = sin(x);
        for iPhase = 1:n_phases
            
            plot(-99+(100*iPhase):(100*iPhase), wave_phase(-99+(100*iPhase):(100*iPhase)), 'color', c_ord(iPhase,:), 'linewidth', 5)
            
        end
        axis off
        title(sprintf('%.1f to %.1f Hz', f_list{iF}(1), f_list{iF}(2)), 'fontsize', font_size)
        
        
        subplot(4, ceil(n_phases/2), [n_phases+2  4*ceil(n_phases/2)])
        hold on
        he = errorbar(0, all_shuf_mean, 2*all_shuf_std, 'o','color', 'k','MarkerFaceColor', 'k', 'markersize', 10);
        
        for iPhase = 1:n_phases
            subplot(4, ceil(n_phases/2), iPhase+1)
            h = histogram(all_lat(iPhase,:), xbin_centers);
            h.FaceColor = c_ord(iPhase,:);
            h.EdgeColor = c_ord(iPhase,:);
            ylim([0 20])
            xlim(this_peak_time{iPhase}*1000)
            xlabel('latency (ms)')
            %             title(sprintf('N stims: %.1f', N_stims{iPhase}), 'fontsize', font_size)
            %             legend boxoff
            set(gca, 'fontsize', font_size)
            
            
            
            subplot(4, ceil(n_phases/2), [n_phases+2  4*ceil(n_phases/2)])
            hold on
            he = errorbar(iPhase, nanmean(all_lat(iPhase,:), 2), 2*nanstd(all_lat(iPhase,:), 0,2), 'o', 'color', c_ord(iPhase,:),'MarkerFaceColor', c_ord(iPhase,:), 'markersize', 10);
            set(gca, 'fontsize', font_size);
            xlabel('Phase')
            xlim([-0.5 n_phases+0.5])
            ylabel('Mean latency (ms)')
            set(gca, 'xticklabel', ['shuf' phase_labels])
        end
        
        SetFigure([], gcf)
        set(gcf, 'position', [435, 50, 949, 697]);
        
        ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
        text(0.35, 0.98,[ExpKeys.subject '_' ExpKeys.date '  Cell ' cell_id], 'fontsize', font_size)
        saveas(gcf, [all_fig_dir ExpKeys.subject '_' ExpKeys.date '_' cell_id(1:end-3) '_f' num2str(floor(f_list{iF}(1))) '_' num2str(floor(f_list{iF}(2))) '_latency.png']);
        saveas_eps([ExpKeys.subject '_' ExpKeys.date '_' cell_id(1:end-3) '_f' num2str(floor(f_list{iF}(1))) '_' num2str(floor(f_list{iF}(2))) '_latency'], all_fig_dir)
        
                close all
    end % end freq loop
    
end % end cell loop

end % end of function
