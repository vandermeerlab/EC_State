function statedep_summary
%% collect the outputs from statedep_all_phase_sandbox and statedep_latency_phase_sandbox
%
%
%
STATE_init
%% defaults


global PARAMS
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
        if ismember([sess_list(iSess).name(1:14) '_' this_cell], PARAMS.Good_cells) % check if this is a 'good' cell from above approvedd list
            
                        freq_list = fieldnames(out.(this_cell));
            
            
            all_cells.([sess_list(iSess).name(1:14) '_' this_cell]) = out.(this_cell);
            
            % subject hdr
            %             all_cells.(this_cell).hdr.name = sess_list(iSess).name(1:14);
            %             all_cells.(this_cell).hdr.date = sess_list(iSess).name(5:14);
            %             all_cells.(this_cell).hdr.subject = sess_list(iSess).name(1:3);
        else
            disp(['Skippking ' sess_list(iSess).name(1:14) '_' this_cell '.  Not a ''good'' cell'])
        end
        
    end
    
end

%%
nShuf = 10000;
cell_list = fieldnames(all_cells);
all_lat =[];
all_count = [];
all_resp_ratio = [];
for iC = 1:length(cell_list)
    this_cell = cell_list{iC};
    f_list = fieldnames(all_cells.(this_cell));
    cell_depths(iC) = all_cells.(this_cell).ExpKeys.tetrodeDepths;
    for iF = 1:length(f_list)
        if strcmp(f_list{iF}, 'ExpKeys') || strcmp(f_list{iF}, 'hdr')
            continue
        else
            x_phase_resp(iC, iF) = nanmean(all_cells.(this_cell).(f_list{iF}).resp(2,:));
            
            
            %% get the shuffle for the response max-min
            for iShuf = 1:nShuf
                this_shuf = [];
                mix = randperm(length(all_cells.(this_cell).(f_list{iF}).latency(1,:)));
                this_shuf(1,:) = all_cells.(this_cell).(f_list{iF}).latency(1,mix);
                
                for iPhase = unique(all_cells.(this_cell).(f_list{iF}).latency(1,:))
                    this_phase_idx = find(this_shuf(1,:) == iPhase);
                    this_phase_mean(iPhase) = nanmean(all_cells.(this_cell).(f_list{iF}).resp(2,this_phase_idx));
                end
                all_shuf_ratio(iShuf) = max(this_phase_mean)/min(this_phase_mean);
                % check for inf from shuffle
                all_shuf_ratio(isinf(all_shuf_ratio)) = NaN;
                
                
            end
            % get the phase response averages
            for iPhase = unique(all_cells.(this_cell).(f_list{iF}).latency(1,:))
                this_phase_idx = find(all_cells.(this_cell).(f_list{iF}).latency(1,:) == iPhase);
                this_resp(iPhase) = nanmean(all_cells.(this_cell).(f_list{iF}).resp(2,this_phase_idx));
            end
            %
            all_resp_ratio(iC, iF) = ((max(this_resp)/min(this_resp)) - nanmean(all_shuf_ratio))/nanstd(all_shuf_ratio);
            if isnan(all_resp_ratio(iC, iF))
                disp([num2str(iC), 'f' num2str(iF)])
            end
            %%
            
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
                all_lat_shuf_mean(iC, iPhase, iF) = nanmean(all_cells.(this_cell).(f_list{iF}).latency_shuf(1,this_phase_idx)); % in ms get the mean value for this cell in this freq at this phase bin
                all_lat_shuf_std(iC, iPhase, iF) = nanstd(all_cells.(this_cell).(f_list{iF}).latency_shuf(1,this_phase_idx)); % in ms get the mean value for this cell in this freq at this phase bin
                
                all_resp_shuf_mean(iC,iPhase, iF) = nanmean(all_cells.(this_cell).(f_list{iF}).resp_shuf(1,this_phase_idx));
                all_resp_shuf_std(iC,iPhase, iF) = nanstd(all_cells.(this_cell).(f_list{iF}).resp_shuf(1,this_phase_idx));
                
                
                if all_lat(iC, iPhase,iF) > all_lat_shuf_mean(iC,iPhase,iF)+ 1.96*(all_lat_shuf_std(iC,iPhase,iF)) || all_lat(iC, iPhase,iF) < all_lat_shuf_mean(iC,iPhase,iF)- 1.96*(all_lat_shuf_std(iC,iPhase,iF))
                    all_lat_v_shuf(iC,iPhase,iF) = all_lat(iC, iPhase, iF);
                else
                    all_lat_v_shuf(iC, iPhase, iF) = NaN;
                end
                
                %exceeds 2sd of shuffle for response
                %                  if all_resp(iC, iPhase,iF) > all_resp_shuf_mean(iC,iPhase,iF)+ 1.96*(all_resp_shuf_std(iC,iPhase,iF)) || all_resp(iC, iPhase,iF) < all_resp_shuf_mean(iC,iPhase,iF)- 1.96*(all_resp_shuf_std(iC,iPhase,iF))
                all_resp_v_shuf(iC,iPhase,iF) = (all_resp(iC,iPhase,iF) - all_resp_shuf_mean(iC,iPhase,iF))/all_resp_shuf_std(iC,iPhase,iF);
                %                 else
                %                     all_resp_v_shuf(iC, iPhase, iF) = NaN;
                %                 end
                
            end
            z_lat(iC, :,iF) = zscore(all_lat(iC, :,iF));
            z_resp(iC, :,iF) = zscore(all_resp(iC, :,iF));
            all_resp_v_all(iC,:,iF) = all_resp(iC,:,iF)./x_phase_resp(iC,iF);
            
            sess_id{iC} = this_cell;
            freq_vals(iC, iF) = iF;
        end
    end
    
