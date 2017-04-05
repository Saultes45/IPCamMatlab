%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Main
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%% Clear;
close all;
clear;
clc;


%% This test ID, it is very important not to modify this
formatOut = 'yyyy-mm-dd--HH-MM-SS-FFF';
DateFormatFile = 'HH_MM_SS.FFF';
RunID = datestr(now,formatOut); %datevec

%% Start using the log file
Message(1,1,1,'Asking for new file', 'UDEF',RunID); %Creating a new log file (by using the third "1" in the function parameters)
Message(1,1,0,['Local directory is : ' cd ], 'UDEF', RunID); %Loging the cd

GetParameters;

%% Init
Timestamp_Vector = zeros(20,1);
fps = zeros(20,1);
CamConnected = 0;
FrameNumber = RequiredTimeInSec*AverageFPS;
retryNumber =0;



%% Preparing video capture
while retryNumber  < 10 && CamConnected == 0
    try
        cam = ipcam('http://192.168.0.100:80/mjpg/video.mjpg', 'root', 'iod.1234', 'Timeout', 10);
        %cam = ipcam('http://169.254.72.83:80/mjpg/video.mjpg', 'root', 'iod.1234', 'Timeout', 10);
        CamConnected = 1;
    catch error
        retryNumber = retryNumber + 1;
        Message(1,1,0,['Connection to IP Camera Timeout, try ' num2str(retryNumber) ' on ' num2str(10)], 'KO', RunID);
    end
end

if retryNumber < 10
    Message(1,1,0,'IP Camera Sucessfully Connected', 'OK', RunID);
    %IP = '169.254.72.83:80';
    IP = '192.168.0.100:80';
    vidWriter = VideoWriter([RunID '_' strrep(IP,':', '-') '_Frames.avi']); % dynamic IP adress please
    open(vidWriter);
    
    %     try GPS
    
    
    %% Acquire and store 20 frames. This loop writes the acquired frames to the specified AVI file for future processing.
    for index = 1:FrameNumber
        
        
        
        % Acquire a single frame.
        
        [Image, ts] = snapshot(cam);
        Image = insertText(Image,[ceil(size(Image,1)/2),10],datestr(ts,formatOut));
        if index>1
            dt = datevec(datenum(ts) - Timestamp_Vector (index-1));
            fps(index) = 1/dt(6);
        else
            fps(index) = 0;
        end
        Image = insertText(Image,[ceil(size(Image,1)/2),40],['FPS:' num2str(fps(index))]);
        if (exist('UTC_Time', 'var') == 1) % 1=> variable in workspace
            Image = insertText(Image,[ceil(size(Image,1)/2),60],['GPS UTC:' num2str(UTC_Time)]);
        end
        % Write frame to video.
        writeVideo(vidWriter, Image);
        % Clear image
        clear Image
        
        %Log the timestamp
        Timestamp_Vector (index) = datenum(ts);
        
        % if vidWriter is too big, svae it and start another one
    end
    close(vidWriter);
    Message(1,1,0,'AVI file saved', 'OK', RunID);
    clear cam ts index
end

%save all the frame times in a excel file
xlswrite([RunID '_' strrep(IP,':', '-') '_FramesTimeStamp.xlsx'],[Timestamp_Vector fps]);
Message(1,1,0,'Excel File Saved', 'OK', RunID);

Message(1,1,0,'End of Matlab', 'UDEF', RunID);