function rb_PCA14_TM_BM_OnsetPrediction(direc, datatotal, timing, out)
%Calculates Onset Prediction

cd(direc) %cd brengt ja naar een bepaalde directory, zet de directory met je scripts en data file tussen de (' ')
subjtotal=size(unique(datatotal(:,2)),1)-1; %-1 because one is the heading "subject";;


AOI={'AOI1','AOI2','AOI3'};
%%
for subj=1:subjtotal
    if subj<10, subjname=['Pil0',num2str(subj)];  %plak het nummer dat 'i' is op dit moment, vast aan de 'string' 'Pil0'
    else subjname=['Pil',num2str(subj)];
    end
    clearvars -except subj subjname AOI subjtotal direc datatotal timing out PredictiveLook_AllSubs PredictiveLook_TrialNumber Table_PredictiveLook_AllSubs Table_PredictiveLook_TrialNumber Mouth_PredictiveLook_AllSubs Mouth_PredictiveLook_TrialNumber
    
    %Find data of that participant
    index=find(strcmpi(datatotal(:,2),subjname));
    data=datatotal(index,:);
    %find trial number
    trialtotal=unique(data(:,1));
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
            predictive_RT=[];
            n=1;
            m=1;
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
                        predictive_RT(m,1)=middlepoint-Fix_Onset;
                        m=m+1;
                    end
                    end
                    n=n+1;
                end
            end
            
            if isempty(predictive_RT)==0
                PredictiveLook.Predictive(trl,aoi)=max(predictive_RT);
            else
                PredictiveLook.Predictive(trl,aoi)=NaN;
            end
            % Store the raw data
            PredictiveLook.ParticipantData.(AOI{aoi}){trl,1}=ParticipantData;
        end
        
        if table==1
            Table_PredictiveLook.Predictive(table_trl,:)= PredictiveLook.Predictive(trl,:);
            table_trl=table_trl+1;
        elseif mouth==1
            Mouth_PredictiveLook.Predictive(mouth_trl,:)= PredictiveLook.Predictive(trl,:);
            mouth_trl= mouth_trl+1;
        end
        
        
    end
    %save the participants average into this variable
    PredictiveLook_AllSubs(subj,:)=nanmean(PredictiveLook.Predictive);
    PredictiveLook_TrialNumber(subj,1)=sum((~isnan(PredictiveLook.Predictive(:,1))));
    PredictiveLook_TrialNumber(subj,2)=sum((~isnan(PredictiveLook.Predictive(:,2))));
    PredictiveLook_TrialNumber(subj,3)=sum((~isnan(PredictiveLook.Predictive(:,3))));
    
    Table_PredictiveLook_AllSubs(subj,:)=nanmean(Table_PredictiveLook.Predictive);
    Table_PredictiveLook_TrialNumber(subj,1)=sum((~isnan(Table_PredictiveLook.Predictive(:,1))));
    Table_PredictiveLook_TrialNumber(subj,2)=sum((~isnan(Table_PredictiveLook.Predictive(:,2))));
    Table_PredictiveLook_TrialNumber(subj,3)=sum((~isnan(Table_PredictiveLook.Predictive(:,3))));
    
    Mouth_PredictiveLook_AllSubs(subj,:)=nanmean(Mouth_PredictiveLook.Predictive);
    Mouth_PredictiveLook_TrialNumber(subj,1)=sum((~isnan(Mouth_PredictiveLook.Predictive(:,1))));
    Mouth_PredictiveLook_TrialNumber(subj,2)=sum((~isnan(Mouth_PredictiveLook.Predictive(:,2))));
    Mouth_PredictiveLook_TrialNumber(subj,3)=sum((~isnan(Mouth_PredictiveLook.Predictive(:,3))));
end

save([out, '\PredLook\TrialNumber'],'PredictiveLook_TrialNumber')

save([out '\PredLook\PredictiveLook'],'PredictiveLook_AllSubs')
save([out '\PredLook\PredictiveLook'],'PredictiveLook_TrialNumber', '-append')

save([out '\PredLook\Table_PredictiveLook'],'Table_PredictiveLook_AllSubs')
save([out '\PredLook\Table_PredictiveLook'],'Table_PredictiveLook_TrialNumber', '-append')

save([out '\PredLook\Mouth_PredictiveLook'],'Mouth_PredictiveLook_AllSubs')
save([out '\PredLook\Mouth_PredictiveLook'],'Mouth_PredictiveLook_TrialNumber', '-append')

