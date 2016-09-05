%% Master script analysis ET PCA14
% Version that has been uploaded to Github, based on ricbra_PCA14_TM_BM_v7
%TM=Table vs. Mouth Trials,
%BM=Begin and Middle time window analysis (ie. both the beginning and the middle point of the time window of interest differ per video)

%%
clear all
close all
clc
disp ('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp ('PART 1: LOADING DATA')
disp ('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
%% Load the data
direc = cd;
out = [direc,'\Output\'];
%Create the Output directories:
mkdir(out)
mkdir([out, filesep, 'Looking', filesep])
mkdir([out, filesep, 'Count',filesep])
mkdir([out, filesep, 'PredLook',filesep])
mkdir([out, filesep, 'ClosFix',filesep])

datatotal = ImportDataFile([direc,filesep, 'Data_12Feb2016.xlsx']); %Zet tussen de (' ') de directory en filename van xlsx file met de data. Deze wordt dan in de cellmatrix "data" geladen.
timing  = ImportTimingFile([direc,filesep, 'Timing_BM_v6.xlsx']);


%% Decide which participants and videos to use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%IncludeVids=[101;102;103;104;105;106;107;108;109;110;111;112;201;202;203;204;205;206;207;208;209;210;211;212;213;214;216;]; % ALL
IncludeVids=[102;103;105;106;108;109;110;111;112;113;201;202;203;206;210;212;213;216;]; % Exclude: 101,104,107,204,205,207,208,209,211,214

%Specify which subjects to include
IncludeSubs=[1,2,3,6,9,10,12,15,18:31];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

%%
disp ('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp ('PART 2: CALCULATING MEASURES')
disp ('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
%% Looking Time
cd(direc)
rb_PCA14_TM_BM_LookingTimes_Percentages(direc, datatotal, timing, out,IncludeVids)

%% Count Ratio
cd(direc)
rb_PCA14_TM_BM_CountRatio(direc, datatotal, timing, out,IncludeVids)

%% Onset Prediction
cd(direc)
rb_PCA14_TM_BM_OnsetPrediction(direc, datatotal, timing, out,IncludeVids)

%% ADDED IN JUNE 2016: Closest Fixation to Hand entering AOI
cd(direc)
rb_PCA14_TM_BM_ClosFix(direc, datatotal, timing, out,IncludeVids)

%% In order to extract plots of the measures for each of the different videos, use the following script:
cd(direc)
rb_PCA14_TM_BM_PerVideo(direc, out, IncludeSubs,IncludeVids)


%%
disp ('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp ('PART 3: SAVING DATA')
disp ('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
%% Transfer into a format that you can analyze with SPSS
cd(direc)

%1) Looking Time
%Load Looking Time and Create Output
load([out, 'Looking\Table_LookingTime_Percentage'],'Table_LookingTime_AllSubs');
load([out, 'Looking\Mouth_LookingTime_Percentage'],'Mouth_LookingTime_AllSubs');
load([out, 'Looking\LookingTime_Percentage'],'LookingTime_AllSubs');

%Store in one variable: Only Included Participants
SPSS.LookingTime.Table.PercentagePredMinReact = Table_LookingTime_AllSubs.PercentagePredMinReact(IncludeSubs,:);
SPSS.LookingTime.Table.Predictive             = Table_LookingTime_AllSubs.Predictive(IncludeSubs,:);
SPSS.LookingTime.Mouth.PercentagePredMinReact = Mouth_LookingTime_AllSubs.PercentagePredMinReact(IncludeSubs,:);
SPSS.LookingTime.Mouth.Predictive             = Mouth_LookingTime_AllSubs.Predictive(IncludeSubs,:);
SPSS.LookingTime.Combined.PercentagePredMinReact = LookingTime_AllSubs.PercentagePredMinReact(IncludeSubs,:);
SPSS.LookingTime.Combined.Predictive             = LookingTime_AllSubs.Predictive(IncludeSubs,:);

clearvars -except SPSS out IncludeSubs

%2)Count Ratio
%Load Count and Create Output
load([out, 'Count\Table_PredictiveCountRatio'],'Table_PredictiveCountRatio_AllSubs');
load([out, 'Count\Mouth_PredictiveCountRatio'],'Mouth_PredictiveCountRatio_AllSubs');
load([out, 'Count\PredictiveCountRatio'],'PredictiveCountRatio_AllSubs');

%Store in one variable: Only Included Participants
SPSS.CountRatio.Table.Count         = Table_PredictiveCountRatio_AllSubs.Ratio(IncludeSubs,:);
%SPSS.CountRatio.Table.NumPred    = Table_PredictiveCountRatio_AllSubs.NumPred(Include,:);
SPSS.CountRatio.Mouth.Count         = Mouth_PredictiveCountRatio_AllSubs.Ratio(IncludeSubs,:);
%SPSS.CountRatio.Mouth.NumPred    = Mouth_PredictiveCountRatio_AllSubs.NumPred(Include,:);
SPSS.CountRatio.Combined.Count         = PredictiveCountRatio_AllSubs.Ratio(IncludeSubs,:);
%SPSS.CountRatio.Combined.NumPred    = PredictiveCountRatio_AllSubs.NumPred(Include,:);

clearvars -except SPSS out IncludeSubs

%3) Predictive Looks
%Load Predictive Looks
load([out, 'PredLook\Table_PredictiveLook'],'Table_PredictiveLook_AllSubs');
load([out, 'PredLook\Mouth_PredictiveLook'],'Mouth_PredictiveLook_AllSubs');
load([out, 'PredLook\PredictiveLook'],'PredictiveLook_AllSubs');

%Store in one variable: Only Included Participants
SPSS.PredLook.Table         = Table_PredictiveLook_AllSubs(IncludeSubs,:);
SPSS.PredLook.Mouth         = Mouth_PredictiveLook_AllSubs(IncludeSubs,:);
SPSS.PredLook.Combined      = PredictiveLook_AllSubs(IncludeSubs,:);

