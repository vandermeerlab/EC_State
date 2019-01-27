function statedep_summary
%% collect the outputs from statedep_all_phase_sandbox and statedep_latency_phase_sandbox
%
%
%

%% defaults

if isunix
    addpath(genpath('/Users/jericcarmichael/Documents/GitHub/vandermeerlab/code-matlab/shared'));
    addpath('/Users/jericcarmichael/Documents/GitHub/EC_state/Basic_functions');
    
    all_fig_dir = '/Volumes/Fenrir/State_dep/all_checks/';
    all_lat_dir = '/Volumes/Fenrir/State_dep/all_lat/';
    all_ccf_dir = '/Volumes/Fenrir/State_dep/all_ccf';
    summary_dir = '/Volumes/Fenrir/State_dep/Summary/';
else
    addpath(genpath('D:\Users\mvdmlab\My_Documents\GitHub\vandermeerlab\code-matlab\shared'));
    addpath(genpath('D:\Users\mvdmlab\My_Documents\GitHub\EC_State'))
    
    all_fig_dir = 'G:\State_data\all_checks\';
    all_lat_dir = 'G:\State_data\all_lat\';
    
end

mkdir(all_lat_dir); mkdir(all_fig_dir);
% list of manually approved cells
good_sess_list = {'M13_2018_12_09_TT1_05_OK',...
    'M13_2018_12_09_TT6_06_OK',...
    'M13_2018_12_09_TT8_01_OK',...
    'M13_2018_12_11_TT7_01_OK',...
    'M13_2018_12_11_TT7_02_OK',...
    'M13_2018_12_16_TT3_02_OK',...
    'M13_2018_12_17_TT2_02_Good',...
    'M14_2018_12_08_TT1_04_Good',...
    'M14_2018_12_09_TT8_02_OK',...
    'M14_2018_12_10_TT1_02_Good',...
    'M14_2018_12_10_TT2_01_Good',...
    'M14_2018_12_10_TT2_02_Good',...
    'M14_2018_12_15_TT1_03_OK',...
    'M14_2018_12_17_TT2_01_OK'};

font_size = 18;
%% generate a latency and count summary
cd(all_lat_dir);
sess_list = dir(all_lat_dir);
sess_list = sess_list(3:end);

for iSess = 1:length(sess_list)
    load(sess_list(iSess).name);
    
    these_cells = fieldnames(out);
    for iC = 1:length(these_cells)
        
        this_cell = these_cells{iC};
        if ismember([sess_list(iSess).name(1:14) '_' this_cell], good_sess_list) % check if this is a 'good' cell from above approvedd list
            
            freq_list = fieldnames(out.(this_cell));
            
            for iF = 1:length(freq_list)
                
                all_cells.(this_cell) = out.(this_cell);
                
            end
            % subject hdr
            all_cells.(this_cell).hdr.name = sess_list(iSess).name(1:14);
            all_cells.(this_cell).hdr.date = sess_list(iSess).name(5:14);
            all_cells.(this_cell).hdr.subject = sess_list(iSess).name(1:3);
        end
        
    end
    
end

%%
cell_list = fieldnames(all_cells);
all_lat =[];
all_count = [];
for iC = 1:length(cell_list)
    this_cell = cell_list{iC};
    f_list = fieldnames(all_cells.(this_cell));
    for iF = 1:length(f_list)
        if strcmp(f_list{iF}, 'hdr')
            continue
        else
                    x_phase_resp(iC,iF) = nanmean(all_cells.(this_cell).(f_list{iF}).resp(2,:));

            for iPhase = unique(all_cells.(this_cell).(f_list{iF}).latency(1,:)) % get the phase segment numbers (should be 1:5 if phase split by 5
               % labels for x axes
               phase_labels{iPhase} = ['p' num2str(iPhase)];

                % get the latencies
                this_phase_idx = find(all_cells.(this_cell).(f_list{iF}).latency(1,:) == iPhase);
                all_lat(iC, iPhase,iF)  = nanmean(all_cells.(this_cell).(f_list{iF}).latency(2,this_phase_idx)); % in ms get the mean value for this cell in this freq at this phase bin
                % same for spike count
                all_count(iC, iPhase, iF) = nanmean(all_cells.(this_cell).(f_list{iF}).count(2,this_phase_idx)); % in ms get the mean value for this cell in this freq at this phase bin
                
                all_resp(iC,iPhase,iF) = nanmean(all_cells.(this_cell).(f_list{iF}).resp(2,this_phase_idx));
                
                % get all the reponses
                % maybe shuffles?
%                 all_count_shuf(iC, iPhase, iF) = nanmean(all_cells.(this_cell).(f_list{iF}).	(2,this_phase_idx)); % in ms get the mean value for this cell in this freq at this phase bin

            end
            z_lat(iC, :,iF) = zscore(all_lat(iC, :,iF));

            
        end
    end
    
end


% plot
figure(1)
for iF = 1:length(f_list)
    if strcmp(f_list{iF}, 'hdr')
        continue
    else
        subplot(2,ceil(length(f_list)-1)/2, iF)
        imagesc(all_lat(:,:,iF))
        axis xy
        xlabel('phase')
        ylabel('cell id')
        set(gca, 'xticklabel', phase_labels)
        text(floor(length(phase_labels)/2),length(all_lat)+1, f_list{iF}, 'fontsize', font_size)
        colorbar
        
    end
end
SetFigure([], gcf)
set(gcf, 'position', [282   50  1200  720])
ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.35, 0.98,['Latency to first spike across cells'], 'fontsize', font_size)

% saveas(gcf, [summary_dir 'Summary_latency_raw.png']);
% saveas_eps('Summary_latency_raw.png', summary_dir)

%%
% same but for zscore
figure(2)
for iF = 1:length(f_list)
    if strcmp(f_list{iF}, 'hdr')
        continue
    else
        subplot(2,ceil(length(f_list)-1)/2, iF)
        imagesc(z_lat(:,:,iF))
        axis xy
        xlabel('phase')
        ylabel('cell id')
        set(gca, 'xticklabel', phase_labels)
        text(floor(length(phase_labels)/2),length(all_lat)+1, f_list{iF}, 'fontsize', font_size)
        
        colorbar
        caxis([-2.5 2.5])
    end
end
SetFigure([], gcf)
set(gcf, 'position', [282   50  1200  720])
ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.35, 0.98,['Zscore first spike latency across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_count.png']);
% saveas_eps('Summary_count.png', summary_dir)


%% make a response plot



% get all responses p(Spike|stim)

% x_phase_resp should be the same across f_list since it is the number of
% responses and doesn't care about phase or freq. 

for iC =1:size(all_resp,1)
    for iF = 1:size(all_resp,3)
% get max phase
[max_val, max_idx] = max(all_resp(iC,:,iF));

% get min phase
[min_val, min_idx] = min(all_resp(iC,:,iF));


% get ratio
resp_ratio(iC,iF) = max_val/min_val; 

    end
end
resp_ratio_1d = reshape(resp_ratio, 1, numel(resp_ratio));
resp_all_1d = reshape(x_phase_resp, 1, numel(x_phase_resp));



% generate figure
figure(3)
% subplot(2,1,1)
scatter(resp_all_1d, resp_ratio_1d,100, 'filled')
xlabel('p(spike|stim)')
ylabel('ratio of max phase / min phase response')
SetFigure([], gcf)

