%% Master script analysis ET PCA14
% Version that has been uploaded to Github, based on ricbra_PCA14_TM_BM_v7
%TM=Table vs. Mouth Trials,
%BM=Begin and Middle time window analysis (ie. both the beginning and the middle point of the time window of interest differ per video)

%% Calculate the Looking time
clear all
close all
clc
direc = cd;
out = [direc,'\Output\'];

datatotal = ImportDataFile([direc,'Data_12Feb2016.xlsx']); %Zet tussen de (' ') de directory en filename van xlsx file met de data. Deze wordt dan in de cellmatrix "data" geladen.
timing  = ImportTimingFile([direc,'Timing_BM_v6.xlsx']);

rb_PCA14_TM_BM_LookingTimes_Percentages(direc, datatotal, timing, out)

%% Calculate the Count Ratio
clearvars -except direc out
close all
clc
cd(direc)

datatotal = ImportDataFile([direc,'Data_12Feb2016.xlsx']); %Zet tussen de (' ') de directory en filename van xlsx file met de data. Deze wordt dan in de cellmatrix "data" geladen.
timing  = ImportTimingFile([direc,'Timing_BM_v6.xlsx']);

rb_PCA14_TM_BM_CountRatio(direc, datatotal, timing, out)

% Calculate the first onset prediction
clearvars -except direc out
close all
clc
cd(direc)

datatotal = ImportDataFile([direc,'Data_12Feb2016.xlsx']); %Zet tussen de (' ') de directory en filename van xlsx file met de data. Deze wordt dan in de cellmatrix "data" geladen.
timing  = ImportTimingFile([direc,'Timing_BM_v6.xlsx']);

rb_PCA14_TM_BM_OnsetPrediction(direc, datatotal, timing, out)


%% Transfer to SPSS
clearvars -except direc out
close all
clc
cd(direc)
%Specify which subjects to include
Include=[1,2,3,6,9,10,12,15,18:31];

%%%%%%%%%%%%%% Looking Time
%Load Looking Time and Create Output
load([out, 'Looking\Table_LookingTime_Percentage'],'Table_LookingTime_AllSubs');
load([out, 'Looking\Mouth_LookingTime_Percentage'],'Mouth_LookingTime_AllSubs');
load([out, 'Looking\LookingTime_Percentage'],'LookingTime_AllSubs');

%Store in one variable: Only Included Participants
SPSS.LookingTime.Table.PercentagePredMinReact = Table_LookingTime_AllSubs.PercentagePredMinReact(Include,:);
SPSS.LookingTime.Table.Predictive             = Table_LookingTime_AllSubs.Predictive(Include,:);
SPSS.LookingTime.Mouth.PercentagePredMinReact = Mouth_LookingTime_AllSubs.PercentagePredMinReact(Include,:);
SPSS.LookingTime.Mouth.Predictive             = Mouth_LookingTime_AllSubs.Predictive(Include,:);
SPSS.LookingTime.Combined.PercentagePredMinReact = LookingTime_AllSubs.PercentagePredMinReact(Include,:);
SPSS.LookingTime.Combined.Predictive             = LookingTime_AllSubs.Predictive(Include,:);

clearvars -except SPSS out Include

%%%%%%%%%%%%%% Count Ratio
%Load Count and Create Output
load([out, 'Count\Table_PredictiveCountRatio'],'Table_PredictiveCountRatio_AllSubs');
load([out, 'Count\Mouth_PredictiveCountRatio'],'Mouth_PredictiveCountRatio_AllSubs');
load([out, 'Count\PredictiveCountRatio'],'PredictiveCountRatio_AllSubs');

%Store in one variable: Only Included Participants
SPSS.CountRatio.Table.Count         = Table_PredictiveCountRatio_AllSubs.Ratio(Include,:);
%SPSS.CountRatio.Table.NumPred    = Table_PredictiveCountRatio_AllSubs.NumPred(Include,:);
SPSS.CountRatio.Mouth.Count         = Mouth_PredictiveCountRatio_AllSubs.Ratio(Include,:);
%SPSS.CountRatio.Mouth.NumPred    = Mouth_PredictiveCountRatio_AllSubs.NumPred(Include,:);
SPSS.CountRatio.Combined.Count         = PredictiveCountRatio_AllSubs.Ratio(Include,:);
%SPSS.CountRatio.Combined.NumPred    = PredictiveCountRatio_AllSubs.NumPred(Include,:);

clearvars -except SPSS out Include

%%%%%%%%%%%%%% Predictive Looks
%Load Predictive Looks
load([out, 'PredLook\Table_PredictiveLook'],'Table_PredictiveLook_AllSubs');
load([out, 'PredLook\Mouth_PredictiveLook'],'Mouth_PredictiveLook_AllSubs');
load([out, 'PredLook\PredictiveLook'],'PredictiveLook_AllSubs');

%Store in one variable: Only Included Participants
SPSS.PredLook.Table         = Table_PredictiveLook_AllSubs(Include,:);
SPSS.PredLook.Mouth       = Mouth_PredictiveLook_AllSubs(Include,:);
SPSS.PredLook.Combined       = PredictiveLook_AllSubs(Include,:);

clearvars -except SPSS 
