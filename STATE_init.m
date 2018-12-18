% STATE_initialize
% Add the codebase, project secific code, cd to data, and initialize the global variables 



%% Add the codebase

close all
restoredefaultpath
global PARAMS

if isunix
    PARAMS.data_dir = '/Volumes/Fenrir/State_dep'; % where to find the raw data
    PARAMS.inter_dir = '/Volumes/Fenrir/State_dep/Temp/'; % where to put intermediate files
    PARAMS.stats_dir = '/Volumes/Fenrir/State_dep/Stats/'; % where to put the statistical output .txt
    PARAMS.code_base_dir = '/Users/jericcarmichael/Documents/GitHub/vandermeerlab/code-matlab/shared'; % where the codebase repo can be found
    PARAMS.code_state_dir = '/Users/jericcarmichael/Documents/GitHub/EC_State'; % where the multisite repo can be found
    PARAMS.ft_dir = '/Users/jericcarmichael/Documents/GitHub/fieldtrip'; % if needed. 
else
%     PARAMS.data_dir = 'G:\Multisite\'; % where to find the raw data
%     PARAMS.inter_dir = 'G:\Multisite\temp\'; % where to put intermediate files
%     PARAMS.stats_dir = 'G:\Multisite\temp\Stats\'; % where to put the statistical output .txt
%     PARAMS.code_base_dir = 'D:\Users\mvdmlab\My_Documents\GitHub\vandermeerlab\code-matlab\shared'; % where the codebase repo can be found
%     PARAMS.code_MS_dir = 'D:\Users\mvdmlab\My_Documents\GitHub\EC_Multisite'; % where the multisite repo can be found
end
% log the progress
PARAMS.log = fopen([PARAMS.inter_dir 'STATE_log.txt'], 'w');
% define subjects, phases, 
PARAMS.Phases = {'pre', 'burst', 'stim', 'post'}; % recording phases within each session
PARAMS.Subjects = {'M13', 'M14'}; %list of subjects
PARAMS.all_sites = {'vStr', 'dStr', 'Ctrx'}; 
rng(10,'twister') % for reproducibility


% add the required code
addpath(genpath(PARAMS.code_base_dir));
addpath(genpath(PARAMS.code_state_dir));
cd(PARAMS.data_dir) % move to the data folder