end
%% sort base on depth
[depth_sort, depth_ord] = sort(cell_depths, 'descend');
x_phase_resp_sort = x_phase_resp(depth_ord,:);
all_resp_v_shuf_sort = all_resp_v_shuf(depth_ord,:,:);
all_lat_sort = all_lat(depth_ord,:,:);
all_resp_sort = all_resp(depth_ord,:,:);
all_resp_v_all_sort = all_resp_v_all(depth_ord,:,:);
all_lat_v_shuf_sort = all_lat_v_shuf(depth_ord,:,:);
all_count_sort = all_count(depth_ord,:,:);
all_resp_ratio_sort = all_resp_ratio(depth_ord, :,:);
for ii =1:length(depth_sort)
    
    labels{ii} = strcat( num2str(floor(x_phase_resp_sort(ii)*100)), '%'); %num2str(depth_sort(ii)), '_m_m ',
    all_sess_id_sort{ii} = sess_id{depth_ord(ii)};

end

% get the freq list for legend
for iF = 1:length(f_list)
    if strcmp(f_list{iF}, 'ExpKeys') || strcmp(f_list{iF}, 'hdr')
        continue
    else
        leg_freq{iF} = [ strrep(f_list{iF}(3:end), '_', '-') 'Hz'];
    end
    
    
end

%% remove cells with a response less than 20%

for iC = length(x_phase_resp_sort):-1:1
    if x_phase_resp_sort(iC) < .2
        all_resp_v_shuf_sort(iC,:,:) = [];
        all_lat_sort(iC,:,:) = [];
        all_resp_sort(iC,:,:) = [];
        all_resp_v_all_sort(iC,:,:) = [];
        all_lat_v_shuf_sort(iC,:,:) = [];
        all_count_sort(iC,:,:) = [];
        all_resp_ratio_sort(iC,:,:) = [];
        x_phase_resp_sort(iC,:,:) = [];
        freq_vals(iC,:) = [];
        labels{iC} = [];
%         all_sess_id_sort{iC} = [];
        depth_sort(iC) = [];
    end
end
labels = labels(~cellfun('isempty',labels));
% all_sess_id_sort = all_sess_id_sort(~cellfun('isempty',all_sess_id_sort));
%%
% relative to shuffle
% zscore
figure(8)
for iF = 1:length(f_list)
    if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
        continue
    else
        subplot(2,ceil(length(f_list)-1)/2, iF);
        imagesc(all_resp_v_shuf_sort(:,:,iF));
        axis xy
        xlabel('phase');
        ylabel('cell id');
        set(gca, 'xticklabel', phase_labels);
        set(gca,'ytick', [1:length(all_resp_v_shuf_sort(:,:,iF))], 'yticklabel',labels ); % [num2str(cell_depths) ' - ' num2str(floor(x_phase_resp(:,iF)*100))]
        text(floor(length(phase_labels)/2),length(all_resp_v_shuf_sort)+1, f_list{iF}, 'fontsize', font_size)
        
        colorbar
        caxis([-2.5 2.5])
    end 
    sig_cells = double(all_resp_v_shuf_sort(:,:,iF)>1.96);
    temp_all_resp_v_shuf = all_resp_v_shuf_sort(:,:,iF);
    temp_all_resp_v_shuf(sig_cells==0)=NaN;
    %     add_num_imagesc(gca, temp_all_resp_v_shuf, 2, 12)
