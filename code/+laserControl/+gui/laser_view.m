classdef laser_view < laserControl.gui.child_view


    properties
        statusPanel
        powerIndicator
        powerText
        shutterIndicator
        shutterText
        modelockIndicator
        modelockText
        connectionIndicator
        connectionText
        laserPowerText

        buttonOnOff
        buttonShutter
        buttonAOM
        editWavelength
        currentWavelengthText
    end

    properties(Hidden)
        currentWavelengthTimer %Regularly reads wavelength until settled
        currentWavelengthString='Current Wavelength: %d nm' %Used in the sprintf for the current wavelength
        laserViewUpdateInterval=2 %Update select GUI elements every this many seconds (e.g. modelock state)
        laserViewUpdateTimer
        setWavelengthLabel
    end

    methods
        function obj = laser_view(hLaser)
            obj = obj@laserControl.gui.child_view;

            if nargin>0
                obj.model.laser = hLaser;
            else
                fprintf('Can''t build laser_view: please supply a laser object as an input argument\n');
                return
            end

            obj.hFig = laserControl.gui.newGenericGUIFigureWindow('laserControl_laser');

            % Closing the figure closes the laser view object
            set(obj.hFig,'CloseRequestFcn', @obj.closeComponentView)

            %Resize the figure window
            pos=get(obj.hFig, 'Position');
            pos(3:4)=[220,250]; %Set the window size
            if isempty(obj.model.laser.friendlyName)
                set(obj.hFig, 'Position',pos, 'Name', 'Laser Control')
            else
                set(obj.hFig, 'Position',pos, 'Name', obj.model.laser.friendlyName)
            end

            %This timer runs when the wavelength is changed and updates the screen until the reading stabilizes
            fprintf('Setting up laser GUI timers\n')
            obj.currentWavelengthTimer = timer;
            obj.currentWavelengthTimer.Name = 'update current wavelength updater';
            if strcmp(obj.model.laser.friendlyName,'MaiTai')
                %MaiTai tunes slowly so update slowly or display may get
                %stuck
                obj.currentWavelengthTimer.StartDelay = 4;
            else
                obj.currentWavelengthTimer.StartDelay = 1;
            end
            obj.currentWavelengthTimer.TimerFcn = @(~,~) [] ;
            obj.currentWavelengthTimer.StopFcn = @(~,~) obj.updateCurrentWavelength;
            obj.currentWavelengthTimer.ExecutionMode = 'singleShot';


            %This timer updates select GUI elements
            obj.laserViewUpdateTimer = timer;
            obj.laserViewUpdateTimer.Name = 'laser view regular updater';
            obj.laserViewUpdateTimer.Period = obj.laserViewUpdateInterval;
            obj.laserViewUpdateTimer.TimerFcn = @(~,~) obj.regularGUIupdater;
            obj.laserViewUpdateTimer.StopFcn = @(~,~) [];
            obj.laserViewUpdateTimer.ExecutionMode = 'fixedDelay';


            %Add some listeners to monitor properties on the laser component
            fprintf('Setting up laser GUI listeners\n')
            obj.listeners{1}=addlistener(obj.model.laser, 'targetWavelength', 'PostSet', @obj.setWavelengthEditPanelToNewTargetWaveLength);
            obj.listeners{2}=addlistener(obj.model.laser, 'currentWavelength','PostSet', @obj.setReadWavelengthTextPanel);
            obj.listeners{3}=addlistener(obj.model.laser, 'isLaserShutterOpen','PostSet', @obj.updateGUI);
            obj.listeners{4}=addlistener(obj.model.laser, 'isLaserModeLocked','PostSet', @obj.updateGUI);
            obj.listeners{5}=addlistener(obj.model.laser, 'isLaserConnected','PostSet', @obj.updateGUI);
            obj.listeners{6}=addlistener(obj.model.laser, 'isLaserOn','PostSet', @obj.updateGUI);


            %TODO: add a status panel that reports the string from laser.isReady

            % Make the status panel
            fprintf('Building GUI elements\n')
            obj.statusPanel = laserControl.gui.newGenericGUIPanel([7.6 40 206.8 117.5], obj.hFig);
            indicatorsLeftPos=115;
            obj.powerIndicator = obj.makeRectangle(obj.statusPanel,[indicatorsLeftPos,90]);
            obj.powerText = obj.makeTextLabel(obj.statusPanel,[0 89, 110 20],'Power: OFF');
            set(obj.powerText, 'HorizontalAlignment', 'Right');

            obj.shutterIndicator   = obj.makeRectangle(obj.statusPanel,[indicatorsLeftPos,70]);
            obj.shutterText = obj.makeTextLabel(obj.statusPanel,[0, 69, 110 20],'Shutter Closed');
            set(obj.shutterText, 'HorizontalAlignment', 'Right');

            obj.modelockIndicator = obj.makeRectangle(obj.statusPanel,[indicatorsLeftPos,50]);
            obj.modelockText = obj.makeTextLabel(obj.statusPanel,[0, 49, 110 20],'Modelock: NO');
            set(obj.modelockText, 'HorizontalAlignment', 'Right')

            obj.connectionIndicator = obj.makeRectangle(obj.statusPanel,[indicatorsLeftPos,30]);
            obj.connectionText = obj.makeTextLabel(obj.statusPanel,[0, 29, 110 20],'Connected: NO');
            set(obj.connectionText, 'HorizontalAlignment', 'Right');

            obj.laserPowerText = obj.makeTextLabel(obj.statusPanel,[0, 9, 130 20],'Power: 0 mW');


            % Buttons
            obj.buttonOnOff=uicontrol(...
                'Parent', obj.hFig, ...
                'Position', [10, 220, 75, 25], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Turn On', ...
                'Callback', @obj.onOffButtonCallBack);

            obj.buttonShutter=uicontrol(...
                'Parent', obj.hFig, ...
                'Position', [100, 220, 100, 25], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Open Shutter', ...
                'Callback', @obj.shutterButtonCallBack);

            if ~isempty(obj.model.laser.hAOM)
                obj.buttonAOM=uicontrol(...
                    'Parent', obj.hFig, ...
                    'Position', [5, 5, 100, 25], ...
                    'FontSize', obj.fSize, ...
                    'FontWeight', 'bold', ...
                    'String', 'AOM GUI', ...
                    'Callback', @obj.startAOM_GUI_Button_Callback);
            end


            % - - - - - - - - -
            % Wavelength
            %Get the wavelength
            fprintf('Checking laser is connected\n')
            if obj.model.laser.isControllerConnected
                fprintf('Doing first read of wavelength\n')
                currentWavelength=obj.model.laser.readWavelength;
            else
                currentWavelength=0;
            end

            obj.editWavelength=uicontrol(...
                'Parent', obj.hFig, ...
                'Style','edit', ...
                'Position', [125, 195, 50, 20], ...
                'FontSize', obj.fSize, ...
                'String', currentWavelength, ...
                'Callback', @obj.setWavelengthEditPanel);

            obj.setWavelengthLabel=obj.makeTextLabel(obj.hFig,[5, 195, 155 20],'Target Wavelength:');
            obj.currentWavelengthText = obj.makeTextLabel(obj.hFig,[5, 170, 195, 20],sprintf(obj.currentWavelengthString,currentWavelength));



            %Set the GUI elements to reflect the current state of the laser
            fprintf('Finalising laser GUI state\n')
            obj.model.laser.isPoweredOn; %Not pretty, but we run this to ensure the properties are set correctly
            obj.updateGUI;

            %Set the target wavelength to equal the current wavelength
            obj.model.laser.targetWavelength=obj.model.laser.currentWavelength;

            start(obj.laserViewUpdateTimer)

        end %constructor

        function delete(obj)
            %Flush the buffer on the laser (just in case)
            if isa(obj.model.laser.hC,'serial')
                flushinput(obj.model.laser.hC)
            end
            
            if isa(obj.laserViewUpdateTimer,'timer')
                stop(obj.laserViewUpdateTimer)
                delete(obj.laserViewUpdateTimer)
            end
            if isa(obj.currentWavelengthTimer,'timer')
                stop(obj.currentWavelengthTimer)
                delete(obj.currentWavelengthTimer)
            end

            %If there is an open AOM view we should close it
            f=findall(0,'Tag', 'laserControl_aom');
            if ~isempty(f)
                delete(f)
            end
            delete@laserControl.gui.child_view(obj);
        end

        % UI Callback functions
        function setWavelengthEditPanel(obj,~,~)
            %Runs when the user enters a new value in the panel
            if ~obj.model.laser.isLaserOn
                warndlg('Laser is powered off','')
                set(obj.editWavelength,'String',obj.model.laser.targetWavelength)
                return
            end

            newValue=get(obj.editWavelength,'String');

            newValue=str2double(newValue);
            if isempty(newValue) || isnan(newValue)
                %If it wasn't numeric, set it back to what it was before
                fprintf('Not a valid wavelength value\n');
                set(obj.editWavelength,'String',obj.model.laser.targetWavelength)
                return
            end

            [inRange,msg]=obj.model.laser.isTargetWavelengthInRange(newValue);
            if ~inRange
                warndlg(msg,'')
                return
            end

            %Will trigger setWavelengthEditPanelToNewTargetWaveLength
            obj.model.laser.setWavelength(newValue);
            obj.model.laser.isModeLocked; %TODO: maybe this should be run by a timer every so often
        end


        % API-triggered callbacks
        function setWavelengthEditPanelToNewTargetWaveLength(obj,~,~)
            %Called when the laser's target wavelength property changes
            set(obj.editWavelength,'String',obj.model.laser.targetWavelength)
            obj.setReadWavelengthTextPanel;

        end


        function setReadWavelengthTextPanel(obj,~,~)
            set(obj.currentWavelengthText,'String',sprintf(obj.currentWavelengthString,round(obj.model.laser.readWavelength)))
            %Now start a timer that will keep updating the wavelength text box until the laser has settled
            %It does this because laser.readWavelength updates the laser.currentWavelength property that fires this callback.
            %This callback then calls readWavelength with a delay via the timer and so there is a 
            %while loop. 
            if isa(obj.currentWavelengthTimer,'timer') && ...
                strcmp(obj.currentWavelengthTimer.Running,'off')
                start(obj.currentWavelengthTimer)
            end

        end

        function h = makeRectangle(~,parentObj,pos)
            h = annotation(...
                parentObj, 'rectangle', ...
                'Units', 'Pixels', ...
                'Position', [pos,15,15], ...
                'Color',[1,1,1]*0.8, ...
                'FaceColor','r');
        end

        function h = makeTextLabel(obj,parentObj,pos,txt)
            h = annotation(...
                parentObj, 'textbox', ...
                'Units', 'Pixels', ...
                'Position', pos , ...
                'EdgeColor', 'None', ...
                'Color', 'w', ...
                'FontWeight', 'Bold', ...
                'FontSize', obj.fSize, ...
                'String', txt);
        end

    end

    methods (Hidden)
        %This function restarts the timer and updates the GUI until the wavelength has settled
        %see also: obj.setReadWavelengthTextPanel
        function updateCurrentWavelength(obj)
            if ~obj.model.laser.isControllerConnected
                return
            end
            %TODO: let's see if this improves stability of the serial comms
            if obj.model.laser.hC.BytesAvailable>0
                fprintf('Skipping updateCurrentWavelength timer callback due to bytes still present for reading in serial buffer\n')
                return
            end

            W=obj.model.laser.readWavelength; %updates obj.model.laser.currentWavelength which is what triggers this timer callback
            set(obj.currentWavelengthText,'String',sprintf(obj.currentWavelengthString,round(W)))
        end


        %The following methods are used to update GUI elements upon certain events happening 
        function onOffButtonCallBack(obj,~,~)
            if ~obj.model.laser.isControllerConnected
                %TODO: make a check connection method and bring up a warning box
                return
            end
            if obj.model.laser.isPoweredOn==true
                obj.model.laser.turnOff;
            elseif obj.model.laser.isPoweredOn==false
                obj.model.laser.turnOn;
            end
            obj.updateGUI
        end

        function shutterButtonCallBack(obj,~,~)
            if ~obj.model.laser.isControllerConnected
                %TODO: make a check connection method and bring up a warning box
                return
            end
            if obj.model.laser.isLaserShutterOpen==true
                obj.model.laser.closeShutter;
            elseif obj.model.laser.isLaserShutterOpen==false
                obj.model.laser.openShutter;
            end
        end

        function startAOM_GUI_Button_Callback(obj,~,~)
            if isempty(obj.model.laser.hAOM)
                return
            end
            laserControl.gui.aom_view(obj.model.laser.hAOM,obj);
        end

        function updateShutterElements(obj,~,~)
            if ~obj.model.laser.isControllerConnected
                %TODO: make a check connection method and bring up a warning box
                return
            end
            if obj.model.laser.isShutterOpen==true
                set(obj.buttonShutter, 'String', 'Close Shutter')
                set(obj.shutterText, 'String', 'Shutter Opened')
                set(obj.shutterIndicator, 'FaceColor', 'g')
            elseif obj.model.laser.isShutterOpen==false
                set(obj.buttonShutter, 'String', 'Open Shutter')
                set(obj.shutterText, 'String', 'Shutter Closed')
                set(obj.shutterIndicator, 'FaceColor', 'r')
            end
        end %updateShutterElements

        function updateModeLockElements(obj,~,~)
            if ~obj.model.laser.isControllerConnected
                %TODO: make a check connection method and bring up a warning box
                return
            end
            if obj.model.laser.isModeLocked==true
                set(obj.modelockIndicator, 'FaceColor', 'g')
                set(obj.modelockText, 'String', 'Modelock: YES')
            elseif obj.model.laser.isModeLocked==false
                set(obj.modelockIndicator, 'FaceColor', 'r')
                set(obj.modelockText, 'String', 'Modelock: NO')
            end
        end %updateModeLockElements

        function updateLaserConnectedElements(obj,~,~)
            if obj.model.laser.isLaserConnected==true
                set(obj.connectionIndicator, 'FaceColor', 'g')
                set(obj.connectionText, 'String', 'Connected: YES')
            elseif obj.model.laser.isLaserConnected==false
                set(obj.connectionIndicator, 'FaceColor', 'r')
                set(obj.connectionText, 'String', 'Connected: NO')
            end
        end %updateLaserConnectedElements

        function updateLaserOnElements(obj,~,~)
            %Better to look at the property as there is a lag between 
            %hitting the button and the power going up
            if obj.model.laser.isLaserOn==true
                set(obj.buttonOnOff, 'String', 'Turn Off')
                set(obj.powerIndicator, 'FaceColor', 'g')
                set(obj.powerText, 'String', 'Power: ON')
            elseif obj.model.laser.isLaserOn==false
                set(obj.buttonOnOff, 'String', 'Turn On')
                set(obj.powerIndicator, 'FaceColor', 'r')
                set(obj.powerText, 'String', 'Power: OFF')
            end
        end %updateLaserOnElements

        function updatePowerText(obj)
            if ~obj.model.laser.isControllerConnected
                %TODO: make a check connection method and bring up a warning box
                return
            end
            powerIn_mW = round(obj.model.laser.readPower);
            set(obj.laserPowerText,'String', sprintf('Power: %d mW',powerIn_mW))
        end

        function updateGUI(obj,~,~)
            obj.updateShutterElements
            obj.updateModeLockElements
            obj.updateLaserConnectedElements
            obj.updateLaserOnElements
            obj.updatePowerText
        end %updateGUI

        function regularGUIupdater(obj,~,~)
            % TODO: this callback blocks MATLAB for a short period of time
            if ~isvalid(obj.model.laser)
                return
            end
            if obj.model.laser.hC.BytesAvailable>0
                fprintf('Skipping regularGUIupdater timer callback due to bytes still present for reading in serial buffer\n')
                return
            end

            try
                obj.updateModeLockElements
                obj.updatePowerText
                %obj.updateCurrentWavelength %TODO: hopefully we can remove this in time
            catch ME 
                fprintf('Failed to update laser GUI with error: %s\n', ME.message)
            end
        end

    end %end hidden methods

end
