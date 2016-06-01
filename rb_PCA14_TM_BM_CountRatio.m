function rb_PCA14_TM_BM_CountRatio(direc, datatotal, timing, out)
%COUNT RATIO PCA 14

%%
cd(direc) %cd brengt ja naar een bepaalde directory, zet de directory met je scripts en data file tussen de (' ')
subjtotal=size(unique(datatotal(:,2)),1)-1; %-1 because one is the heading "subject";


AOI={'AOI1','AOI2','AOI3'};
%%
for subj=1:subjtotal
    if subj<10, subjname=['Pil0',num2str(subj)];  %plak het nummer dat 'i' is op dit moment, vast aan de 'string' 'Pil0'
    else subjname=['Pil',num2str(subj)];
    end
    
    clearvars -except subj AOI subjname direc datatotal timing out subjtotal PredictiveCountRatio_AllSubs PredictiveCountRatio_TrialNumber Table_PredictiveCountRatio_AllSubs Table_PredictiveCountRatio_TrialNumber Mouth_PredictiveCountRatio_AllSubs Mouth_PredictiveCountRatio_TrialNumber
    
    %Find the data belonging to that subject
    index=find(strcmpi(datatotal(:,2),subjname));
    data=datatotal(index,:);
    %determine the amount of trials
    trialtotal=unique(data(:,1));
    %restart the counter for table and mouth trials
    table_trl=1;
    mouth_trl=1;
    
    for trl=1:length(trialtotal)
        trialnumber=trialtotal(trl);
        table=0;
        mouth=0;
        for aoi=1:3; %Action Step 1,2,3
            clear stimulus
            ParticipantData={};
            Fix_Onset=[];
            n=1;
            p_count=0;
            r_count=0;
            for rij=1:size(data,1)
                if strcmpi(data(rij,2),subjname) && strcmpi(data(rij,1),trialnumber) && (data{rij,8}==aoi)==1 
                    stimulus=data{rij,4};
                    stimulus=str2num(stimulus(1:end-5)); %Make a number out of the string which can then be compared to the timing file
                    
                    ParticipantData(n,:)=data(rij,:);
                    
                    if stimulus>=200
                        table=1; %table trials
                        mouth=0;
                    elseif stimulus>=100 && stimulus<200
                        table=0; %mouth trials
                        mouth=1;
                    end
                    
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
                    if Fix_Dur>=100 %Is the fixation is at least 100ms
                    if Fix_Onset< middlepoint && Fix_Onset>=beginpoint %Predictive only
                        p_count=p_count+1;
                    elseif Fix_Onset>= middlepoint && Fix_Onset<endpoint %Reactive only
                        r_count=r_count+1;
                    end
                    end
                    n=n+1;
                end
            end
            if p_count==0 && r_count==0
                PredictiveCountRatio.SortTrial(trl,aoi)=NaN; %invalid
            elseif p_count>0
                PredictiveCountRatio.SortTrial(trl,aoi)=1; %predictive trial
            else 
                PredictiveCountRatio.SortTrial(trl,aoi)=0; %reactive trial
            end
            % Store the raw data
            PredictiveCountRatio.ParticipantData.(AOI{aoi}){trl,1}=ParticipantData;
        end
        
        if table==1
            Table_PredictiveCountRatio.SortTrial(table_trl,:)=PredictiveCountRatio.SortTrial(trl,:);
            table_trl=table_trl+1;
        elseif mouth==1
            Mouth_PredictiveCountRatio.SortTrial(mouth_trl,:)=PredictiveCountRatio.SortTrial(trl,:);
            mouth_trl= mouth_trl+1;
        end
    end
    
    %save the participants average into this variable
        
    PredictiveCountRatio_TrialNumber.Predictive(subj,1)= length(find(PredictiveCountRatio.SortTrial(:,1)==1));
    PredictiveCountRatio_TrialNumber.Predictive(subj,2)=length(find(PredictiveCountRatio.SortTrial(:,2)==1));
    PredictiveCountRatio_TrialNumber.Predictive(subj,3)=length(find(PredictiveCountRatio.SortTrial(:,3)==1));
    PredictiveCountRatio_TrialNumber.Reactive(subj,1)= length(find(PredictiveCountRatio.SortTrial(:,1)==0));
    PredictiveCountRatio_TrialNumber.Reactive(subj,2)=length(find(PredictiveCountRatio.SortTrial(:,2)==0));
    PredictiveCountRatio_TrialNumber.Reactive(subj,3)=length(find(PredictiveCountRatio.SortTrial(:,3)==0));
    PredictiveCountRatio_TrialNumber.Invalid(subj,1)= length(find(isnan(PredictiveCountRatio.SortTrial(:,1))));
    PredictiveCountRatio_TrialNumber.Invalid(subj,2)=length(find(isnan(PredictiveCountRatio.SortTrial(:,2))));
    PredictiveCountRatio_TrialNumber.Invalid(subj,3)=length(find(isnan(PredictiveCountRatio.SortTrial(:,3))));
    PredictiveCountRatio_TrialNumber.Total(subj,:)=PredictiveCountRatio_TrialNumber.Predictive(subj,:)+PredictiveCountRatio_TrialNumber.Reactive(subj,:);
    
    
    %%%%%%%%%%%%% This value was adpated in v7 to represent a relative frequency
    PredictiveCountRatio_AllSubs.Ratio(subj,:)=PredictiveCountRatio_TrialNumber.Predictive(subj,:)./(PredictiveCountRatio_TrialNumber.Predictive(subj,:)+PredictiveCountRatio_TrialNumber.Reactive(subj,:));
    
    %save the participants average into this variable
    Table_PredictiveCountRatio_TrialNumber.Predictive(subj,1)= length(find(Table_PredictiveCountRatio.SortTrial(:,1)==1));
    Table_PredictiveCountRatio_TrialNumber.Predictive(subj,2)=length(find(Table_PredictiveCountRatio.SortTrial(:,2)==1));
    Table_PredictiveCountRatio_TrialNumber.Predictive(subj,3)=length(find(Table_PredictiveCountRatio.SortTrial(:,3)==1));
    Table_PredictiveCountRatio_TrialNumber.Reactive(subj,1)= length(find(Table_PredictiveCountRatio.SortTrial(:,1)==0));
    Table_PredictiveCountRatio_TrialNumber.Reactive(subj,2)=length(find(Table_PredictiveCountRatio.SortTrial(:,2)==0));
    Table_PredictiveCountRatio_TrialNumber.Reactive(subj,3)=length(find(Table_PredictiveCountRatio.SortTrial(:,3)==0));
    Table_PredictiveCountRatio_TrialNumber.Invalid(subj,1)= length(find(isnan(Table_PredictiveCountRatio.SortTrial(:,1))));
    Table_PredictiveCountRatio_TrialNumber.Invalid(subj,2)=length(find(isnan(Table_PredictiveCountRatio.SortTrial(:,2))));
    Table_PredictiveCountRatio_TrialNumber.Invalid(subj,3)=length(find(isnan(Table_PredictiveCountRatio.SortTrial(:,3))));
    Table_PredictiveCountRatio_TrialNumber.Total(subj,:)=Table_PredictiveCountRatio_TrialNumber.Predictive(subj,:)+Table_PredictiveCountRatio_TrialNumber.Reactive(subj,:);
    
        
    %%%%%%%%%%%%% This value was adpated in v7 to represent a relative frequency
    Table_PredictiveCountRatio_AllSubs.Ratio(subj,:)=Table_PredictiveCountRatio_TrialNumber.Predictive(subj,:)./(Table_PredictiveCountRatio_TrialNumber.Predictive(subj,:)+Table_PredictiveCountRatio_TrialNumber.Reactive(subj,:));
   
    
    %save the participants average into this variable
    Mouth_PredictiveCountRatio_TrialNumber.Predictive(subj,1)= length(find(Mouth_PredictiveCountRatio.SortTrial(:,1)==1));
    Mouth_PredictiveCountRatio_TrialNumber.Predictive(subj,2)=length(find(Mouth_PredictiveCountRatio.SortTrial(:,2)==1));
    Mouth_PredictiveCountRatio_TrialNumber.Predictive(subj,3)=length(find(Mouth_PredictiveCountRatio.SortTrial(:,3)==1));
    Mouth_PredictiveCountRatio_TrialNumber.Reactive(subj,1)= length(find(Mouth_PredictiveCountRatio.SortTrial(:,1)==0));
    Mouth_PredictiveCountRatio_TrialNumber.Reactive(subj,2)=length(find(Mouth_PredictiveCountRatio.SortTrial(:,2)==0));
    Mouth_PredictiveCountRatio_TrialNumber.Reactive(subj,3)=length(find(Mouth_PredictiveCountRatio.SortTrial(:,3)==0));
    Mouth_PredictiveCountRatio_TrialNumber.Invalid(subj,1)= length(find(isnan(Mouth_PredictiveCountRatio.SortTrial(:,1))));
    Mouth_PredictiveCountRatio_TrialNumber.Invalid(subj,2)=length(find(isnan(Mouth_PredictiveCountRatio.SortTrial(:,2))));
    Mouth_PredictiveCountRatio_TrialNumber.Invalid(subj,3)=length(find(isnan(Mouth_PredictiveCountRatio.SortTrial(:,3))));
    Mouth_PredictiveCountRatio_TrialNumber.Total(subj,:)=Mouth_PredictiveCountRatio_TrialNumber.Predictive(subj,:)+Mouth_PredictiveCountRatio_TrialNumber.Reactive(subj,:);
        
        
    %%%%%%%%%%%%% This value was adpated in v7 to represent a relative frequency
    Mouth_PredictiveCountRatio_AllSubs.Ratio(subj,:)=Mouth_PredictiveCountRatio_TrialNumber.Predictive(subj,:)./(Mouth_PredictiveCountRatio_TrialNumber.Predictive(subj,:)+Mouth_PredictiveCountRatio_TrialNumber.Reactive(subj,:));
    
end

save([out, 'Count\TrialNumber'],'PredictiveCountRatio_TrialNumber')

save([out, 'Count\PredictiveCountRatio'],'PredictiveCountRatio_AllSubs')
save([out, 'Count\PredictiveCountRatio'],'PredictiveCountRatio_TrialNumber', '-append')

save([out, 'Count\Table_PredictiveCountRatio'],'Table_PredictiveCountRatio_AllSubs')
save([out, 'Count\Table_PredictiveCountRatio'],'Table_PredictiveCountRatio_TrialNumber', '-append')

save([out, 'Count\Mouth_PredictiveCountRatio'],'Mouth_PredictiveCountRatio_AllSubs')
save([out, 'Count\Mouth_PredictiveCountRatio'],'Mouth_PredictiveCountRatio_TrialNumber', '-append')
