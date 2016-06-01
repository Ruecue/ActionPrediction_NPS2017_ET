function rb_PCA14_TM_BM_PerVideo(direc, out, inc)

% direc: directory of the scripts
% out: output directory
% inc: Variable Include from the main script that indices which subjects to
% include

Include=[1,2,3,6,9,10,12,15,18:31];
inc=Include;



%%%%%%%%%%%%%%%%%%%% LookingTime

%% load in the information for all participants and videos
Set=load([out, 'Looking\OutDataPerVideo'], 'OutDataPerVideo')

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

%% Next, we want to create an average per subject for each of the videos
%to sort everything more easily, we create a dataset
DSet=mat2dataset(Set);
DSet.Properties.VarNames={'sub','video','AOI','PPred', 'PReac', 'PPminPR'};

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
            if isequal(Set(rc+1,1),Set(rc+2,1)) && isequal(Set(rc+1,2),Set(rc+2,2)) && isequal(Set(rc+1,3),Set(rc+2,3))
                disp(Set(rc,1))
                disp(Set(rc,2))
                disp(Set(rc,3))
                error('it seems that there are more than two trials for this participant and AOI')
            end
            
            %Create Average
            Set_Avg(j,1)=Set(rc,1); %Sub
            Set_Avg(j,2)=Set(rc,2); %Trial
            Set_Avg(j,3)=Set(rc,3); %AOI
            %average the two values
            Set_Avg(j,4)=mean([Set(rc,6),Set(rc+1,6)]);
            
            rc=rc+2; %skip the next row
            j=j+1;
        else
            %Use single value:
            Set_Avg(j,1)=Set(rc,1); %Sub
            Set_Avg(j,2)=Set(rc,2); %Trial
            Set_Avg(j,3)=Set(rc,3); %AOI
            %use this row only
            Set_Avg(j,4)=Set(rc,6);
            
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
        end
        rc=rc+1;
    end
end

%% Next, we want to average across participants per Video and AOI

DSet_Avg=mat2dataset(Set_Avg);
DSet_Avg.Properties.VarNames={'sub','video','AOI','PPminPR'};

%Sorted according to subject, then video and then AOI so that we can
%compute the average.
DSet_Avg = sortrows(DSet_Avg,{'video','AOI'});

%% Now I want to average over participants in these arrays
Set_Avg=double(DSet_Avg);

%Detect each jumps in the AOIs (from 1 to 2, 2 to 3, etc.)
jump = find(abs(diff(Set_Avg(:,3)))> 0);

%check that these indeed belong to the same video.
clear M_SetAvg
s_in=1; %starting index for the average)
j=1; %index for M_SetAvg
for i=1:length(jump)
    M_SetAvg(j,1)=mean(Set_Avg([s_in:jump(i)],2)); %Video
    M_SetAvg(j,2)=mean(Set_Avg([s_in:jump(i)],3)); %AOI
    M_SetAvg(j,3)=mean(Set_Avg([s_in:jump(i)],4)); %Value
    s_in=jump(i)+1;
    j=j+1;
end

%add last trial
M_SetAvg(j,1)=mean(Set_Avg([s_in:end],2)); %Video
M_SetAvg(j,2)=mean(Set_Avg([s_in:end],3)); %AOI
M_SetAvg(j,3)=mean(Set_Avg([s_in:end],4)); %Value

%rearrange per video (columns: AOIs)
DS_M_SetAvg=mat2dataset(M_SetAvg);
DS_M_SetAvg.Properties.VarNames={'video','AOI','PPminPR'};
%sort according to AOI and then  video
DS_M_SetAvg = sortrows(DS_M_SetAvg,{'AOI', 'video'});

M_SetAvg=double(DS_M_SetAvg);

thirds=find(abs(diff((M_SetAvg(:,2))))>0);
SPSSOut(:,1)=M_SetAvg([1:thirds(1)],1) %Video Number
SPSSOut(:,2)=M_SetAvg([1:thirds(1)],3) %AOI1
SPSSOut(:,3)=M_SetAvg([thirds(1)+1:thirds(2)],3) %AOI2
SPSSOut(:,4)=M_SetAvg([thirds(2)+1:end],3) %AOI3

%Sanity check
%Videos should be the same
if ~isequal(SPSSOut(:,1),M_SetAvg([thirds(1)+1:thirds(2)],1)) || ~isequal(SPSSOut(:,1),M_SetAvg([thirds(2)+1:end],1))
    error ('Distribution of videos in SPSSOut is not consistent between AOIs, please check')
end

if ~isequal(mean(M_SetAvg([thirds(1)+1:thirds(2)],2)),2) ||~isequal(mean(M_SetAvg([thirds(2)+1:end],2)),3)
    error ('Distribution of AOIs in SPSSOut is not correct, please check')
end

%Barplots per video

for vid=1:13 %100ers
    figure(1)
    subplot(4,4,vid)
    bar(SPSSOut(vid,[2:end]))
    ylim([-0.3,0.3])
    title(SPSSOut(vid,1))
end

pl=1;
for vid=14:28 %200ers
    figure(2)
    subplot(4,4,pl)
    bar(SPSSOut(vid,[2:end]))
    ylim([-0.3,0.3])
    title(SPSSOut(vid,1))
     pl=pl+1;
end



