function rb_PCA14_TM_BM_LookingTimes_Percentages(direc, datatotal, timing, out)
%LOOKING TIME PCA 14

cd(direc) %cd brengt ja naar een bepaalde directory, zet de directory met je scripts en data file tussen de (' ')


subjtotal=size(unique(datatotal(:,2)),1)-1; %-1 because one is the heading "subject"
AOI={'AOI1','AOI2','AOI3'};
%%
x_all=1; %this index is used to store the information of all videos and subjects in the variable LT_OutDataPerVideo
for subj=1:subjtotal
    clear LookingTime
    clearvars -except LT_OutDataPerVideo x_all subj AOI subjtotal direc datatotal timing out LookingTime_AllSubs Table_LookingTime_AllSubs Mouth_LookingTime_AllSubs  Mouth_LookingTime_TrialNumber  Table_LookingTime_TrialNumber  LookingTime_TrialNumber
    
    %Create the subject name that we will look for in the data file
    if subj<10, subjname=['pil0',num2str(subj)];  %plak het nummer dat 'i' is op dit moment, vast aan de 'string' 'Pil0'
    else subjname=['pil',num2str(subj)];
    end
    
    %Look for all the trials of this subject
    index=find(strcmpi(datatotal(:,2),subjname));
    data=datatotal(index,:);
    
    %Look for the number of trials from the subject
    trialtotal=unique(data(:,1));
    
    %find the stimulus number for that trial
    
    stimtotal=unique(data(:,4));
    for i=1:size(stimtotal,1)
        temp=stimtotal{i};
        stimtotaltemp(i,1)=str2num(temp(1:end-5));
    end
    stimtotal=stimtotaltemp;
    clear temp stimtotaltemp
    
    %reset the table and mouth trials
    table_trl=1;
    mouth_trl=1;
    
    LookingTime=[]; %added in in version 3 (because I got an error that this variable was cleared)
    
    for trl=1:length(trialtotal)
        trialnumber=trialtotal(trl);
        %get the video of that trial
        i_begtrl=min(find((strcmp(trialnumber,data(:,1)))));
        vidnum=str2num(data{i_begtrl,4}(1:end-5));
       
        %This tells us whether a trial ia a mouth or a table trial
        table=0;
        mouth=0;
        clear stimulus
        for aoi=1:3; %For Action Step 1,2,3
            %The data of that participant for one trial and one AOI
            ParticipantData={};
            %Fixation onset of one trial, and duration of reactive and
            %predictive looks
            Fix_Onset=[];
            predictive_tempdur=[];
            reactive_tempdur=[];
            n=1;
            m=1;
            
            %Go through all the rows and select the fixations of this trial
            %for to this AOI
            for rij=1:size(data,1)
                %If this fixation was to the AOI
                if strcmpi(data(rij,2),subjname) && strcmpi(data(rij,1),trialnumber) && (data{rij,8}==aoi)==1 
                    stimulus=data{rij,4};
                    stimulus=str2num(stimulus(1:end-5)); %Make a number out of the string which can then be compared to the timing file
                    
                    %sanity check (above I determined vidnum and this
                    %should be the same as stimulus here, so I am
                    %doublechecking this to make sure my code is right.
                    if ~isequal(stimulus, vidnum)
                        error('stimulus and vidnum is not the same, check the loop and data file')
                    end
                    
                    if stimulus>=200
                        table=1; %table trials
                        mouth=0;
                    elseif stimulus>=100 && stimulus<200
                        table=0; %mouth trials
                        mouth=1;
                    end
                    
                    %Data from all fixation to this AOI from this trial is passed onto the Participant
                    %Data file
                    ParticipantData(n,:)=data(rij,:);
                    
                    for rij_t=1:size(timing,1) %go through the timing file and look for the right video column to determine the middle point
                        if isequal(timing{rij_t,1},stimulus)==1;
                            if aoi==1
                                beginpoint=timing{rij_t,2};
                                middlepoint=timing{rij_t,3};
                                endpoint=timing{rij_t,4};
                            elseif aoi==2
                                beginpoint=timing{rij_t,5};
                                middlepoint=timing{rij_t,6};
                                endpoint=timing{rij_t,7};
                            elseif aoi==3
                                beginpoint=timing{rij_t,8};
                                middlepoint=timing{rij_t,9};
                                endpoint=timing{rij_t,10};
                            end
                        end
                    end
                    
                    %Check if fixation lies in the correct time window
                    Fix_Onset=ParticipantData{n,11};
                    Fix_Dur=ParticipantData{n,12};
                    Fix_End=ParticipantData{n,13};
                    
                    if Fix_Dur>=100 %Is the fixation is at least 100ms
                        if Fix_Onset>= beginpoint && Fix_Onset< middlepoint      %Predictive fixations lie between begin and middle
                            if Fix_End>middlepoint
                                predictive_tempdur(m,1)=middlepoint-Fix_Onset;
                                reactive_tempdur(m,1)=0;
                                m=m+1;
                            elseif Fix_End<=middlepoint
                                predictive_tempdur(m,1)=Fix_Dur;
                                reactive_tempdur(m,1)=0;
                                m=m+1;
                            end
                        elseif Fix_Onset>= middlepoint && Fix_Onset<endpoint   %If there is no predictive fixation, reactive fixations need to lie between middle and end
                            if Fix_End>endpoint
                                reactive_tempdur(m,1)=endpoint-Fix_Onset;
                                predictive_tempdur(m,1)=0;
                                m=m+1;
                            elseif Fix_End<=endpoint
                                reactive_tempdur(m,1)=Fix_Dur;
                                predictive_tempdur(m,1)=0;
                                m=m+1;
                            end
                        end  
                    end 
                   
                    n=n+1;
                end
            end
            
            %Check if this trial is predictive or reactive or invalid
            if isempty(predictive_tempdur)==1 && isempty(reactive_tempdur)==1%if no information has been saved
                LookingTime.Trials(trl,aoi)=NaN;
                LookingTime.Predictive(trl,aoi)=NaN;
                LookingTime.Reactive(trl,aoi)=NaN;
                LookingTime.VidNum(trl,aoi)=vidnum; %this stores which video has been seen so that we can later group videos together
            elseif sum(predictive_tempdur)>0 %if we have at least one predictive fixation this trial is counted as predictive and we sum up the predictive looking time
                LookingTime.Trials(trl,aoi)=1; %predictive
                LookingTime.Predictive(trl,aoi)=(sum(predictive_tempdur))/(middlepoint-beginpoint); %Percentage of Looking to AOI during predictive time window  
                LookingTime.Reactive(trl,aoi)=NaN; %reactive doesnt count here
                LookingTime.VidNum(trl,aoi)=vidnum; %this stores which video has been seen so that we can later group videos together
            else %if there is no predictive fixation, the trial is reactive and we sum up the reactive looking time
                LookingTime.Trials(trl,aoi)=0; %reactive
                LookingTime.Predictive(trl,aoi)=NaN; %Predictive is 0
                LookingTime.Reactive(trl,aoi)=(sum(reactive_tempdur))/(endpoint-middlepoint); %Percentage of Looking to AOI during reactive time window
                LookingTime.VidNum(trl,aoi)=vidnum; %this stores which video has been seen so that we can later group videos together
             end
            % Store the raw data
            LookingTime.ParticipantData.(AOI{aoi}){trl,1}=ParticipantData;
                       
            %Write this off into large datafile
            LT_OutDataPerVideo(x_all,1)=subj;
            LT_OutDataPerVideo(x_all,2)=vidnum;
            LT_OutDataPerVideo(x_all,3)=aoi;
            LT_OutDataPerVideo(x_all,4)=LookingTime.Predictive(trl,aoi);
            LT_OutDataPerVideo(x_all,5)=LookingTime.Reactive(trl,aoi);
            
            x_all=x_all+1;
            
        end
        
        if table==1
            Table_LookingTime.Trials(table_trl,:)=LookingTime.Trials(trl,:);
            Table_LookingTime.Predictive(table_trl,:)=LookingTime.Predictive(trl,:);
            Table_LookingTime.Reactive(table_trl,:)=LookingTime.Reactive(trl,:);
            table_trl=table_trl+1;
        elseif mouth==1
            Mouth_LookingTime.Trials(mouth_trl,:)=LookingTime.Trials(trl,:);
            Mouth_LookingTime.Predictive(mouth_trl,:)=LookingTime.Predictive(trl,:);
            Mouth_LookingTime.Reactive(mouth_trl,:)=LookingTime.Reactive(trl,:);
            mouth_trl= mouth_trl+1;
        end
     
        
    end
    
%     %After we have classifed all trials as either predictive or reactive we
%     %can calucalte the difference score
%     LookingTime.PercentagePredMinReact=nanmean(LookingTime.Predictive,1)-nanmean(LookingTime.Reactive,1) %average percentage looking time predictive

    %Participant Average
    LookingTime_AllSubs.Predictive(subj,:)=nanmean(LookingTime.Predictive,1);
    LookingTime_AllSubs.Reactive(subj,:)=nanmean(LookingTime.Reactive,1);
    
    %Check for NaNs that represent the presence of only invalid trials in
    %one AOI (where both predictive and reactive should be NaN), otherwise
    %replace this NaN with an average of 0 to make comparison possible
    
    for i=1:3
        if isnan(LookingTime_AllSubs.Predictive(subj,i)) && ~isnan(LookingTime_AllSubs.Reactive(subj,i))
            LookingTime_AllSubs.Predictive(subj,i)=0;
        elseif isnan(LookingTime_AllSubs.Reactive(subj,i)) && ~isnan(LookingTime_AllSubs.Predictive(subj,i))
            LookingTime_AllSubs.Reactive(subj,i)=0;
        end
    end
    
    LookingTime_AllSubs.PercentagePredMinReact(subj,:)=LookingTime_AllSubs.Predictive(subj,:)-LookingTime_AllSubs.Reactive(subj,:);
    
    LookingTime_TrialNumber.Predictive(subj,1)=length(find(LookingTime.Trials(:,1)==1));
    LookingTime_TrialNumber.Predictive(subj,2)=length(find(LookingTime.Trials(:,2)==1));
    LookingTime_TrialNumber.Predictive(subj,3)=length(find(LookingTime.Trials(:,3)==1));
    LookingTime_TrialNumber.Reactive(subj,1)=length(find(LookingTime.Trials(:,1)==0));
    LookingTime_TrialNumber.Reactive(subj,2)=length(find(LookingTime.Trials(:,2)==0));
    LookingTime_TrialNumber.Reactive(subj,3)=length(find(LookingTime.Trials(:,3)==0));
    LookingTime_TrialNumber.Invalid(subj,1)=length(find(isnan(LookingTime.Trials(:,1))));
    LookingTime_TrialNumber.Invalid(subj,2)=length(find(isnan(LookingTime.Trials(:,2))));
    LookingTime_TrialNumber.Invalid(subj,3)=length(find(isnan(LookingTime.Trials(:,3))));
    LookingTime_TrialNumber.Total(subj,:)=LookingTime_TrialNumber.Predictive(subj,:)+LookingTime_TrialNumber.Reactive(subj,:);
    
    %Table Trials
    Table_LookingTime_AllSubs.Predictive(subj,:)=nanmean(Table_LookingTime.Predictive,1);
    Table_LookingTime_AllSubs.Reactive(subj,:)=nanmean(Table_LookingTime.Reactive,1);
    
    %Check for NaNs that represent the presence of only invalid trials in
    %one AOI (where both predictive and reactive should be NaN), otherwise
    %replace this NaN with an average of 0 to make comparison possible
    
    for i=1:3
        if isnan(Table_LookingTime_AllSubs.Predictive(subj,i)) && ~isnan(Table_LookingTime_AllSubs.Reactive(subj,i))
             Table_LookingTime_AllSubs.Predictive(subj,i)=0;
        elseif isnan( Table_LookingTime_AllSubs.Reactive(subj,i)) && ~isnan(Table_LookingTime_AllSubs.Predictive(subj,i))
             Table_LookingTime_AllSubs.Reactive(subj,i)=0;
        end
    end
    Table_LookingTime_AllSubs.PercentagePredMinReact(subj,:)=Table_LookingTime_AllSubs.Predictive(subj,:)-Table_LookingTime_AllSubs.Reactive(subj,:);
    
    Table_LookingTime_TrialNumber.Predictive(subj,1)=length(find(Table_LookingTime.Trials(:,1)==1));
    Table_LookingTime_TrialNumber.Predictive(subj,2)=length(find(Table_LookingTime.Trials(:,2)==1));
    Table_LookingTime_TrialNumber.Predictive(subj,3)=length(find(Table_LookingTime.Trials(:,3)==1));
    Table_LookingTime_TrialNumber.Reactive(subj,1)=length(find(Table_LookingTime.Trials(:,1)==0));
    Table_LookingTime_TrialNumber.Reactive(subj,2)=length(find(Table_LookingTime.Trials(:,2)==0));
    Table_LookingTime_TrialNumber.Reactive(subj,3)=length(find(Table_LookingTime.Trials(:,3)==0));
    Table_LookingTime_TrialNumber.Invalid(subj,1)=length(find(isnan(Table_LookingTime.Trials(:,1))));
    Table_LookingTime_TrialNumber.Invalid(subj,2)=length(find(isnan(Table_LookingTime.Trials(:,2))));
    Table_LookingTime_TrialNumber.Invalid(subj,3)=length(find(isnan(Table_LookingTime.Trials(:,3))));
    Table_LookingTime_TrialNumber.Total(subj,:)=Table_LookingTime_TrialNumber.Predictive(subj,:)+Table_LookingTime_TrialNumber.Reactive(subj,:);
    
    %Mouth Trials
    Mouth_LookingTime_AllSubs.Predictive(subj,:)=nanmean(Mouth_LookingTime.Predictive,1);
    Mouth_LookingTime_AllSubs.Reactive(subj,:)=nanmean(Mouth_LookingTime.Reactive,1);
    
    for i=1:3
        if isnan(Mouth_LookingTime_AllSubs.Predictive(subj,i)) && ~isnan(Mouth_LookingTime_AllSubs.Reactive(subj,i))
             Mouth_LookingTime_AllSubs.Predictive(subj,i)=0;
        elseif isnan( Mouth_LookingTime_AllSubs.Reactive(subj,i)) && ~isnan(Mouth_LookingTime_AllSubs.Predictive(subj,i))
             Mouth_LookingTime_AllSubs.Reactive(subj,i)=0;
        end
    end
    Mouth_LookingTime_AllSubs.PercentagePredMinReact(subj,:)=Mouth_LookingTime_AllSubs.Predictive(subj,:)-Mouth_LookingTime_AllSubs.Reactive(subj,:);
    
    Mouth_LookingTime_TrialNumber.Predictive(subj,1)=length(find(Mouth_LookingTime.Trials(:,1)==1));
    Mouth_LookingTime_TrialNumber.Predictive(subj,2)=length(find(Mouth_LookingTime.Trials(:,2)==1));
    Mouth_LookingTime_TrialNumber.Predictive(subj,3)=length(find(Mouth_LookingTime.Trials(:,3)==1));
    Mouth_LookingTime_TrialNumber.Reactive(subj,1)=length(find(Mouth_LookingTime.Trials(:,1)==0));
    Mouth_LookingTime_TrialNumber.Reactive(subj,2)=length(find(Mouth_LookingTime.Trials(:,2)==0));
    Mouth_LookingTime_TrialNumber.Reactive(subj,3)=length(find(Mouth_LookingTime.Trials(:,3)==0));
    Mouth_LookingTime_TrialNumber.Invalid(subj,1)=length(find(isnan(Mouth_LookingTime.Trials(:,1))));
    Mouth_LookingTime_TrialNumber.Invalid(subj,2)=length(find(isnan(Mouth_LookingTime.Trials(:,2))));
    Mouth_LookingTime_TrialNumber.Invalid(subj,3)=length(find(isnan(Mouth_LookingTime.Trials(:,3))));
    Mouth_LookingTime_TrialNumber.Total(subj,:)=Mouth_LookingTime_TrialNumber.Predictive(subj,:)+ Mouth_LookingTime_TrialNumber.Reactive(subj,:);
end

%Save Trial Number
save([out, 'Looking\TrialNumber'],'LookingTime_TrialNumber')

save([out, 'Looking\LookingTime_Percentage'],'LookingTime_AllSubs')
save([out, 'Looking\LookingTime_Percentage'],'LookingTime_TrialNumber', '-append')

save([out, 'Looking\Table_LookingTime_Percentage'],'Table_LookingTime_AllSubs')
save([out, 'Looking\Table_LookingTime_Percentage'],'Table_LookingTime_TrialNumber', '-append')

save([out, 'Looking\Mouth_LookingTime_Percentage'],'Mouth_LookingTime_AllSubs')
save([out, 'Looking\Mouth_LookingTime_Percentage'],'Mouth_LookingTime_TrialNumber', '-append')

save([out, 'Looking\LT_OutDataPerVideo'], 'LT_OutDataPerVideo')
