%% STATE_initialize
% Add the codebase, project secific code, cd to data, and initialize the global variables 
% Add the codebase

close all
restoredefaultpath
global PARAMS

os = computer;

if ismac
    PARAMS.data_dir = '/Volumes/Fenrir/State_dep'; % where to find the raw data
    PARAMS.inter_dir = '/Volumes/Fenrir/State_dep/Temp/'; % where to put intermediate files
    PARAMS.stats_dir = '/Volumes/Fenrir/State_dep/Stats/'; % where to put the statistical output .txt
    PARAMS.code_base_dir = '/Users/jericcarmichael/Documents/GitHub/vandermeerlab/code-matlab/shared'; % where the codebase repo can be found
    PARAMS.code_state_dir = '/Users/jericcarmichael/Documents/GitHub/EC_State'; % where the multisite repo can be found
    PARAMS.ft_dir = '/Users/jericcarmichael/Documents/GitHub/fieldtrip'; % if needed. 
    PARAMS.filter_dir = '/Volumes/Fenrir/State_dep/Filters/'; % stores custom built filters for speed.  
    
elseif strcmp(os, 'GLNXA64')
    
    PARAMS.data_dir = '/media/ecarmichael/Fenrir/State_dep'; % where to find the project data
    PARAMS.raw_data_dir = '/media/ecarmichael/Fenrir/State_dep/EC_State'; % where to find the raw data
    PARAMS.inter_dir = '/home/ecarmichael/Documents/State_dep/Temp/'; % where to put intermediate files
    PARAMS.stats_dir = '/home/ecarmichael/Documents/State_dep/Stats/'; % where to put the statistical output .txt
    PARAMS.code_base_dir = '/home/ecarmichael/Documents/GitHub/vandermeerlab/code-matlab/shared'; % where the codebase repo can be found
    PARAMS.code_state_dir = '/home/ecarmichael/Documents/GitHub/EC_State'; % where the multisite repo can be found
    PARAMS.ft_dir = '/home/ecarmichael/Documents/GitHub/fieldtrip'; % if needed. 
    PARAMS.filter_dir = '/media/ecarmichael/Fenrir/State_dep/Filters/'; % stores custom built filters for speed.
    
else
    disp('on a PC')
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
PARAMS.Good_cells = {'M16_2019_02_15_4p2_TT6_SS_02_Good',...
'M16_2019_02_16_3p3_TT5_SS_01_Great',...
'M16_2019_02_17_4_TT7_SS_01_Good',...
'M16_2019_02_18_4_TT4_SS_01_Good',...
'M16_2019_02_19_3p9_TT4_SS_01_Good',...
'M16_2019_02_20_4p3_TT5_SS_01_Good',...
'M16_2019_02_22_4p4_TT8_SS_01_Good',...
'M16_2019_02_23_2p5_TT4_SS_01_Good',...
'M16_2019_02_25_3p1_TT1_SS_01_Good',...
'M16_2019_02_27_3p3_TT5_SS_01_Good',...
'M16_2019_02_27_3p9_TT2_SS_01_Good',...
'M17_2019_02_15_3_TT3_SS_02_OK',...
'M17_2019_02_16_3p2_TT5_SS_01_Good',...
'M17_2019_02_16_3p6_TT4_SS_02_Good',...
'M17_2019_02_17_3_TT8_SS_04_OK',...
'M17_2019_02_18_3p7_TT5_SS_02_OK',...
'M17_2019_02_19_2p5_TT5_SS_01_OK',...
'M17_2019_02_20_3p7_TT5_SS_01_Good',...
'M17_2019_02_21_4p2_TT7_SS_01_Good',...
'M17_2019_02_24_3p6_TT1_SS_01_Good',...
'M17_2019_02_25_3p1_TT5_SS_02_OK',...
'M17_2019_02_25_3p9_TT1_SS_01_Good',...
'M18_2019_04_10_3p8_TT4_SS_01_Good',...
'M18_2019_04_11_4p2_TT7_SS_01_Good',...
'M18_2019_04_12_3p4_TT4_SS_02_Good',...
'M18_2019_04_12_3p8_TT7_SS_01_Good',...
'M18_2019_04_13_3p8_TT6_SS_02_OK',...
'M18_2019_04_14_4_TT3_SS_01_Good',...
'M18_2019_04_15_3p3_TT8_SS_08_Good',...
'M18_2019_04_15_4_TT7_SS_01_Good',...
'M19_2019_04_12_4p2_TT7_SS_01_OK',...
'M19_2019_04_13_4p7_TT2_SS_01_OK',...
'M19_2019_04_13_4p2_TT3_SS_01_OK',...
'M19_2019_04_14_3p3_TT8_SS_01_OK',...
'M19_2019_04_14_4p2_TT5_SS_01_Good',...
'M19_2019_04_15_4_TT6_SS_01_OK',...
'M20_2019_06_07_3p8_TT8_SS_01_Good',...
'M20_2019_06_07_4p6_TT8_SS_01_Good',...
'M20_2019_06_08_4p2_TT7_SS_02_Good',...
'M20_2019_06_09_4p7_TT7_SS_01_Good',...
'M20_2019_06_10_4p2_TT6_SS_01_OK',...
    };


    %M20_2019_06_07_TT8_01_OK was at a very high intensity and seemed to
    %produce an artifact in the LFP. 
    %'M19_2019_04_13_TT2_01_OK',...  %this cell faded by looks nice
    %overall, it has a strange gap in the middle between 200-300 so it has
    %been removed. 
    %M17_2019_02_25_TT5_01_OK',very few responses.  Not used
    %M17_2019_02_17_TT8_04_OK', Too few spikes.  Not Used
    %M17_2019_02_16_TT1_01_Good', Too few spikes 8% plus LFP artifact
    %M17_2019_02_16_TT5_01_OK', Too few spikes 8% plus LFP artifact
    %M16_2019_02_15_TT5_01_Good', possible artifact.  


