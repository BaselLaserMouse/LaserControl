classdef MPDSaom < laserControl.aom
%%  MPDSaom - control class for OptoElectronic MPDFnCxx opto-acoustic modulators
%
% Example
% M = MPDSaom('COM1');
%
%
% For detailed method docs, please see the comments and help text in the aom abstract class. 
%
%
% Rob Campbell - SWC 2019

    methods
        function obj = MPDSaom(serialComms)
        % function obj = maitai(serialComms,logObject)
        % serialComms is a string indicating the serial port we should connect to

            % Define a file name for the settings file
            obj.settingsFname='MPDSaom_settings.mat';

            % Set some values to the AOM tuning parameters in case the user
            % has not yet created a settings file. 
            obj.referenceWavelength=790; %We will tune the the frequency at this wavelength
            obj.referenceFrequency=118;  %This is a default, it can be over-ridden by a saved value
            obj.powerTable=[750,20; 920,20]; %Format: col 1 is wavelength and col 2 is power in dB. Can be loaded from disk.

            obj.friendlyName='MPDS AOM';

            if nargin<1
                error('MPDSaom requires one argument: you must supply the COM port as a string')
            end

            fprintf('\nSetting up MPDS AOM communication on serial port %s\n', serialComms);
            laserControl.clearSerial(serialComms)
            obj.controllerID=serialComms;
            success = obj.connect;


            if ~success
                fprintf('Component MPDS AOM failed to connect over the serial port.\n')
                return
                %TODO: is it possible to delete it here?
            end


            %Report Connectedion 
            fprintf('Connected to MPDS AOM on %s\n', serialComms)


        end %constructor

        function delete(obj)
            fprintf('Disconnecting from MPDS AOM device\n');
            if ~isempty(obj.hC) && isa(obj.hC,'serial') && isvalid(obj.hC)
                fprintf('Closing serial communications with MPDS AOM device.\n')
                flushinput(obj.hC) % Ensure buffer is empty
                fclose(obj.hC);
                delete(obj.hC);
            end  
            if ~isempty(obj.listeners)
                cellfun(@delete,obj.listeners)
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
            s=obj.getStatusString;
            if ~isempty(s)
                obj.isAomConnected=true;
                obj.loadSettingsFromDisk;
            else
                obj.isAomConnected=false;
                fprintf('AOM does not seem to be responding to serial commands\n')
            end

        end


        function linkToLaser(obj,thisLaser)
            if ~isa(thisLaser,'laserControl.laser')
                fprintf('Error: linkToLaser must be supplied with an object that inherits class "laserControl.laser"\n')
                return
            end
            obj.laser=thisLaser;

            obj.listeners{1}=addlistener(obj.laser, 'targetWavelength', 'PostSet', @obj.updateAOMsetingsBasedOnWavelength);
        end


        function success = isControllerConnected(obj)
            S=obj.getStatusString;
            if isempty(S)
                obj.isAomConnected=false;
                success=false;
                return
            end
            obj.isAomConnected=true;
            success=true;
        end


        function [AOMReady,msg] = isReady(obj)
            if ~obj.isControllerConnected
                AOMReady=false;
                obj.isAomReady=AOMReady;
                return
            end
            AOMReady=obj.readAOMBlankingState;
            obj.isAomReady=AOMReady;
        end


        function frequency = readFrequency(obj,statusStr)
            if nargin<2
                statusStr = obj.getStatusString;
            end
            T=regexp(statusStr,' F=(\d+\.\d+) P=','tokens');
            frequency = str2double(T{1}{1});
            obj.currentFrequency = frequency; % Updates observable property that can be used by GUIs
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
            obj.currentRFpower_dB = AOMPower; % Updates observable property that can be used by GUIs
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
            obj.currentRFpower_dB = AOMPower; % Updates observable property that can be used by GUIs
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
            AOMID='MPDS'; %Can change if we really care
        end
        
    end %close methods




    % MPDS-specific
    methods

        % Methods for changing settings on the AOM
        function success = disableAOMBlanking(obj)
            obj.sendAndReceiveSerial('L0O0');
            success = ~obj.readAOMBlankingEnabled;
        end


        function success = enableAOMBlanking(obj)
            obj.sendAndReceiveSerial('L0O1');
            success = obj.readAOMBlankingEnabled;
        end


        function success = internalAOMBlanking(obj)
            obj.sendAndReceiveSerial('L0I1');
            success = strcmp(obj.readAOMBlankingState,'internal');
        end


        function success = externalAOMBlanking(obj)
            obj.sendAndReceiveSerial('L0I0');
            success = strcmp(obj.readAOMBlankingState,'external');
        end


        function success = disableChannel(obj,chan)
            if nargin<2
                chan=1;
            end
            if isnumeric(chan)
                chan=num2str(chan);
            end
            obj.sendAndReceiveSerial(['L',chan,'O0']);
            success = ~obj.readChannelEnabled(chan);
            if isnan(success)
                success=false;
            end
        end


        function success = enableChannel(obj,chan)
            if nargin<2
                chan=1;
            end
            if isnumeric(chan)
                chan=num2str(chan);
            end
            obj.sendAndReceiveSerial(['L',chan,'O1']);
            success = obj.readChannelEnabled(chan);
            if isnan(success)
                success=false;
            end
        end


        function success = internalChannel(obj,chan)
            if nargin<2
                chan=1;
            end
            if isnumeric(chan)
                chan=num2str(chan);
            end
            obj.sendAndReceiveSerial(['L',chan,'I1']);
            success = strcmp(obj.readChannelState(chan),'internal');
        end


        function success = externalChannel(obj,chan)
            if nargin<2
                chan=1;
            end
            if isnumeric(chan)
                chan=num2str(chan);
            end
            obj.sendAndReceiveSerial(['L',chan,'I0']);
            success = strcmp(obj.readChannelState(chan),'external');
        end


        % Methods for reading back the state of the AOM
        function state = readAOMBlankingEnabled(obj,statusStr)
            % Returns true if blanking is enabled. False if disabled.
            if nargin<2
                statusStr = obj.getStatusString;
            end
            if ~isempty(findstr(statusStr,'Blanking ON '))
                state=true;
            else
                state=false;
            end
        end


        function state = readAOMBlankingState(obj,statusStr)
            % Returns a string describing if the blanking is 'internal' or 'external'
            if nargin<2
                statusStr = obj.getStatusString;
            end
            tok=regexp(statusStr,'Blanking \w+ (\w+)','tokens');
            state = lower(tok{1}{1});
            % Sets observable property for GUIs
            if strcmp(state,'internal')
                obj.currentExternalBlankingEnabled=false;
            else
                obj.currentExternalBlankingEnabled=true;
            end
        end


        function state = readChannelEnabled(obj,chan,statusStr)
            % Returns true if the defined channel is "On".
            % Returns NaN if the channel was not found
            if nargin<2
                chan=1;
            end
            if isnumeric(chan)
                chan=num2str(chan);
            end
            if nargin<3
                statusStr = obj.getStatusString;
            end

            tok=regexp(statusStr,['l',chan,' F=.*? P=.*? (O[NF]+) [EI]\w+.*Blanking'],'tokens');
            if isempty(tok)
                fprintf('Channel %s not found by MPDSaom.readChannelState\n', chan)
                state=NaN;
                return 
            end
            if strcmp('ON',tok{1}{1})
                state=true;
            elseif strcmp('OFF',tok{1}{1})
                state=false;
            end

        end


        function state = readChannelState(obj,chan,statusStr)
            % Returns a string describing if the defined channel is to 'internal' or 'external'.
            % External is used for commanding power with a 0 to 10V drive signal.
            % Returns false if the channel was not found
            if nargin<2
                chan=1;
            end
            if isnumeric(chan)
                chan=num2str(chan);
            end
            if nargin<3
                statusStr = obj.getStatusString;
            end

            tok=regexp(statusStr,['l',chan,' F=.*? P=.*? O[NF]+ (\w+).*Blanking'],'tokens');
            if isempty(tok)
                fprintf('Channel %s not found by MPDSaom.readChannelState\n', chan)
                state=false;
                return 
            end
            state = lower(tok{1}{1});
            % Sets observable property for GUIs
            if strcmp(state,'internal')
                obj.currentExternalChannel=false;
            else
                obj.currentExternalChannel=true;
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

        % Callback that runs when laser wavelength changes
        function updateAOMsetingsBasedOnWavelength(obj,~,~)
            if ~obj.respondToChangingLaserWavelength
                return
            end
            if isempty(obj.laser) || ~isvalid(obj.laser)
                return
            end

            lasWav = obj.laser.targetWavelength; %Wavelength user is tuning to

            % Set the AOM frequency based upon laser wavelength
            newFreq = (obj.referenceWavelength/lasWav) * obj.referenceFrequency;
            fprintf('Tuning to %d nm: AOM at %0.2f MHz ', lasWav, newFreq)
            obj.setFrequency(newFreq);

            % Set AOM power in dB based on laser wavelength
            delta=abs(obj.powerTable(:,1)-lasWav);
            ind = find(delta==min(delta));
            newPower = obj.powerTable(ind,2);
            fprintf('& power at %d\n', newPower);
            obj.setPower_dB(newPower);
        end



    end % hidden methods

    
end %close classdef
