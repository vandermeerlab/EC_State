%% initialize

STATE_init
global PARAMS

cd(PARAMS.raw_data_dir)

%% loop through sessions and preprocess the data. based on STATE_batch.m but with more utilitatian sturcture
sess_list = {};
d = dir;
d=d(~ismember({d.name},{'.','..', '._*'}));
for iSess = 1:length(d)
    if ~strcmp(d(iSess).name(1:2), '._')
        sess_list{end+1} = d(iSess).name;

    end
end


to_process = {}; % custom sessions to process


for iSess = 1:length(sess_list)
    this_date = sess_list{iSess}(5:14);
    this_sub = sess_list{iSess}(1:3);
    this_str = sess_list{iSess}(16:19);
    this_depth = sess_list{iSess}(21:23);
    
    if ismember(PARAMS.Good_cells, sess_list{iSess}(1:22))
    
         fprintf('STATE_Batch_2: Processing session: %s...\n', iSess.name)
    end

end