% PARAMS.Good_cells = {'M13_2018_12_09_TT1_05_OK',...
%     'M13_2018_12_09_TT6_01_OK',...
%     'M13_2018_12_09_TT8_01_OK',...
%     'M13_2018_12_11_TT7_01_OK',...
%     'M13_2018_12_11_TT7_02_OK',...
%     'M13_2018_12_16_TT3_02_OK',...
%     'M13_2018_12_17_TT2_02_Good',...
%     'M14_2018_12_01_TT3_02_OK',...
%     'M14_2018_12_08_TT1_04_Good',...
%     'M14_2018_12_09_TT8_02_OK',...
%     'M14_2018_12_10_TT1_02_Good',...
%     'M14_2018_12_10_TT2_01_Good',...
%     'M14_2018_12_10_TT2_02_Good',...
%     'M14_2018_12_15_TT1_03_OK',...
%     'M14_2018_12_17_TT2_01_OK',...
%     'M16_2019_02_16_TT5_01_Great',...
%     'M16_2019_02_16_TT7_01_Good',...
%     'M16_2019_02_18_TT4_01_Good',...
%     'M16_2019_02_17_TT7_01_Good',...
%     'M16_2019_02_20_TT5_01_Good',...
%     'M16_2019_02_22_TT8_01_Good',...
%     'M16_2019_02_23_TT4_01_Good',...
%     'M16_2019_02_25_TT1_01_Good',...
%     'M16_2019_02_27_TT5_01_Good',...
%     'M17_2019_02_15_TT3_02_OK',...
%     'M17_2019_02_18_TT5_02_OK',...
%     'M17_2019_02_19_TT5_01_OK',...
%     'M17_2019_02_20_TT5_01_Good',...
%     'M18_2019_04_10_TT4_01_Good',...
%     'M18_2019_04_11_TT7_01_Good',...
%     'M18_2019_04_12_TT4_02_Good',...
%     'M18_2019_04_12_TT7_01_Good',...
%     'M18_2019_04_13_TT6_02_OK',...
%     'M18_2019_04_14_TT3_01_Good',...
%     'M19_2019_04_12_TT7_01_OK',...
%     'M19_2019_04_13_TT3_01_OK',...
%     'M19_2019_04_13_TT2_01_OK',...
%     'M19_2019_04_14_TT8_01_OK',...
%     'M19_2019_04_14_TT5_01_Good',...
%     };

rng(11,'twister') % for reproducibility


% add the required code
addpath(genpath(PARAMS.code_base_dir));
addpath(genpath(PARAMS.code_state_dir));
cd(PARAMS.data_dir) % move to the data folder

