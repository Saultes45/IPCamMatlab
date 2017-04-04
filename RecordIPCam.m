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

%% COM port configuration
PSoC5				= serial(PSoC5COMPort);
PSoC5.BaudRate 		= PSoC5Baudrate; %bauds
PSoC5.Terminator 	= 'CR';
PSoC5.DataBits 		= 8;
PSoC5.Timeout 		= 3; % en s
set(PSoC5,'InputBufferSize',512*10);% we need a large buffer size

%% Init
Timestamp_Vector = zeros(20,1);
fps = zeros(20,1);
CamConnected = 0;
FrameNumber = RequiredTimeInSec*AverageFPS;
retryNumber =0;
occured_error = 0;
NumberOfInconsitentMessages = 0;

%% Check COM port avaiblability if ~isvalid(PSoC5)
AvailableToolBoxes = ver; % We do the check onl if the tool box is avalailable
if ~isempty(find(strcmp({AvailableToolBoxes.Name},'Instrument Control Toolbox'), 1))
    serialInfo = instrhwinfo('serial');
    if ~any(strcmp(serialInfo.AvailableSerialPorts, PSoC5COMPort))
        Message(1,1,0,['The specified COM port ' PSoC5COMPort ' cannot be opened'], 'KO', RunID);
        button = questdlg(['The specified COM port ' PSoC5COMPort ' cannot be opened, Would you like to select an other COM port ?'],...
            'Problem opening the COM port','Sure','No, Abort Aquitition','Sure');
        if strcmp(button, 'Sure') %the user want to select an other COM port
            Message(1,1,0,'User want to select an other COM port', 'UDEF', RunID);
            %find all the available COM Port
            
            if isempty(serialInfo.AvailableSerialPorts)
                msgbox('No other COM port are available','Error','Warn');
                Message(1,1,0,'No other COM port are available', 'KO', RunID);
                occured_error = 1;
            else
                [selection,ok] = listdlg('PromptString','Select a COM port:',...
                    'SelectionMode','single',...
                    'ListString',serialInfo.AvailableSerialPorts);
                if ok == 1
                    PSoC5COMPort = char(serialInfo.AvailableSerialPorts(selection));
                    Message(1,1,0,['User selected : ' PSoC5COMPort], 'OK', RunID);
                else
                    Message(1,1,0,'The user misselected something', 'KO', RunID);
                    occured_error = 1;
                end
            end
        else
            occured_error = 1;
        end
        
    end
    
else
    msgbox('It is impossible to pre check the availability of the COM Port because you don''t have the correct toolbox','Error','Warn');
    Message(1,1,0,'It is impossible to pre check the availability of the COM Port because you don''t have the correct toolbox', 'KO', RunID);
end



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
    try
        fopen(PSoC5);
        Message(1,1,0,['Successful open of : ' num2str(PSoC5.Name) ' with ' num2str(PSoC5.BaudRate) ' bauds'],'OK', RunID);
        flushinput(PSoC5)
    catch error
        disp(error);
        occured_error = 1;
    end
    
    
    
    if occured_error ~= 1
        %% Acquire and store 20 frames. This loop writes the acquired frames to the specified AVI file for future processing.
        for index = 1:FrameNumber
            
            %GNSS fisrt
            GPSRawGetGGA
            
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
    
end

fclose(PSoC5);
%record(PSoC5,'off');
Message(1,1,0,['PSoC : ' num2str(PSoC5COMPort) ' has been closed'],'OK', RunID);

delete(PSoC5);
clear PSoC5;


Message(1,1,0,'End of Matlab', 'UDEF', RunID);