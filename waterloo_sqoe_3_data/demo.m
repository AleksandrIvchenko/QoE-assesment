clear; clc;

Full{:,19} = [];
%C{5,5} = []
%Full = int8(zeros(100));
%Full = cell(450,1);
global_count=0;

load('sourceVideo.mat');
load('actualBitrate.mat');
sourceNames = sourceVideo.name;
%disp(sourceVideo.fps)
tVideo = 10; % 10 seconds test video (without stalling)
segmentDuration = 2;

%class(sourceNames)
%disp(sourceVideo.mat)
%xlswrite('toPy/SourseNames',sourceNames)
 
count = 1;
for iii = 1:length(sourceNames)
    %
    load(['representations/' sourceNames{iii} '.mat']);
    load(['streamInfo/' sourceNames{iii} '.mat']);
    bitrateLadder = eval(['actualBitrate.' sourceNames{iii}]);
    name = sourceNames{iii};
    %disp(representation{:,2})
    %celldisp(representation)
    for jjj = 1:length(streamInfo)
        %Цикл проходит 450 раз - по количеству итоговых видео
        Full{1,1} = 'Name';
        Full{global_count + jjj+1,1} = name;
                
        videoInfo = streamInfo(jjj, :);
        %disp(videoInfo);
        fps = double(videoInfo{1});
        Full{1,2} = 'FPS';
        Full{global_count + jjj+1,2} = fps;
        
        %additional information about video info
        Full{1,20} = 'VideoQualityLevel';
        Full{global_count + jjj+1,20} = videoInfo{2};
        
        %Full{1,15} = 'VideoQualityLevel';
        %Full{global_count + jjj+1,15} = videoInfo{2};
        
        %        
        selectedRep = double(videoInfo{2});%DASH configuration/profile description (bitrateLadder)
        bitrates = [];
        seqPSNR = [];
                
        % stalling duration
        stallTime = (sum(streamInfo{jjj,5})+streamInfo{jjj,3}) / fps;
        % overall duration of the streaming session
        duration = (sum(streamInfo{jjj,5})+streamInfo{jjj,3}) / fps + tVideo;
        
        Full{1,3} = 'stallTime';
        Full{1,4} = 'duration';
        Full{global_count + jjj+1,3} = stallTime;
        Full{global_count + jjj+1,4} = duration;
        
        switching = (videoInfo{2}(2:end) ~= videoInfo{2}(1:end-1));%сдвиг на 1 влево
        
        Full{1,5} = 'switching';
        Full{global_count + jjj+1,5} = switching;
               
        mw = (1+2*fps*(1:4)).*switching;
        % magnitude of switching in kbps - переключение между потоками ABS 
        mw(mw == 0) = [];
        
        Full{1,6} = 'SwithcingMagnitide';
        Full{global_count + jjj+1,6} = mw;        
        
        for kkk = 1:length(selectedRep)
            b = bitrateLadder(selectedRep(kkk)+1);
            bitrates = [bitrates, b]; %#ok 
            
            load(['VQAResults/PSNR/' sourceNames{iii} '/' representation{selectedRep(kkk)+2, 5}]);
            
            %disp(kkk);
            abc = representation{selectedRep(kkk)+2, 5};
            %disp(abc)
            Full{1,14+kkk} = 'Representation';%Начиная с 15=14+1
            Full{global_count + jjj+1,14+kkk} = abc;
            
            segmentPSNR = psnr((kkk-1)*segmentDuration*fps+1:kkk*segmentDuration*fps);
            seqPSNR = [seqPSNR; segmentPSNR]; %#ok Покадровое PSNR, 10 сек*fps, 240-300 значений
        end
        
        Full{1,7} = 'bitrates';
        Full{global_count + jjj+1,7} = bitrates; 
        
        Full{1,8} = 'seqPSNR per frame';
        seqPSNR_to_table = seqPSNR.';
        
        Full{global_count + jjj+1,8} = seqPSNR_to_table; 
        
        % duration of initial buffering
        tInit = double(videoInfo{3}) / fps;
        Full{1,9} = 'duration of initial buffering';
        Full{global_count + jjj+1,9} = tInit; 
        % duration of stalling events in second
        lStall = double(videoInfo{5}) ./ fps;
        Full{1,10} = 'duration of stalling events in second';
        Full{global_count + jjj+1,10} = lStall; 
        % number of stalling events
        nStall = length(lStall);
        Full{1,11} = 'number of stalling events';
        Full{global_count + jjj+1,11} = nStall; 
        % average duration of stalling event
        tStall = mean(lStall);
        if (isnan(tStall))
            tStall = 0;
        end
        Full{1,12} = 'average duration of stalling event';
        Full{global_count + jjj+1,12} = tStall; 
        
        m_PSNR = mean(seqPSNR);
        Q_PSNR(1, count) = mean(seqPSNR); %#ok
        Full{1,13} = 'mean(seqPSNR)';
        Full{global_count + jjj+1,13} = m_PSNR; 
        
        %{'videoName' 'inputYUV' 'encodedMP4' 'decodedYUV'}
        %Full{1,15} = 'Q_PSNR_per_seq';%Просто массив всех средних пснр
        %Full{global_count + jjj+1,15} = Q_PSNR;
        
        count = count + 1;
    end
    global_count = global_count + length(streamInfo);
 
%     save(['VQAResult/PSNR/' sourceNames{iii} '.mat'], 'Q_PSNR');
%     clear Q_PSNR;
    count = 1; 
end

% To obtain 450 results, we need to concatenate results of each video
% content. See sample code below:
QO_PSNR = [];
for iii = 1:length(sourceNames)
    load(['VQAResults/PSNR/' sourceNames{iii}]);
    QO_PSNR = [QO_PSNR; Q_PSNR']; %#ok
end

load('MOS.mat');
MOS_values = MOS;
disp(MOS_values(1));
for iii = 1:length(MOS_values)
   Full{1,14} = 'MOS';
   Full{iii +1 ,14} = MOS_values(iii); %in the other way the table full has not the last mos
end

save('Full.mat', 'Full');

%csvwrite('Full.mat', Full)

%fid = fopen('110416.csv','wt');
% if fid>0
%     for k=1:size(Full,1)
%         fprintf(fid,'%s,%f\n',Full{k,:});
%     end
%     fclose(fid);
% end

cell2csv('Full.csv', Full)