end
SetFigure([], gcf)
set(gcf, 'position', [282   50  1200  720])
ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.35, 0.98,['Zscore v Shuf per stim across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_resp_v_shuf.png']);
% saveas_eps('Summary_resp_v_shuf', summary_dir)
%% make a response plot



% get all responses p(Spike|stim)

% x_phase_resp should be the same across f_list since it is the number of
% responses and doesn't care about phase or freq.
f_cor = linspecer(size(all_resp_ratio,2));
figure(9)
freq_colors = [];
for iC =1:size(all_resp_ratio_sort,1)
    for iF = 1:size(all_resp_ratio_sort,2)
        % % get max phase
        % % norm to lowest
        %
        % [max_val, max_idx] = max(all_resp_v_shuf(iC,:,iF))%./min(all_resp_v_shuf(iC,:,iF)));
        %
        % % get min phase
        % [min_val, min_idx] = min(all_resp_v_shuf(iC,:,iF));
        %
        %
        % % get ratio
        % resp_ratio(iC,iF) = abs(max_val-min_val);
        freq_colors{iC,iF} = f_cor(iF,:);
        freq(iC, iF) = iF;
            cell_id(iC,iF) = iC; 
    end
end
resp_ratio_1d = reshape(all_resp_ratio_sort, 1, numel(all_resp_ratio_sort));
resp_all_1d = reshape(x_phase_resp_sort, 1, numel(x_phase_resp_sort));
freq_colors_1d = reshape(freq_colors,1, numel(freq_colors));
freq_id_1d = reshape(freq_vals,1, numel(freq_vals));
depth_all_1d = reshape(repmat(depth_sort',1,size(x_phase_resp_sort,2)), 1, numel(x_phase_resp_sort));
cell_id_1d = reshape(cell_id,1, numel(cell_id));

% generate figure
for iC = 1:length(resp_all_1d)
    hold on
    if depth_all_1d(iC) >3.5
        scatter(resp_all_1d(iC), resp_ratio_1d(iC),100,freq_colors_1d{iC}, 'filled')
    else
        scatter(resp_all_1d(iC), resp_ratio_1d(iC),100,freq_colors_1d{iC}, 'filled', 'd')
    end
end
xlabel('p(spike|stim)')
ylabel('zscore response (max phase/min phase)')
%ylabel('ratio of max phase / min phase response')
h = zeros(size(all_resp_ratio,2), 1);
for iF = 1:size(all_resp_ratio,2)
    h(iF) = plot(NaN,NaN,'o', 'color', f_cor(iF, :), 'MarkerFaceColor', f_cor(iF,:));
end
lgd = legend(h, leg_freq, 'location', 'NorthEastOutside');
legend('boxoff')
lgd.FontSize = 18;

xlim([0.2 .7])
ylim([-2 4])
line([0 0.7], [1.96, 1.96], 'color', [0.3 0.3 0.3])

SetFigure([], gcf)
saveas(gcf, [summary_dir 'Summary_resp_ratio.png']);
saveas_eps('Summary_resp_ratio', summary_dir)

% extra legend figure
figure(111)
hold on
    h(1) = plot(NaN,NaN,'o', 'color', 'k', 'MarkerFaceColor', 'k');
    h(2) = plot(NaN,NaN,'d', 'color', 'k', 'MarkerFaceColor', 'k');
axis off
lgd = legend({'dStr', 'vStr'});
legend('boxoff')
lgd.FontSize = 18;
saveas_eps('Summary_Str_legend', summary_dir)
%% make a table of responsive cells and which frequencies
Keep_idx = resp_all_1d >0.2; 

keep_resp_ratio_1d = resp_ratio_1d(Keep_idx);
keep_resp_all_1d = resp_all_1d(Keep_idx);
keep_depth_1d = depth_all_1d(Keep_idx);
keep_freq_1d = freq_id_1d(Keep_idx);
keep_cell_1d = cell_id_1d(Keep_idx);


fprintf('\nNumber of responsive cells: %.2d/%.2d = %.2d %%\n',length(unique(keep_cell_1d(keep_resp_ratio_1d >1.96))),length(unique(keep_cell_1d)),round((length(unique(keep_cell_1d(keep_resp_ratio_1d >1.96)))/length(unique(keep_cell_1d)))*100) ) 
for iC = 1:length(keep_resp_all_1d)
    if keep_resp_ratio_1d(iC) >1.96
        fprintf(['Responsive cell ' all_sess_id_sort{keep_cell_1d(iC)} ' at ' num2str(keep_resp_ratio_1d(iC),2) ' SD, ' freq_list{keep_freq_1d(iC)} 'Hz. Overall Resp:' num2str((keep_resp_all_1d(iC)*100),2) '\n'])
    end
end

fprintf('\n')

%%

% %% make a table of responsive cells, where they are, subject ID, ....
% Sub_list = {'M13', 'M14'};
% summary_table = cell(6,length(Sub_list)+1);
% summary_table{2,1} = 'n Resp Cells';
% for iSub = 1:length(Sub_list)
%     summary_table{1, iSub+1} = Sub_list{iSub};
%
% end
% for iC = 1:length(cell_list)
%     this_cell = cell_list{iC};
%     f_list = fieldnames(all_cells.(this_cell));
%
%     summary_table(
%
%
%
%
% end


%% plots
% figure(1)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         imagesc(all_lat_sort(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_lat_sort)+1, f_list{iF}, 'fontsize', font_size)
%         colorbar
%         
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['Latency to first spike across cells'], 'fontsize', font_size)
% 
% saveas(gcf, [summary_dir 'Summary_latency_raw.png']);
% saveas_eps('Summary_latency_raw', summary_dir)
% %%
% figure(2)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         
%         imagesc(all_lat_v_shuf_sort(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_lat_v_shuf_sort)+1, f_list{iF}, 'fontsize', font_size)
%         colorbar
%         
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['Latency to first spike across cells (above 2d of shuf)'], 'fontsize', font_size)
% 
% saveas(gcf, [summary_dir 'Summary_latency_zshuf.png']);
% saveas_eps('Summary_latency_z_shuf', summary_dir)
% %%
% % same but for zscore
% figure(3)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         imagesc(z_lat(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_lat)+1, f_list{iF}, 'fontsize', font_size)
%         
%         colorbar
%         caxis([-2.5 2.5])
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['Zscore first spike latency across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_zscore.png']);
% saveas_eps('Summary_zscore', summary_dir)
% 
% %% count version
% 
% figure(3)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         imagesc(all_count_sort(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_count_sort)+1, f_list{iF}, 'fontsize', font_size)
%         
%         colorbar
%         %         caxis([-2.5 2.5])
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['nSpikes per stim across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_count.png']);
% saveas_eps('Summary_count', summary_dir)
% 
% 
% %% response version
% figure(5)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         imagesc(all_resp_sort(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_resp_sort)+1, f_list{iF}, 'fontsize', font_size)
%         
%         colorbar
%         %         caxis([-2.5 2.5])
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['Response per stim across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_resp.png']);
% saveas_eps('Summary_resp', summary_dir)
% 
% % zscore
% figure(6)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         imagesc(z_resp(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_lat)+1, f_list{iF}, 'fontsize', font_size)
%         
%         colorbar
%         %         caxis([-2.5 2.5])
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['Zscore response per stim across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_resp_z.png']);
% saveas_eps('Summary_resp_z', summary_dir)
% 
% % relative to all
% % zscore
% figure(7)
% for iF = 1:length(f_list)
%     if strcmp(f_list{iF}, 'hdr') || strcmp(f_list{iF}, 'ExpKeys')
%         continue
%     else
%         subplot(2,ceil(length(f_list)-1)/2, iF)
%         imagesc(all_resp_v_all_sort(:,:,iF))
%         axis xy
%         xlabel('phase')
%         ylabel('cell id')
%         set(gca, 'xticklabel', phase_labels)
%         text(floor(length(phase_labels)/2),length(all_resp_v_all_sort)+1, f_list{iF}, 'fontsize', font_size)
%         
%         colorbar
%         %         caxis([-2.5 2.5])
%     end
% end
% SetFigure([], gcf)
% set(gcf, 'position', [282   50  1200  720])
% ha = axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
% text(0.35, 0.98,['Relative response per stim across cells'], 'fontsize', font_size)
% saveas(gcf, [summary_dir 'Summary_resp_v_all.png']);
% saveas_eps('Summary_resp_v_all', summary_dir)
%%


