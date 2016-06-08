function rb_PCA14_TM_BM_ClosFix(direc, datatotal, timing, out,incstim)
%Calculates Onset Prediction

%RELATIVE VALUE (OnsetFix-HandinAOI)
%ONLY TAKING PREDICTIVE FIXATIONS INTO ACCOUNT AND WITHIN THE PREDICTIVE
%WINDOW

cd(direc) %cd brengt ja naar een bepaalde directory, zet de directory met je scripts en data file tussen de (' ')
subjtotal=size(unique(datatotal(:,2)),1)-1; %-1 because one is the heading "subject";;


AOI={'AOI1','AOI2','AOI3'};
%%
x_all=1; %this index is used to store the information of all videos and subjects in the variable C_OutDataPerVideo

for subj=1:subjtotal
    if subj<10, subjname=['Pil0',num2str(subj)];  %plak het nummer dat 'i' is op dit moment, vast aan de 'string' 'Pil0'
    else subjname=['Pil',num2str(subj)];
    end
    clearvars -except CF_OutDataPerVideo incstim x_all subj subjname AOI subjtotal direc datatotal timing out PredictiveLook_AllSubs PredictiveLook_TrialNumber Table_PredictiveLook_AllSubs Table_PredictiveLook_TrialNumber Mouth_PredictiveLook_AllSubs Mouth_PredictiveLook_TrialNumber
    
    %Find data of that participant
    index=find(strcmpi(datatotal(:,2),subjname));
    data=datatotal(index,:);
    %find trial number
    trialtotal=unique(data(:,1));
    table_trl=1;
    mouth_trl=1;
    
    trl=1;
    
    for trl_all=1:length(trialtotal)
        trialnumber=trialtotal(trl_all);
        table=0;
        mouth=0;
        
        %istrl determines whether we are counting a trial or not (was added
        %to enable selection of trials for some of the videos)
        istrl=0;
        
        %get the video of that trial
        i_begtrl=min(find((strcmp(trialnumber,data(:,1)))));
        vidnum=str2num(data{i_begtrl,4}(1:end-5));
        
        for aoi=1:3; %Action Step 1,2,3
            clear stimulus
            ParticipantData={};
            AllFixDiff=[];
            n=1;
            m=1;
            for rij=1:size(data,1)
                if strcmpi(data(rij,2),subjname) && strcmpi(data(rij,1),trialnumber) && (data{rij,8}==aoi)==1
                    stimulus=data{rij,4};
                    stimulus=str2num(stimulus(1:end-5)); %Make a number out of the string which can then be compared to the timing file
                    
                    if ismember(stimulus,incstim)
                        istrl=1; %take this trial with you :)
                        
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
                        %Calculate difference between Fix Onset and
                        %TimingMiddlepoint
                        Fix_Onset=ParticipantData{n,11};
                        Fix_Dur=ParticipantData{n,12};
                        if Fix_Dur>=100 && Fix_Onset<middlepoint && Fix_Onset>=beginpoint %Is the fixation is at least 100ms? And does it ly in the predictive window?
                            AllFixDiff(m,1)=Fix_Onset-middlepoint;
                            m=m+1;
                        end
                        n=n+1;
                    end
                end
            end
            
            if istrl==1
                if ~isempty(AllFixDiff)
                    [minv,ind]= (min(abs(AllFixDiff)));
                    ClosFix.Diff(trl,aoi)=AllFixDiff(ind); %relative
                    %ClosFix.Diff(trl,aoi)=abs(AllFixDiff(ind)); %absolute
                    
                else
                    ClosFix.Diff(trl,aoi)=NaN;
                end
                
                %Store the Video Number to later be able to analyse videos
                %separately:
                ClosFix.VidNum(trl,aoi)=vidnum; %this stores which video has been seen so that we can later group videos together
                
                % Store the raw data
                ClosFix.ParticipantData.(AOI{aoi}){trl,1}=ParticipantData;
                
                %Write this off into large datafile
                CF_OutDataPerVideo(x_all,1)=subj;
                CF_OutDataPerVideo(x_all,2)=vidnum;
                CF_OutDataPerVideo(x_all,3)=aoi;
                CF_OutDataPerVideo(x_all,4)=ClosFix.Diff(trl,aoi);
                
                x_all=x_all+1;
            end
            
        end
        if istrl==1
            if table==1
                Table_CF.Diff(table_trl,:)= ClosFix.Diff(trl,:);
                table_trl=table_trl+1;
            elseif mouth==1
                Mouth_CF.Diff(mouth_trl,:)= ClosFix.Diff(trl,:);
                mouth_trl= mouth_trl+1;
            end
            trl=trl+1;
        end
    end
    %save the participants average into this variable
    CF_AllSubs(subj,:)=nanmean(ClosFix.Diff);
    CF_TrialNumber(subj,1)=sum((~isnan(ClosFix.Diff(:,1))));
    CF_TrialNumber(subj,2)=sum((~isnan(ClosFix.Diff(:,2))));
    CF_TrialNumber(subj,3)=sum((~isnan(ClosFix.Diff(:,3))));
    
    Table_CF_AllSubs(subj,:)=nanmean(Table_CF.Diff);
    Table_CF_TrialNumber(subj,1)=sum((~isnan(Table_CF.Diff(:,1))));
    Table_CF_TrialNumber(subj,2)=sum((~isnan(Table_CF.Diff(:,2))));
    Table_CF_TrialNumber(subj,3)=sum((~isnan(Table_CF.Diff(:,3))));
    
    Mouth_CF_AllSubs(subj,:)=nanmean(Mouth_CF.Diff);
    Mouth_CF_TrialNumber(subj,1)=sum((~isnan(Mouth_CF.Diff(:,1))));
    Mouth_CF_TrialNumber(subj,2)=sum((~isnan(Mouth_CF.Diff(:,2))));
    Mouth_CF_TrialNumber(subj,3)=sum((~isnan(Mouth_CF.Diff(:,3))));
end
save([out, '\ClosFix\VideosIncluded'],'incstim')

save([out, '\ClosFix\TrialNumber'],'CF_TrialNumber')

save([out '\ClosFix\ClosestFix'],'CF_AllSubs')
save([out '\ClosFix\ClosestFix'],'CF_TrialNumber', '-append')

save([out '\ClosFix\Table_ClosestFix'],'Table_CF_AllSubs')
save([out '\ClosFix\Table_ClosestFix'],'Table_CF_TrialNumber', '-append')

save([out '\ClosFix\Mouth_ClosestFix'],'Mouth_CF_AllSubs')
save([out '\ClosFix\Mouth_ClosestFix'],'Mouth_CF_TrialNumber', '-append')

save([out, '\ClosFix\CF_OutDataPerVideo'], 'CF_OutDataPerVideo')

