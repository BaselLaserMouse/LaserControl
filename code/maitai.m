classdef maitai < laser
%%  maitai
%
% Laser control class for  SpectraPhysics MaiTai lasers.
% In the SpectraPhysics GUI you should set the baudrate switch to "9600".
%
% For more info see the abstract class "laser".
%



    methods

        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        %constructor
        function obj = maitai(serialComms)
        % function obj = maitai(serialComms)

            obj.maxWavelength=1100;
            obj.minWavelength=700;

            fprintf('Setting up MaiTai laser communication on serial port %s\n', serialComms);
            laserUtils.clearSerial(serialComms)
            obj.controllerID=serialComms;
            success = obj.connect;

            if ~success
                fprintf('Component maitai failed to connect to laser over the serial port.\n')
                %TODO: is it possible to delete it here?
            end

            %Set the target wavelength to equal the current wavelength
            obj.targetWavelength=obj.currentWavelength;
        end %constructor


        % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        %destructor
        function delete(obj)
            fprintf('Disconnecting from MaiTai laser\n')
            if ~isempty(obj.hC) && isa(obj.hC,'serial')
                fprintf('Closing serial communications with MaiTai laser\n')
                flushinput(obj.hC) %There may be characters left in the buffer because of the timers used to poll the laser
                fclose(obj.hC);
                delete(obj.hC);
            end  
        end %destructor


        function success = connect(obj)
            obj.hC=serial(obj.controllerID,'BaudRate',9600);
            fopen(obj.hC); %TODO: could test the output to determine if the port was opened
            flushinput(obj.hC) % Just in case
            if isempty(obj.hC) %TODO: better tests: query the version number or something like that
                success=false;
            else
                success=true;
            end 
            obj.isLaserConnected=success;
        end %connect


        function success = isControllerConnected(obj)
            if strcmp(obj.hC.Status,'closed')
                success=false;
            else
                [~,success] = obj.isShutterOpen;
            end
            obj.isLaserConnected=success;
        end


        function success = turnOn(obj)
            if obj.readWarmedUp<100
                fprintf('Laser is not warmed up. Current warm up state: %0.2f\n',obj.readWarmedUp)
                return
            end
            successA=obj.sendAndReceiveSerial('ON',false);
            successB=obj.setWatchDogTimer(0); %otherwise it will turn off again
            success=successA & successB;
            obj.isLaserOn=success;
        end


        function success = turnOff(obj)
            success=obj.sendAndReceiveSerial('OFF',false);
            if success
                obj.isLaserOn=false;
            end
        end

        function powerOnState = isPoweredOn(obj)
            if obj.readPumpPower>10
                powerOnState=true;
            else
                powerOnState=false;
            end
            obj.isLaserOn=powerOnState;
        end


        function [laserReady,msg] = isReady(obj)
            laserReady = false;
            msg='';
            [shutterState,success] = obj.isShutterOpen;
            if ~success
                msg='No connection to laser';
                obj.isLaserReady=false;
                return
            end
            if ~obj.emissionPossible
                msg='Laser is switched off and is not emitting';
                obj.isLaserReady=false;
                return
            end
            if shutterState==0
                msg='Laser shutter is closed';
                obj.isLaserReady=false;
                return
            end
            if ~obj.isModeLocked
                msg='Laser not modelocked';
                obj.isLaserReady=false;
                return
            end

            laserReady=true;
            obj.isLaserReady=laserReady;
        end


        function modelockState = isModeLocked(obj)
            [success,reply]=obj.sendAndReceiveSerial('*STB?'); %modelock state embedded in the second bit of this 8 bit number
            if ~success %If we can't talk to it, we assume it's also not modelocked (maybe questionable, but let's go with this for now)
                modelockState=false;
                obj.isLaserModeLocked=modelock;
                return
            end

            %extract modelock state
            bits = fliplr(dec2bin(str2double(reply),8));
            if strcmp(bits(2),'1')
                modelockState=1;
            else 
                modelockState=0;
            end
            obj.isLaserModeLocked=modelockState;
        end


        function success = openShutter(obj)
            success=obj.sendAndReceiveSerial('SHUTTER 1',false);
            pause(0.75) %Because it takes the laser about a second to register the change
            if success
                obj.isLaserShutterOpen=true;
            end
        end


        function success = closeShutter(obj)
            success=obj.sendAndReceiveSerial('SHUTTER 0',false);
            pause(0.75) %Because it takes the laser about a second to register the change
            if success
                obj.isLaserShutterOpen=false;
            end
        end


        function [shutterState,success] = isShutterOpen(obj)
            [success,reply]=obj.sendAndReceiveSerial('SHUTTER?');
            if ~success
                shutterState=[];
                return
            end            
            shutterState = str2double(reply); %if open the command returns 1
            obj.isLaserShutterOpen=shutterState;
        end


        function wavelength = readWavelength(obj) 
            [success,wavelength]=obj.sendAndReceiveSerial('READ:WAVELENGTH??');
            if ~success
                wavelength=[];
                return
            end
            wavelength = str2double(wavelength(1:end-2));
            obj.currentWavelength=wavelength;
        end


        function success = setWavelength(obj,wavelengthInNM)

            success=false;
            if length(wavelengthInNM)>1
                fprintf('wavelength should be a scalar')
                return
            end            
            if ~obj.isTargetWavelengthInRange(wavelengthInNM)
                return
            end
            cmd = sprintf('WAVELENGTH %d', round(wavelengthInNM));
            [success,wavelength]=obj.sendAndReceiveSerial(cmd,false);
            if ~success
                return
            end
            obj.currentWavelength=wavelength;
            obj.targetWavelength=wavelengthInNM;

        end
   

        function tuning = isTuning(obj)

            %First get the desired (setpoint) wavelength
            [success,wavelengthDesired]=obj.sendAndReceiveSerial('WAVELENGTH?');
            if ~success
                return
            end

            wavelengthDesired = str2double(wavelengthDesired(1:end-2));
            pause(0.33)
            currentWavelength = obj.readWavelength;

            if round(currentWavelength) == wavelengthDesired
                tuning=false;
            else
                tuning=true;
            end

        end
        

        function laserPower = readPower(obj)
            [success,laserPower]=obj.sendAndReceiveSerial('READ:POWER?');
            if ~success
                laserPower=[];
                return
            end
            laserPower = str2double(laserPower(1:end-1))*1E3;
            laserPower = round(laserPower);
        end



        % MaiTai specific
        function laserPower = readPumpPower(obj)
            [success,laserPower]=obj.sendAndReceiveSerial('READ:PLASER:POWER?');
            if ~success
                laserPower=[];
                return
            end
            laserPower = str2double(laserPower(1:end-1))*1E3;
            laserPower = round(laserPower);
        end

        function pLasI = readPumpLaserCurrent(obj)
            [success,pLasI]=obj.sendAndReceiveSerial('READ:PLASER:PCURRENT?');
            if ~success
                pLasI=[];
                return
            end
            pLasI = str2double(pLasI(1:end-1));
        end

        function laserHumidity = readHumidity(obj)
            [success,laserHumidity]=obj.sendAndReceiveSerial('READ:HUM?');
            if ~success
                laserHumidity=[];
                return
            end
            laserHumidity = str2double(laserHumidity(1:end-3));
        end

        function warmedUpValue = readWarmedUp(obj)
            %Return a scalar that defines whether the laser is warmed up
            %100 means warmed up. Returns empty if nothing was read back.
            [success,warmedUpValue]=obj.sendAndReceiveSerial('READ:PCTWarmedup?');
            if ~success
                warmedUpValue=[];
                return
            end
            warmedUpValue = str2double(warmedUpValue(1:end-1));
        end

        function emission = emissionPossible(obj)
            [success,reply]=obj.sendAndReceiveSerial('*STB?'); %emission state embedded in the first bit of this 8 bit number
            if ~success %If we can't talk to it, we assume it's also not emitting (maybe questionable, but let's go with this for now)
                emission=false;
                return
            end

            %extract modelock state
            bits = fliplr(dec2bin(str2double(reply),8));
            if strcmp(bits(1),'1')
                emission=1;
            else 
                emission=0;
            end
        end

        function success=setWatchDogTimer(obj,value)
            cmd=sprintf('TIMER:WATCHDOG %d',round(value));
            success=obj.sendAndReceiveSerial(cmd,false);
            if ~success
                return
            end
            [success,currentValue]=obj.sendAndReceiveSerial('TIMER:WATCHDOG?');
            if ~success
                return
            end

            currentValue = round(str2double(currentValue));
            if currentValue ~= value
                fprintf('You asked for a MaiTai watchdog timer value %d seconds but the set value is reported as being %d seconds\n',...
                    value,currentValue)
                success=false;
            end
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
            if obj.hC.BytesAvailable>0
                fprintf('Read in from the MaiTai buffer but there are still %d BytesAvailable\n',obj.hC.BytesAvailable)
            end
            if ~isempty(reply)
                reply(end)=[];
            else
                msg=sprintf('Laser serial command %s did not return a reply\n',commandString);
                success=false;
                return
            end


            %TODO: improve check of success?
            success=true;
        end
        
    end

end