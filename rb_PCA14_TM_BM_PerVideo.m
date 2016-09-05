function rb_PCA14_TM_BM_PerVideo(direc, out, inc, incstim)

% direc: directory of the scripts
% out: output directory
% inc: Variable Include from the main script that indices which subjects to
% include

% Include=[1,2,3,6,9,10,12,15,18:31];
% inc=Include;

%%%%%%%%%%%%%%%%%%%%% LookingTime & Count Ratio

%% load in the information for all participants and videos
load([out, 'Looking\LT_OutDataPerVideo'], 'LT_OutDataPerVideo');
load([out, 'Count\C_OutDataPerVideo'], 'C_OutDataPerVideo');

SetL=LT_OutDataPerVideo;
SetC=C_OutDataPerVideo;
clear LT_OutDataPerVideo C_OutDataPerVideo

%Note: LT and Count Ratio should give us exactly the same trials, so we can
%first check this and then combine the data.

%Check that they contain the same data (if I substract the first three
%columns from each other, this should always be 0 (so the length of the Os
%then again should be the same as the length of SetC.
% Also the NaNs in row 4 of the C set should also be there in row 4 and row
% 5 of the LT set, so we can check this (the minimum of ismember should be
% 1

if ~isequal(size(SetL,1), size(SetC,1))
    error ('size SetL and SetC are not the same, please check')
elseif ~isequal(size(find((SetC(:,1)-SetL(:,1))==0),1),size(SetC,1)) || ~isequal(size(find((SetC(:,2)-SetL(:,2))==0),1),size(SetC,1)) || ~isequal(size(find((SetC(:,3)-SetL(:,3))==0),1),size(SetC,1)) 
    error ('values in SetC and SetL are not the same, please check')
elseif min(ismember(find(isnan(SetC(:,4))),find(isnan(SetL(:,4)))))~=1 || min(ismember(find(isnan(SetC(:,4))),find(isnan(SetL(:,5)))))~=1
    error ('NaNs in SetC are not consistent with NaNs in SetLT, please check')
end

%Add last row of SetC to SetL

Set=SetL;
Set(:,7)=SetC(:,4);%PredictiveOrReactiveTrial

%Remove invalid trials and replace NaN with 0 where needed
%Also remove participants that I want to exclude
j=1;
del=[];
for i=1:length(Set)
    if isnan(Set(i,4)) && isnan(Set(i,5)) || ~ismember(Set(i,1),inc)
        del(j)=i;
        j=j+1;
    elseif isnan(Set(i,4)) && ~isnan(Set(i,5))
        Set(i,4)=0; %as we are comparing looking times, NaN needs to be replaced with 0 in cases where participants did look but only during one window.
    elseif isnan(Set(i,5)) && ~isnan(Set(i,4))
        Set(i,5)=0; %as we are comparing looking times, NaN needs to be replaced with 0 in cases where participants did look but only during one window.
    end
    
end

%delete the invalid trials
if ~isempty(del)
    Set(del,:)=[];
end

%% Calculate the difference per trial
Set(:,6)=Set(:,4)-Set(:,5);

%% Next, we want to create an average per subject for each of the videos (for COunt and PPminPR)
%to sort everything more easily, we create a dataset
DSet=mat2dataset(Set);
DSet.Properties.VarNames={'sub','video','AOI','PPred', 'PReac', 'PPminPR','Count'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSet = sortrows(DSet,{'sub','video', 'AOI'});

%Convert back to double
Set=double(DSet);

j=1;
rc=1; %rc: the row you want to check (we want to skip one row if we averaged that one).
while rc<=length(Set)
    if rc<length(Set)
        if isequal(Set(rc,1),Set(rc+1,1)) && isequal(Set(rc,2),Set(rc+1,2)) && isequal(Set(rc,3),Set(rc+1,3)) %if we have two of the same Subject, Video and AOI, we need to average
            %check that the next row is not also the same (there should be max
            %2 trials per participant
            if rc<length(Set)-1 %only check this if we are not already at the end ;)
                if isequal(Set(rc+1,1),Set(rc+2,1)) && isequal(Set(rc+1,2),Set(rc+2,2)) && isequal(Set(rc+1,3),Set(rc+2,3))
                    disp(Set(rc,1))
                    disp(Set(rc,2))
                    disp(Set(rc,3))
                    error('it seems that there are more than two trials for this participant and AOI')
                end
            end
            
            %Create Average
            Set_Avg(j,1)=Set(rc,1); %Sub
            Set_Avg(j,2)=Set(rc,2); %Trial
            Set_Avg(j,3)=Set(rc,3); %AOI
            %average the two values
            Set_Avg(j,4)=(Set(rc,6)+Set(rc+1,6))/2; %Looking %pred-%react
            Set_Avg(j,5)=(Set(rc,7)+Set(rc+1,7))/2; %Count: the mean of the 0 and 1 will give us the count ratio
            
            rc=rc+2; %skip the next row
            j=j+1;
        else
            %Use single value:
            Set_Avg(j,1)=Set(rc,1); %Sub
            Set_Avg(j,2)=Set(rc,2); %Trial
            Set_Avg(j,3)=Set(rc,3); %AOI
            %use this row only
            Set_Avg(j,4)=Set(rc,6);
            Set_Avg(j,5)=Set(rc,7);
            
            rc=rc+1; %we need to check the next row.
            j=j+1;
        end
    else %for the last row, we only need to write this into Set_Avg if this is a unique trial
        if ~isequal(Set(rc,1),Set(rc-1,1)) || ~isequal(Set(rc,2),Set(rc-1,2)) || ~isequal(Set(rc,3),Set(rc-1,3)) %if this trial is different from the one before write this into the variable
            %Use single value:
            Set_Avg(j,1)=Set(rc,1); %Sub
            Set_Avg(j,2)=Set(rc,2); %Trial
            Set_Avg(j,3)=Set(rc,3); %AOI
            %use this row only
            Set_Avg(j,4)=Set(rc,6);
            Set_Avg(j,5)=Set(rc,7);
        end
        rc=rc+1;
    end
end

%% Next, we want to average across participants per Video and AOI

DSet_Avg=mat2dataset(Set_Avg);
DSet_Avg.Properties.VarNames={'sub','video','AOI','PPminPR','Count'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSet_Avg = sortrows(DSet_Avg,{'video','AOI'});

%% Now I want to average over participants in these arrays
Set_Avg=double(DSet_Avg);

%Detect each jumps in the AOIs (from 1 to 2, 2 to 3, etc.)

%check that there are only jumps of 0, +1 (1-2, 2-3) and -2 (3-1)
testjump=diff(Set_Avg(:,3));
ok=[0,1,-2];

if max(~ismember(testjump,ok))>0 %this means there is a number in there that we dont allow.
    warning('the order of AOIs is not correct (1,2,3), there might be videos for which no data is present, please check')
    %find the missing AOI-video combination:
    wrongjump=find(~ismember(testjump,ok)>0);
    priorAOI=Set_Avg(wrongjump,3);
    priorVid=Set_Avg(wrongjump,2);
    followAOI=Set_Avg(wrongjump+1,3);
    followVid=Set_Avg(wrongjump+1,2);
    
    warning('the following AOI seems to be missing for this video:')
    disp('priorAOI:')
    disp(priorAOI)
    disp('priorVid:')
    disp(priorVid)
    disp('followAOI:')
    disp(followAOI)
    disp('followVid:')
    disp(followVid)
    
    %If its a missing AOI from the same video, add that in (as this was the case
    %for my data), if its not from the same video, give error
    
    if priorVid-followVid==0
       AllAOI=[1,2,3];
       AOIpresent=[priorAOI,followAOI]
       AddVid=priorVid;
       AddAOI=setdiff(AllAOI,AOIpresent);
       Addin=[NaN,AddVid,AddAOI,NaN];
       %add this in: (using A = [A(1:k,:); b; A(k+1:end,:)]
       Set_Avg=[Set_Avg(1:wrongjump,:);Addin;Set_Avg(wrongjump+1:end,:)];
     else
        error('The Video-AOI combi that is missing cannot be solved by the script, please check')
    end
    warning('added in NaN ro the data for Video and AOI:')
    disp(AddVid)
    disp(AddAOI)
    warning('press enter to proceed:')
    input('')
end

jump = find(abs(diff(Set_Avg(:,3)))> 0);

%check that these indeed belong to the same video.
clear M_SetAvg
s_in=1; %starting index for the average)
j=1; %index for M_SetAvg
for i=1:length(jump)
    M_SetAvg(j,1)=mean(Set_Avg([s_in:jump(i)],2)); %Video
    M_SetAvg(j,2)=mean(Set_Avg([s_in:jump(i)],3)); %AOI
    M_SetAvg(j,3)=mean(Set_Avg([s_in:jump(i)],4)); %Value LT
    M_SetAvg(j,4)=mean(Set_Avg([s_in:jump(i)],5)); %Value C
    s_in=jump(i)+1;
    j=j+1;
end

%add last trial
M_SetAvg(j,1)=mean(Set_Avg([s_in:end],2)); %Video
M_SetAvg(j,2)=mean(Set_Avg([s_in:end],3)); %AOI
M_SetAvg(j,3)=mean(Set_Avg([s_in:end],4)); %Value LT
M_SetAvg(j,4)=mean(Set_Avg([s_in:end],5)); %Value C

%rearrange per video (columns: AOIs)
DS_M_SetAvg=mat2dataset(M_SetAvg);
DS_M_SetAvg.Properties.VarNames={'video','AOI','PPminPR','Count'};
%sort according to AOI and then  video
DS_M_SetAvg = sortrows(DS_M_SetAvg,{'AOI', 'video'});

M_SetAvg=double(DS_M_SetAvg);


%%Plot and export for the different variables:

%LookingTime
thirds=find(abs(diff((M_SetAvg(:,2))))>0);
SPSSOut_LT(:,1)=M_SetAvg([1:thirds(1)],1); %Video Number
SPSSOut_LT(:,2)=M_SetAvg([1:thirds(1)],3); %AOI1 LT
SPSSOut_LT(:,3)=M_SetAvg([thirds(1)+1:thirds(2)],3);%AOI2 LT
SPSSOut_LT(:,4)=M_SetAvg([thirds(2)+1:end],3); %AOI3 LT
%Count
SPSSOut_C(:,1)=M_SetAvg([1:thirds(1)],1); %Video Number
SPSSOut_C(:,2)=M_SetAvg([1:thirds(1)],4); %AOI1 C
SPSSOut_C(:,3)=M_SetAvg([thirds(1)+1:thirds(2)],4); %AOI2 C
SPSSOut_C(:,4)=M_SetAvg([thirds(2)+1:end],4); %AOI3 C


%Sanity check
%Videos should be the same
if ~isequal(SPSSOut_LT(:,1),M_SetAvg([thirds(1)+1:thirds(2)],1)) || ~isequal(SPSSOut_LT(:,1),M_SetAvg([thirds(2)+1:end],1))
    error ('Distribution of videos in SPSSOut is not consistent between AOIs, please check LT')
elseif ~isequal(SPSSOut_C(:,1),M_SetAvg([thirds(1)+1:thirds(2)],1)) || ~isequal(SPSSOut_C(:,1),M_SetAvg([thirds(2)+1:end],1))
    error ('Distribution of videos in SPSSOut is not consistent between AOIs, please check C')
end

if ~isequal(mean(M_SetAvg([thirds(1)+1:thirds(2)],2)),2) ||~isequal(mean(M_SetAvg([thirds(2)+1:end],2)),3)
    error ('Distribution of AOIs in SPSSOut is not correct, please check (LT & C)')
end

%% Barplots per video
%Looking Time


length(find(incstim<200))

for vid=1:length(find(incstim<200)); %100ers
    title ('Looking Time')
    figure(1)
    subplot(4,4,vid)
    bar(SPSSOut_LT(vid,[2:end]))
    ylim([-0.3,0.3])
    title(SPSSOut_LT(vid,1))
end

pl=1;
for vid=length(find(incstim<200))+1:length(incstim) %200ers
    figure(2)
    title ('Looking Time')
    subplot(4,4,pl)
    bar(SPSSOut_LT(vid,[2:end]))
    ylim([-0.3,0.3])
    title(SPSSOut_LT(vid,1))
     pl=pl+1;
end

%Count
for vid=1:length(find(incstim<200)); %100ers
    figure(3)
    title ('Count')
    subplot(4,4,vid)
    bar(SPSSOut_C(vid,[2:end]),'g')
    ylim([0,1])
    title(SPSSOut_C(vid,1))
end

pl=1;
for vid=length(find(incstim<200))+1:length(incstim) %200ers
    figure(4)
    title ('Count')
    subplot(4,4,pl)
    bar(SPSSOut_C(vid,[2:end]),'g')
    ylim([0,1])
    title(SPSSOut_C(vid,1))
     pl=pl+1;
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% Predictive Look Onset


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except out inc incstim
%% load in the information for all participants and videos
load([out, 'PredLook\PO_OutDataPerVideo'], 'PO_OutDataPerVideo');
SetPO=PO_OutDataPerVideo;
clear PO_OutDataPerVideo

%Remove invalid trials and replace NaN with 0 where needed
%Also remove participants that I want to exclude
j=1;
del=[];
for i=1:length(SetPO)
    if isnan(SetPO(i,4)) || ~ismember(SetPO(i,1),inc)
        del(j)=i;
        j=j+1;
    end
end

%delete the invalid trials
if ~isempty(del)
    SetPO(del,:)=[];
end

%% Next, we want to create an average per subject for each of the videos (for COunt and PPminPR)
%to sort everything more easily, we create a dataset
DSetPO=mat2dataset(SetPO);
DSetPO.Properties.VarNames={'sub','video','AOI', 'POLook'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSetPO = sortrows(DSetPO,{'sub','video', 'AOI'});

%Convert back to double
SetPO=double(DSetPO);

j=1;
rc=1; %rc: the row you want to check (we want to skip one row if we averaged that one).
while rc<=length(SetPO)
    if rc<length(SetPO)
        if isequal(SetPO(rc,1),SetPO(rc+1,1)) && isequal(SetPO(rc,2),SetPO(rc+1,2)) && isequal(SetPO(rc,3),SetPO(rc+1,3)) %if we have two of the same Subject, Video and AOI, we need to average
            %check that the next row is not also the same (there should be max
            %2 trials per participant
            if rc<length(SetPO)-1 %only check this if we are not already at the end ;)
                if isequal(SetPO(rc+1,1),SetPO(rc+2,1)) && isequal(SetPO(rc+1,2),SetPO(rc+2,2)) && isequal(SetPO(rc+1,3),SetPO(rc+2,3))
                    disp(SetPO(rc,1))
                    disp(SetPO(rc,2))
                    disp(SetPO(rc,3))
                    error('it seems that there are more than two trials for this participant and AOI')
                end
            end
            
            %Create Average
            Set_AvgPO(j,1)=SetPO(rc,1); %Sub
            Set_AvgPO(j,2)=SetPO(rc,2); %Trial
            Set_AvgPO(j,3)=SetPO(rc,3); %AOI
            %average the two values
            Set_AvgPO(j,4)=(SetPO(rc,4)+SetPO(rc+1,4))/2; %Avg. Predictive Look Onset
           
            rc=rc+2; %skip the next row
            j=j+1;
        else
            %Use single value:
            Set_AvgPO(j,1)=SetPO(rc,1); %Sub
            Set_AvgPO(j,2)=SetPO(rc,2); %Trial
            Set_AvgPO(j,3)=SetPO(rc,3); %AOI
            %use this row only
            Set_AvgPO(j,4)=SetPO(rc,4); %Predictive Look Onset
            
            rc=rc+1; %we need to check the next row.
            j=j+1;
        end
    else %for the last row, we only need to write this into Set_Avg if this is a unique trial
        if ~isequal(SetPO(rc,1),SetPO(rc-1,1)) || ~isequal(SetPO(rc,2),SetPO(rc-1,2)) || ~isequal(SetPO(rc,3),SetPO(rc-1,3)) %if this trial is different from the one before write this into the variable
            %Use single value:
            Set_AvgPO(j,1)=SetPO(rc,1); %Sub
            Set_AvgPO(j,2)=SetPO(rc,2); %Trial
            Set_AvgPO(j,3)=SetPO(rc,3); %AOI
            %use this row only
            Set_AvgPO(j,4)=SetPO(rc,4);%Predictive Look Onset
        end
        rc=rc+1;
    end
end

%% Next, we want to average across participants per Video and AOI

DSet_AvgPO=mat2dataset(Set_AvgPO);
DSet_AvgPO.Properties.VarNames={'sub','video','AOI','POLook'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSet_AvgPO = sortrows(DSet_AvgPO,{'video','AOI'});

%% Now I want to average over participants in these arrays
Set_AvgPO=double(DSet_AvgPO);

%Detect each jumps in the AOIs (from 1 to 2, 2 to 3, etc.)

%check that there are only jumps of 0, +1 (1-2, 2-3) and -2 (3-1)
testjump=diff(Set_AvgPO(:,3));
ok=[0,1,-2];

if max(~ismember(testjump,ok))>0 %this means there is a number in there that we dont allow.
    warning('PO ANALYSIS: the order of AOIs is not correct (1,2,3), there might be videos for which no data is present, please check')
    %find the missing AOI-video combination:
    wrongjump=find(~ismember(testjump,ok)>0);
    priorAOI=Set_AvgPO(wrongjump,3);
    priorVid=Set_AvgPO(wrongjump,2);
    followAOI=Set_AvgPO(wrongjump+1,3);
    followVid=Set_AvgPO(wrongjump+1,2);
    
    warning('PO ANALYSIS: the following AOI seems to be missing for this video:')
    disp('priorAOI:')
    disp(priorAOI)
    disp('priorVid:')
    disp(priorVid)
    disp('followAOI:')
    disp(followAOI)
    disp('followVid:')
    disp(followVid)
    
    %If its a missing AOI from the same video, add that in (as this was the case
    %for my data), if its not from the same video, give error
    
    if priorVid-followVid==0
       AllAOI=[1,2,3];
       AOIpresent=[priorAOI,followAOI];
       AddVid=priorVid;
       AddAOI=setdiff(AllAOI,AOIpresent);
       Addin=[NaN,AddVid,AddAOI,NaN];
       %add this in: (using A = [A(1:k,:); b; A(k+1:end,:)]
       Set_AvgPO=[Set_AvgPO(1:wrongjump,:);Addin;Set_AvgPO(wrongjump+1:end,:)];
    else
        error('PO ANALYSIS: The Video-AOI combi that is missing cannot be solved by the script, please check')
    end
    warning('added in NaN ro the data for Video and AOI:')
    disp(AddVid)
    disp(AddAOI)
    warning('press enter to proceed:')
    input('')
end

jump = find(abs(diff(Set_AvgPO(:,3)))> 0);

%check that these indeed belong to the same video.
clear M_SetAvgPO
s_in=1; %starting index for the average)
j=1; %index for M_SetAvg
for i=1:length(jump)
    M_SetAvgPO(j,1)=mean(Set_AvgPO([s_in:jump(i)],2)); %Video
    M_SetAvgPO(j,2)=mean(Set_AvgPO([s_in:jump(i)],3)); %AOI
    M_SetAvgPO(j,3)=mean(Set_AvgPO([s_in:jump(i)],4)); %Value PO
    s_in=jump(i)+1;
    j=j+1;
end

%add last trial
M_SetAvgPO(j,1)=mean(Set_AvgPO([s_in:end],2)); %Video
M_SetAvgPO(j,2)=mean(Set_AvgPO([s_in:end],3)); %AOI
M_SetAvgPO(j,3)=mean(Set_AvgPO([s_in:end],4)); %Value PO

%rearrange per video (columns: AOIs)
DS_M_SetAvgPO=mat2dataset(M_SetAvgPO);
DS_M_SetAvgPO.Properties.VarNames={'video','AOI','POLook'};
%sort according to AOI and then  video
DS_M_SetAvgPO = sortrows(DS_M_SetAvgPO,{'AOI', 'video'});

M_SetAvgPO=double(DS_M_SetAvgPO);

%%Plot and export for the different variables:

%Predictive OnsetLookingTime
thirds=find(abs(diff((M_SetAvgPO(:,2))))>0);
SPSSOut_PO(:,1)=M_SetAvgPO([1:thirds(1)],1); %Video Number
SPSSOut_PO(:,2)=M_SetAvgPO([1:thirds(1)],3); %AOI1 PO
SPSSOut_PO(:,3)=M_SetAvgPO([thirds(1)+1:thirds(2)],3);%AOI2 PO
SPSSOut_PO(:,4)=M_SetAvgPO([thirds(2)+1:end],3); %AOI3 PO

%Sanity check
%Videos should be the same
if ~isequal(SPSSOut_PO(:,1),M_SetAvgPO([thirds(1)+1:thirds(2)],1)) || ~isequal(SPSSOut_PO(:,1),M_SetAvgPO([thirds(2)+1:end],1))
    error ('Distribution of videos in SPSSOut is not consistent between AOIs, please check PO')
end

if ~isequal(mean(M_SetAvgPO([thirds(1)+1:thirds(2)],2)),2) ||~isequal(mean(M_SetAvgPO([thirds(2)+1:end],2)),3)
    error ('Distribution of AOIs in SPSSOut is not correct, please check (LT & C)')
end

%% Barplots per video
%Predictive Onset
for vid=1:length(find(incstim<200)); %100ers
    figure(5)
    title ('Onset Prediction')
    subplot(4,4,vid)
    bar(SPSSOut_PO(vid,[2:end]),'r')
    ylim([0,1000])
    title(SPSSOut_PO(vid,1))
end

pl=1;
for vid=length(find(incstim<200))+1:length(incstim) %200ers
    figure(6)
    title ('Onset Prediction')
    subplot(4,4,pl)
    bar(SPSSOut_PO(vid,[2:end]),'r')
    ylim([0,1000])
    title(SPSSOut_PO(vid,1))
     pl=pl+1;
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% Closest Fixation Onset (Middle-FixOnset) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars -except out inc incstim
%% load in the information for all participants and videos
load([out, '\ClosFix\CF_OutDataPerVideo'], 'CF_OutDataPerVideo');
SetCF=CF_OutDataPerVideo;
clear CF_OutDataPerVideo

%Remove invalid trials and replace NaN with 0 where needed
%Also remove participants that I want to exclude
j=1;
del=[];
for i=1:length(SetCF)
    if isnan(SetCF(i,4)) || ~ismember(SetCF(i,1),inc)
        del(j)=i;
        j=j+1;
    end
end

%delete the invalid trials
if ~isempty(del)
    SetCF(del,:)=[];
end

%% Next, we want to create an average per subject for each of the videos (for COunt and PPminPR)
%to sort everything more easily, we create a dataset
DSetCF=mat2dataset(SetCF);
DSetCF.Properties.VarNames={'sub','video','AOI', 'CFDiff'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSetCF = sortrows(DSetCF,{'sub','video', 'AOI'});

%Convert back to double
SetCF=double(DSetCF);

j=1;
rc=1; %rc: the row you want to check (we want to skip one row if we averaged that one).
while rc<=length(SetCF)
    if rc<length(SetCF)
        if isequal(SetCF(rc,1),SetCF(rc+1,1)) && isequal(SetCF(rc,2),SetCF(rc+1,2)) && isequal(SetCF(rc,3),SetCF(rc+1,3)) %if we have two of the same Subject, Video and AOI, we need to average
            %check that the next row is not also the same (there should be max
            %2 trials per participant
            
            %if we are before the last two trials we need to check the
            %trial after that as well:
            if rc<length(SetCF)-1
                if isequal(SetCF(rc+1,1),SetCF(rc+2,1)) && isequal(SetCF(rc+1,2),SetCF(rc+2,2)) && isequal(SetCF(rc+1,3),SetCF(rc+2,3))
                    disp(SetCF(rc,1))
                    disp(SetCF(rc,2))
                    disp(SetCF(rc,3))
                    error('it seems that there are more than two trials for this participant and AOI')
                end
            end
            
            %Create Average
            Set_AvgCF(j,1)=SetCF(rc,1); %Sub
            Set_AvgCF(j,2)=SetCF(rc,2); %Trial
            Set_AvgCF(j,3)=SetCF(rc,3); %AOI
            %average the two values
            Set_AvgCF(j,4)=(SetCF(rc,4)+SetCF(rc+1,4))/2; %Avg. Closest fixation difference
           
            rc=rc+2; %skip the next row
            j=j+1;
        else
            %Use single value:
            Set_AvgCF(j,1)=SetCF(rc,1); %Sub
            Set_AvgCF(j,2)=SetCF(rc,2); %Trial
            Set_AvgCF(j,3)=SetCF(rc,3); %AOI
            %use this row only
            Set_AvgCF(j,4)=SetCF(rc,4); %Closest Fixation difference
            
            rc=rc+1; %we need to check the next row.
            j=j+1;
        end
    else %for the last row, we only need to write this into Set_Avg if this is a unique trial
        if ~isequal(SetCF(rc,1),SetCF(rc-1,1)) || ~isequal(SetCF(rc,2),SetCF(rc-1,2)) || ~isequal(SetCF(rc,3),SetCF(rc-1,3)) %if this trial is different from the one before write this into the variable
            %Use single value:
            Set_AvgCF(j,1)=SetCF(rc,1); %Sub
            Set_AvgCF(j,2)=SetCF(rc,2); %Trial
            Set_AvgCF(j,3)=SetCF(rc,3); %AOI
            %use this row only
            Set_AvgCF(j,4)=SetCF(rc,4);%Closest Fixation difference
        end
        rc=rc+1;
    end
end

%% Next, we want to average across participants per Video and AOI

DSet_AvgCF=mat2dataset(Set_AvgCF);
DSet_AvgCF.Properties.VarNames={'sub','video','AOI','CFDiff'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSet_AvgCF = sortrows(DSet_AvgCF,{'video','AOI'});

%% Now I want to average over participants in these arrays
Set_AvgCF=double(DSet_AvgCF);

%Detect each jumps in the AOIs (from 1 to 2, 2 to 3, etc.)

%check that there are only jumps of 0, +1 (1-2, 2-3) and -2 (3-1)
testjump=diff(Set_AvgCF(:,3));
ok=[0,1,-2];

if max(~ismember(testjump,ok))>0 %this means there is a number in there that we dont allow.
    warning('CF ANALYSIS: the order of AOIs is not correct (1,2,3), there might be videos for which no data is present, please check')
    %find the missing AOI-video combination:
    wrongjump=find(~ismember(testjump,ok)>0);
    priorAOI=Set_AvgCF(wrongjump,3);
    priorVid=Set_AvgCF(wrongjump,2);
    followAOI=Set_AvgCF(wrongjump+1,3);
    followVid=Set_AvgCF(wrongjump+1,2);
    
    warning('CF ANALYSIS:the following AOI seems to be missing for this video:')
    disp('priorAOI:')
    disp(priorAOI)
    disp('priorVid:')
    disp(priorVid)
    disp('followAOI:')
    disp(followAOI)
    disp('followVid:')
    disp(followVid)
    
    %If its a missing AOI from the same video, add that in (as this was the case
    %for my data), if its not from the same video, give error
    
    if priorVid-followVid==0
       AllAOI=[1,2,3];
       AOIpresent=[priorAOI,followAOI];
       AddVid=priorVid;
       AddAOI=setdiff(AllAOI,AOIpresent);
       Addin=[NaN,AddVid,AddAOI,NaN];
       %add this in: (using A = [A(1:k,:); b; A(k+1:end,:)]
       Set_AvgCF=[Set_AvgCF(1:wrongjump,:);Addin;Set_AvgCF(wrongjump+1:end,:)];
    else
        error('CF ANALYSIS:The Video-AOI combi that is missing cannot be solved by the script, please check')
    end
    warning('added in NaN ro the data for Video and AOI:')
    disp(AddVid)
    disp(AddAOI)
    warning('press enter to proceed:')
    input('')
end

jump = find(abs(diff(Set_AvgCF(:,3)))> 0);

%check that these indeed belong to the same video.
clear M_SetAvgCF
s_in=1; %starting index for the average)
j=1; %index for M_SetAvg
for i=1:length(jump)
    M_SetAvgCF(j,1)=mean(Set_AvgCF([s_in:jump(i)],2)); %Video
    M_SetAvgCF(j,2)=mean(Set_AvgCF([s_in:jump(i)],3)); %AOI
    M_SetAvgCF(j,3)=mean(Set_AvgCF([s_in:jump(i)],4)); %Value CF
    s_in=jump(i)+1;
    j=j+1;
end

%add last trial
M_SetAvgCF(j,1)=mean(Set_AvgCF([s_in:end],2)); %Video
M_SetAvgCF(j,2)=mean(Set_AvgCF([s_in:end],3)); %AOI
M_SetAvgCF(j,3)=mean(Set_AvgCF([s_in:end],4)); %Value CF

%rearrange per video (columns: AOIs)
DS_M_SetAvgCF=mat2dataset(M_SetAvgCF);
DS_M_SetAvgCF.Properties.VarNames={'video','AOI','CFDiff'};
%sort according to AOI and then  video
DS_M_SetAvgCF = sortrows(DS_M_SetAvgCF,{'AOI', 'video'});

M_SetAvgCF=double(DS_M_SetAvgCF);

%%Plot and export for the different variables:

%Predictive OnsetLookingTime
thirds=find(abs(diff((M_SetAvgCF(:,2))))>0);
SPSSOut_CF(:,1)=M_SetAvgCF([1:thirds(1)],1); %Video Number
SPSSOut_CF(:,2)=M_SetAvgCF([1:thirds(1)],3); %AOI1 CF
SPSSOut_CF(:,3)=M_SetAvgCF([thirds(1)+1:thirds(2)],3);%AOI2 CF
SPSSOut_CF(:,4)=M_SetAvgCF([thirds(2)+1:end],3); %AOI3 CF

%Sanity check
%Videos should be the same
if ~isequal(SPSSOut_CF(:,1),M_SetAvgCF([thirds(1)+1:thirds(2)],1)) || ~isequal(SPSSOut_CF(:,1),M_SetAvgCF([thirds(2)+1:end],1))
    error ('Distribution of videos in SPSSOut is not consistent between AOIs, please check CF')
end

if ~isequal(mean(M_SetAvgCF([thirds(1)+1:thirds(2)],2)),2) ||~isequal(mean(M_SetAvgCF([thirds(2)+1:end],2)),3)
    error ('Distribution of AOIs in SPSSOut is not correct, please check (LT & C)')
end

%% Barplots per video
%Predictive Onset
for vid=1:length(find(incstim<200))%100ers
    figure(7)
    title('Closest Fixation Onset')
    subplot(4,4,vid)
    bar(SPSSOut_CF(vid,[2:end]),'y')
    ylim([-1000,0])
    title(SPSSOut_CF(vid,1))
end

pl=1;
for vid=length(find(incstim<200))+1:length(incstim) %200ers
    figure(8)
    title('Closest Fixation Onset')
    subplot(4,4,pl)
    bar(SPSSOut_CF(vid,[2:end]),'y')
    ylim([-1000,0])
    title(SPSSOut_CF(vid,1))
     pl=pl+1;
end








