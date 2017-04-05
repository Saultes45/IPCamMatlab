%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Getting the parameters from the .ini file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% File opening
Message(1,1,0,'Trying to find the .ini file', 'UDEF', RunID);
try
    %% looking for the first .ini file in the current folder
    %make a list of the files and folders in the selected path
    MyDirInfo = dir([cd '\*.ini']);
    
    if ~isempty(MyDirInfo)
        
        if size(MyDirInfo,1) == 1
            Message(1,0,0,'The .ini file have been found', 'OK', RunID);
        else %there is more than one txt file on the path, so we take the first one
            Message(1,0,0,'Multiple .ini file have been found, taking the first one', 'UDEF', RunID);
        end
        
        
        fid = fopen( [cd '\' MyDirInfo(1).name], 'r' );
        Message(1,1,0,['.ini file opened with fid : ' num2str(fid)], 'OK', RunID);
        
        i = 1;
        tline = fgetl(fid);
        Text_from_file{i} = tline;
        while ischar(tline)
            i = i+1;
            tline = fgetl(fid);
            Text_from_file{i} = tline;
        end
        
        fclose(fid); % closing the file
        % clear the fid and line, in some version of MATLAB it causes error to future
        % plots (in GenerateBlankFigures.m) not to clear these variables
        Message(1,1,0,'.ini file closed', 'OK', RunID);
        clear fid;
        clear line;
        
        %%  Parsing the retrived text
        NumberOfImportedParameters = 0;
        for cpt_line = 1 : length(Text_from_file) - 1
            %     if the line begins with an [, we look at the final charater of the
            %     same line (to see if it is a ] )
            if ~strcmp(Text_from_file{cpt_line}(1),'[')
                %                 read the first part before the "=" sign so we've got the name of the variable
                [NameOfTheVariable,ValueOfTheVariable] = strtok(Text_from_file{cpt_line}, '=');
                [~,ValueOfTheVariable] = strtok(Text_from_file{cpt_line}, '=');
                NameOfTheVariable = strtrim(NameOfTheVariable);
                ValueOfTheVariable = strtrim(ValueOfTheVariable(2:end));
                if all(ismember(ValueOfTheVariable, '0123456789+-.eEdD')) && length(strfind(ValueOfTheVariable, '.')) < 2%then the string is a number
                    ValueOfTheVariable = str2double(ValueOfTheVariable);
                    eval([ NameOfTheVariable ' = ' num2str(ValueOfTheVariable) ';']);
                else %then the string is NOT a number
                    eval([ NameOfTheVariable ' = ''' ValueOfTheVariable ''';']);
                end
                NumberOfImportedParameters = NumberOfImportedParameters + 1;
            else
                if strcmp(Text_from_file{cpt_line}(end),']')
                    Message(1,1,0,['Section found : ' Text_from_file{cpt_line}(2:end-1)], 'OK', RunID);
                end
            end
        end
        
        
        %% Check the number of parameters imported
        
        %check if the parameter NumberOfParameterToImport has been imported
        if exist('NumberOfParameterToImport', 'var')
            if NumberOfParameterToImport == NumberOfImportedParameters
                Message(1,1,0,[num2str(NumberOfParameterToImport) ' parameters have been imported'], 'OK', RunID);
            else
                
                occured_error = 1;
                Message(1,1,0,['NumberOfParameterToImport (' num2str(NumberOfParameterToImport) ') is different from NumberOfImportedParameters (' num2str(NumberOfImportedParameters) ')'], 'KO', RunID);
            end
            
        else
            occured_error = 1;
            Message(1,1,0,'The variable NumberOfParameterToImport was not found in the .ini file', 'KO', RunID);
        end
        Message(1,1,0,'Parameters imported', 'OK', RunID);
        
    else
        Message(1,0,0,'No .ini files detected in this folder', 'KO', RunID);
        msg = 'No .ini files detected in this folder';
        msgID = 'GetParameters:NoFile';
        throw(MException(msgID,msg));
    end
catch error
    disp(error);
    occured_error = 1;
    Message(1,1,0,'Parameters not imported', 'KO', RunID);
end