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
                'Terminator', 'CR');
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
        

        function success = setFrequency(obj, frequencyInMHz)

            % Round requency to two decimal places and send to driver
            frequencyInMHz = round(frequencyInMHz,2);
            cmd = sprintf('L1F%3.2f',frequencyInMHz);
            [s,strReturn]=obj.sendAndReceiveSerial(cmd);
            
            % Issue a warning message if the driver didn't set itself to the desired frequency
            currentFrequency = obj.readFrequency;
            if currentFrequency ~= frequencyInMHz
                fprintf('User asked for %0.2f MHz but driver is at %0.2f MHz\n', ...
                    frequencyInMHz,currentFrequency)
                success=false;
            else
                success=true;
            end
        end
        
        function AOMPower = readPower(obj,statusStr)
            if nargin<2
                statusStr=[];
            end
            AOMPower = obj.readPower_dB(statusStr);
        end
        function success = setPower(obj,powerIn_dB)
            success = obj.setPower_dB(powerIn_dB);
        end


        function AOMPower = readPower_dB(obj,statusStr)
            %Return AOM frequency power in dB
            if nargin<2 || isempty(statusStr)
                statusStr = obj.getStatusString;
            end
            T=regexp(statusStr,' P=(\d+\.\d+) ','tokens');
            AOMPower = str2double(T{1}{1});
        end
        
        
        function success = setPower_dB(obj, powerIn_dB)
            % Round requency to two decimal places and send to driver
            powerIn_dB = round(powerIn_dB,2);
            cmd = sprintf('L1D%2.2f',powerIn_dB);
            [s,strReturn]=obj.sendAndReceiveSerial(cmd);
            
            % Issue a warning message if the driver didn't set itself to the desired power
            currentPower = obj.readPower;
            if abs(currentPower-powerIn_dB)>0.05 %Represented as a 10bit value so may be off by a little
                fprintf('User asked for %0.2f dB but driver is at %0.2f dB\n', ...
                    powerIn_dB,currentPower)
                success=false;
            else
                success=true;
            end
        end


        function AOMPower = readPower_raw(obj,statusStr)
            %Return AOM frequency power in raw value from register (0 to 1023)
            if nargin<2
                statusStr = obj.getStatusString
            end
            T=regexp(statusStr,' P=(\d+\.\d+) ','tokens');
            AOMPower = str2double(T{1}{1});
        end
        
                
        function success = setPower_raw(obj, powerIn_raw)
            % Round requency to two decimal places and send to driver
            if powerIn_raw<0 || powerIn_raw>1023
                fprintf('Power value out of range\n')
                return
            end
            cmd = sprintf('L1P%04d',powerIn_raw);
            [s,strReturn]=obj.sendAndReceiveSerial(cmd);
            outStr=obj.nudgePowerUp;
            currentPower = regexp(outStr,'P=(\d+)\(','tokens');
            currentPower = str2double(currentPower{1}{1});
            if currentPower == powerIn_raw
                success=true;
            else
                fprintf('User requested power=%d but power is %d\n',...
                    powerIn_raw,currentPower)
                success=false;
            end
        end

  
        function AOMID = readAOMID(obj)
        end
        

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        function [success,reply]=sendAndReceiveSerial(obj,commandString,waitForReply)
            % Send a serial command and optionally read back the reply 
            if nargin<3
                waitForReply=true;
            end

            if isempty(commandString) || ~ischar(commandString)
                reply='';
                success=false;
                return
            end

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

            if ~isempty(reply)
                reply(end)=[];
            else
                msg=sprintf('MPDSaom serial command %s did not return a reply\n',commandString);
                success=false;
                return
            end

            success=true;
        end

        % Serial read command for the weird commands that don't use a CR and return a question mark
        function outStr = nonStandardSerial(obj,commandString)
            obj.hC.Terminator='';
            fprintf(obj.hC,commandString); %Because this command does not need a CR
            obj.hC.Terminator='?'; % Yeah...
            outStr = fgets(obj.hC);
            obj.hC.Terminator='CR';
        end
    end %close methods


    

    % MPDS-specific
    methods

        function success = disableAOMBlanking(obj)
            obj.sendAndReceiveSerial('L0I0O0');
            success = ~obj.readAOMBlankingState;
        end

        function success = enableAOMBlanking(obj)
            obj.sendAndReceiveSerial('L0I1O1');
            success = obj.readAOMBlankingState;
        end

        function state = readAOMBlankingState(obj,statusStr)
            if nargin<2
                statusStr = obj.getStatusString;
            end
            if ~isempty(findstr(statusStr,'Blanking ON '))
                state=true;
            else
                state=false;
            end
        end


        % Nudge commands for frequency and power (return to CLI the current values)
        function nudgeFreqUp(obj)
            str=obj.nonStandardSerial('6');
            [a,b]=regexp(str,'\d+\.\d+ MHz');
            fprintf('%s\n',str(a:b))
        end
        function nudgeFreqDown(obj)
            str=obj.nonStandardSerial('4');
            [a,b]=regexp(str,'\d+\.\d+ MHz');
            fprintf('%s\n',str(a:b))
        end

        function varargout=nudgePowerUp(obj)
            str=obj.nonStandardSerial('8');
            [a,b]=regexp(str,'P.*\)');

            % Optional output return because it seems we have to use this to read the raw power
            % value. Stupidly, there is no other way that I can see. 
            if nargout>0
                varargout{1}=str(a:b);
            else
               fprintf('%s\n',str(a:b))
            end
        end
        function nudgePowerDown(obj)
            str=obj.nonStandardSerial('2');
            [a,b]=regexp(str,'P.*\)');
            fprintf('%s\n',str(a:b))
        end
    end % MPDS-specific

    % MPDS-specific hidden
    methods (Hidden=true)
        function statusStr = getStatusString(obj)
            % Get the status string. Annoying code because this command follows
            % a different standard to the rest
            statusStr = obj.nonStandardSerial('S');
            statusStr = statusStr(3:end-2); %Just to trim extra char returns
        end

        function reset(obj)
            fprintf(obj.hC,'M'); %This command needs no CR
        end
    end % hidden methods

    
end %close classdef
