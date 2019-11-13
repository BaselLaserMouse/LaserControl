classdef MPDSaom < laserControl.aom
%%  MPDSaom - control class for OptoElectronic MPDFnCxx opto-acoustic modulators
%
% Example
% M = MPDSaom('COM1');
%
%
% For detailed method docs, please see the aom abstract class. 
%
%
% Rob Campbell - SWC 2019

    properties
        defaultReplyTerminator='' %By default we expect reply strings to terminate with this character
    end

    methods
        function obj = MPDSaom(serialComms)
        % function obj = maitai(serialComms,logObject)
        % serialComms is a string indicating the serial port we should connect to

            if nargin<1
                error('MPDSaom requires one argument: you must supply the COM port as a string')
            end
            
            obj.maxFrequency=1100;
            obj.minFrequency=700;

            fprintf('\nSetting up MPDS AOM communication on serial port %s\n', serialComms);
            laserControl.clearSerial(serialComms)
            obj.controllerID=serialComms;
            success = obj.connect;

            if ~success
                fprintf('Component MPDS AOM failed to connect over the serial port.\n')
                return
                %TODO: is it possible to delete it here?
            end

      
            %Set the target wavelength to equal the current wavelength
            %obj.targetWavelength=obj.currentWavelength;

            %Report connection and humidity
            fprintf('Connected to MPDS AOM on %s\n', ...
             serialComms)

            
        end %constructor
        
        function delete(obj)
            fprintf('Disconnecting from MPDS AOM device\n');
            if ~isempty(obj.hC) && isa(obj.hC,'serial') && isvalid(obj.hC)
                fprintf('Closing serial communications with MPDS AOM device.\n')
                flushinput(obj.hC) % Ensure buffer is empty
                fclose(obj.hC);
                delete(obj.hC);
            end  
        end %Destructor


        function success = connect(obj)
            obj.hC=serial(obj.controllerID,'BaudRate',57600,'TimeOut',5,...
                'Terminator', obj.defaultReplyTerminator);
            try 
                fopen(obj.hC);
            catch ME
                fprintf(' * ERROR: Failed to connect to MPDSaom:\n%s\n\n', ME.message)
                success=false;
                return
            end

            flushinput(obj.hC) % Just in case
            if isempty(obj.hC) 
                success=false;
            else
                s=true; %TODO - write connection test code
                if s==true
                    success=true;
                else
                    fprintf('Failed to communicate with MPDSaom\n');
                    success=false;
                end
            end
            obj.isAomConnected=success;
        end



        function success = isControllerConnected(obj)
            S=obj.getStatusString;
            if isempty(S)
                success=false;
                return
            end
            success=true;
        end
        
        
        function [AOMReady,msg] = isReady(obj)
            AOMReady=true;
        end

        
        function frequency = readFrequency(obj,statusStr)
            if nargin<2
                statusStr = obj.getStatusString;
            end
            T=regexp(statusStr,' F=(\d+\.\d+) P=','tokens');
            frequency = str2double(T{1}{1});
        end
        

        function success = setFrequency(obj, frequencyInHz)

            % Round requency to two decimal places and send to driver
            frequencyInHz = round(frequencyInHz,2);
            cmd = sprintf('L1F%3.2f',frequencyInHz);
            [s,strReturn]=obj.sendAndReceiveSerial([cmd,char(13)],char(13));
            
            % Issue a warning message if the driver didn't set itself to the desired frequency
            currentFrequency = obj.readFrequency;
            if currentFrequency ~= frequencyInHz
                fprintf('User asked for %0.2f Hz but driver is at %0.2f Hz\n', ...
                    frequencyInHz,currentFrequency)
                success=false;
            else
                success=true;
            end
        end
        

        function AOMPower = readPower(obj,statusStr)
            %Return AOM frequency power in dB
            if nargin<2
                statusStr = obj.getStatusString;
            end
            T=regexp(statusStr,' P=(\d+\.\d+) ','tokens');
            AOMPower = str2double(T{1}{1});
        end
        
        
        function success = setPower(obj, powerIndB)
            % Round requency to two decimal places and send to driver
            powerIndB = round(powerIndB,2);
            cmd = sprintf('L1D%2.2f',powerIndB);
            [s,strReturn]=obj.sendAndReceiveSerial([cmd,char(13)],char(13));
            
            % Issue a warning message if the driver didn't set itself to the desired power
            currentPower = obj.readPower;
            if abs(currentPower-powerIndB)>0.05 %Represented as a 10bit value so may be off by a little
                fprintf('User asked for %0.2f dB but driver is at %0.2f dB\n', ...
                    powerIndB,currentPower)
                success=false;
            else
                success=true;
            end
        end

  
        function AOMID = readAOMID(obj)
        end
        

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        function [success,reply]=sendAndReceiveSerial(obj,commandString,replyTerminator,waitForReply)
            % Send a serial command and optionally read back the reply 
            if nargin<3 && isempty(replyTerminator)
                replyTerminator=obj.defaultReplyTerminator;
            end

            if nargin<4
                waitForReply=true;
            end

            if isempty(commandString) || ~ischar(commandString)
                reply='';
                success=false;
                return
            end

            obj.hC.Terminator = replyTerminator;

            fprintf(obj.hC,commandString);

            if ~waitForReply
                reply=[];
                success=true;
                if obj.hC.BytesAvailable>0
                    fprintf('Not waiting for reply by there are %d BytesAvailable\n',obj.hC.BytesAvailable)
                end
                return
            end

            reply=fgets(obj.hC);
            doFlush=1;
            if obj.hC.BytesAvailable>0
                if doFlush
                    fprintf('Read in from the MPDSaom buffer using command "%s" but there are still %d BytesAvailable. Flushing.\n', ...
                        commandString, obj.hC.BytesAvailable)
                    flushinput(obj.hC)
                else
                    fprintf('Read in from the MPDSaom buffer using command "%s" but there are still %d BytesAvailable. NOT FLUSHING.\n', ...
                        commandString, obj.hC.BytesAvailable)
                end
            end
            obj.hC.Terminator = obj.defaultReplyTerminator;

            if ~isempty(reply)
                reply(end)=[];
            else
                msg=sprintf('MPDSaom serial command %s did not return a reply\n',commandString);
                success=false;
                return
            end

            success=true;
        end


    end %close methods


    

    % MPDS-specific
    methods
        function success = enableBlanking(obj)
            cmd = sprintf('L1D%2.2f',powerIndB);
            [s,strReturn]=obj.sendAndReceiveSerial([cmd,char(13)],char(13));
        end
        function success = disableBlanking(obj)
        end

    end % MPDS-specific

    % MPDS-specific hidden
    methods (Hidden=true)
        function statusStr = getStatusString(obj)
            % Get the status string
            [~,statusStr]=obj.sendAndReceiveSerial('S','?');
            statusStr = statusStr(3:end-2); %Just to trim extra char returns
        end

        function reset(obj)
            fprintf(obj.hC,'M');
        end
    end % hidden methods

    
end %close classdef
