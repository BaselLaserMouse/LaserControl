classdef aom_view < laserControl.gui.child_view


    properties
        freqPanel % Elements for frequency setting go here
        powerPanel % Elements for power setting go here
        connectionText

        % Buttons
        button_LoadSettings
        button_SaveSettings
        button_tuneLaserToReferenceWavelength
        button_updateReferenceFreq
        button_RF_powerTweakMode
        button_insertRF_power
        button_removeRF_power %should be disabled unless we are at a power stored in the table
        button_showPowerFig 


        %Check boxes
        checkBox_blankingExternal
        checkBox_externalVoltageControl

        editFreq
        editRF_power

        currentFrequencyText
        currentRefWavelength
        currentPowerText
    end

    properties(Hidden)

        currentFrequencyString='Current Frequency: %3.2f MHz' %Used in the sprintf for the current frequency
        currentPowerString='Current RF Power: %2.2f dB' %Used in the sprintf for the current power
        currentRefWavelengthString='Current Ref Wavelength: %d nm' %Used in the sprintf for the current reference wavelength
        setWavelengthLabel
        lastBeamPower %To return power to original value
        hSI %reference to ScanImage
    end


    properties (SetObservable)
        inRF_powerTweakMode=false;
    end


    methods
        function obj = aom_view(hAOM,parentView)
            obj = obj@laserControl.gui.child_view;

            if nargin>0
                obj.model.hAOM = hAOM;
            else
                fprintf('Can''t build aom_view: please supply an AOM object as an input argument\n');
                return
            end

            if nargin>1
                obj.parentView=parentView; % The laser GUI
                obj.listeners{1}=addlistener(parentView.model.laser, 'currentWavelength', 'PostSet', @obj.updateLaserWavelengthRelatedElements);
            else
                fprintf('No laser GUI connected. Assuming AOM is connected to a non-tunable laser.\n')
            end

            %Connect to ScanImage if possible
            obj.connectScanImage %obj.hSI remains empty if this fails



            obj.hFig = laserControl.gui.newGenericGUIFigureWindow('laserControl_aom');
            % Closing the figure closes the laser view object
            set(obj.hFig,'CloseRequestFcn', @obj.closeComponentView)

            if ~obj.model.hAOM.isAomConnected
                fprintf('\nAOM NOT CONNECTED\n')
                return
            end

            %Read current settings to ensure the observable values are populated
            obj.model.hAOM.readFrequency;
            obj.model.hAOM.readPower_dB;
            obj.model.hAOM.readAOMBlankingState;
            obj.model.hAOM.readChannelState;

            %Resize the figure window
            pos=get(obj.hFig, 'Position');
            pos(3:4)=[220,300]; %Set the window size
            if isempty(obj.model.hAOM.friendlyName)
                set(obj.hFig, 'Position',pos, 'Name', 'AOM Control')
            else
                set(obj.hFig, 'Position',pos, 'Name', obj.model.hAOM.friendlyName)
            end



            % Make the status panel
            fprintf('Building AOM GUI elements\n')
            obj.freqPanel = laserControl.gui.newGenericGUIPanel([6, 145, 104, 150], obj.hFig);
            obj.powerPanel = laserControl.gui.newGenericGUIPanel([113, 145, 104, 150], obj.hFig);            
            obj.makeTextLabel(obj.freqPanel,[1,135,90,15],'Frequency');
            obj.makeTextLabel(obj.powerPanel,[1,135,90,15],'RF Power');

            % Freq editing
            obj.editFreq=uicontrol(...
                'Parent', obj.hFig, ...
                'Style','edit', ...
                'Position', [5, 107, 75, 20], ...
                'FontSize', obj.fSize, ...
                'String', obj.model.hAOM.currentFrequency, ...
                'Parent', obj.freqPanel, ...
                'Callback', @obj.setFreqEditPanel);

            obj.button_tuneLaserToReferenceWavelength = uicontrol(...
                'Parent', obj.freqPanel, ...
                'Position', [5, 55, 90, 35], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', '<html>Tune laser to<br />reference &lambda</html>', ...
                'Tooltip', 'Tune laser to reference frequency to enable reference frequency updating', ...
                'Callback', @obj.tuneLaserToRefWavelengthButtonCallback);
            if isempty(obj.parentView)
                obj.button_tuneLaserToReferenceWavelength.Enable='off';
            end

            obj.button_updateReferenceFreq = uicontrol(...
                'Parent', obj.freqPanel, ...
                'Position', [5, 10, 90, 35], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', '<html>Update ref<br />frequency</html>', ...
                'Enable', 'Off', ...
                'Tooltip', 'Set reference frequency to current frequency', ...
                'Callback', @obj.updateRefWavelengthButtonCallback);

            % Power editing
            obj.editRF_power=uicontrol(...
                'Parent', obj.hFig, ...
                'Style','edit', ...
                'Position', [5, 107, 75, 20], ...
                'FontSize', obj.fSize, ...
                'String', obj.model.hAOM.currentRFpower_dB, ...
                'Parent', obj.powerPanel, ...
                'Callback', @obj.setPowerEditPanel);

            obj.button_RF_powerTweakMode = uicontrol(...
                'Parent', obj.powerPanel, ...
                'Position', [5, 5, 90, 20], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'Tooltip', 'Enters and leaves power tweak mode', ...
                'Enable','on',...
                'String', 'Enter tweak', ...
                'Callback', @obj.tweakModeButtonCallBack);
            if isempty(obj.hSI)
                obj.button_RF_powerTweakMode.Enable='off';
            end


            obj.button_insertRF_power = uicontrol(...
                'Parent', obj.powerPanel, ...
                'Position', [5, 30, 90, 20], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Add value', ...
                'Enable', 'on', ...
                'Callback', @obj.insertRF_powerValueFromTableButtonCallback);

            obj.button_removeRF_power = uicontrol(...
                'Parent', obj.powerPanel, ...
                'Position', [5, 55, 90, 20], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Remove value', ...
                'Callback', @obj.removeRF_powerValueFromTableButtonCallback);        

            obj.button_showPowerFig = uicontrol(...
                'Parent', obj.powerPanel, ...
                'Position', [5, 80, 90, 20], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Show fig', ...
                'Callback', @obj.showPowerFigButtonCallback);   

            obj.connectionText = obj.makeTextLabel(obj.hFig,[4, 35, 220 20],'');
            set(obj.connectionText, 'HorizontalAlignment', 'Left');
            obj.updateAOMConnectedElements %Updates string of above text label

            obj.updateLaserWavelengthRelatedElements; %Ensure button state is correct



            % Buttons
            obj.button_LoadSettings = uicontrol(...
                'Parent', obj.hFig, ...
                'Position', [8, 5, 100, 25], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Load Settings', ...
                'Callback', @obj.loadSettingsButtonCallBack);

            obj.button_SaveSettings = uicontrol(...
                'Parent', obj.hFig, ...
                'Position', [115, 5, 100, 25], ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'Save Settings', ...
                'Callback', @obj.saveSettingsButtonCallBack);


            % - - - - - - - - -

            %Check boxes
            obj.checkBox_blankingExternal = uicontrol( ...
                'Style','checkbox', ...
                'parent', obj.hFig, ...
                'String', 'External blanking',...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', obj.hFig.Color, ...
                'ForegroundColor', 'w', ...
                'Value', obj.model.hAOM.currentExternalBlankingEnabled, ...
                'Callback', @obj.setExternalBlankingCallback, ....
                'Position', [8,98,200,20]);

            obj.checkBox_externalVoltageControl = uicontrol( ...
                'Style','checkbox', ...
                'parent', obj.hFig, ...
                'FontSize', obj.fSize, ...
                'FontWeight', 'bold', ...
                'String', 'External voltage control',...
                'BackgroundColor', obj.hFig.Color, ...
                'ForegroundColor', 'w', ...
                'Value', obj.model.hAOM.currentExternalChannelEnabled, ...
                'Callback', @obj.setExternalVoltageCallback, ....
                'Position', [8,115,200,20]);


            %Text labels
            obj.currentRefWavelength = obj.makeTextLabel(obj.hFig,[4, 50, 210, 20],sprintf(obj.currentRefWavelengthString,obj.model.hAOM.referenceWavelength));
            obj.currentFrequencyText = obj.makeTextLabel(obj.hFig,[4, 65, 210, 20],sprintf(obj.currentFrequencyString,obj.model.hAOM.readFrequency));
            obj.currentPowerText = obj.makeTextLabel(obj.hFig,[4, 80, 210, 20],sprintf(obj.currentPowerString,obj.model.hAOM.readPower_dB));


            %Add some listeners to monitor properties on the AOM
            fprintf('Setting up AOM GUI listeners\n')
            obj.listeners{2}=addlistener(obj.model.hAOM, 'isAomConnected', 'PostSet', @obj.updateAOMConnectedElements);
            obj.listeners{3}=addlistener(obj.model.hAOM, 'referenceWavelength', 'PostSet', @obj.updateRefWavelengthTextCallback);            
            obj.listeners{4}=addlistener(obj.model.hAOM, 'currentFrequency', 'PostSet', @obj.updateFreqTextCallback);            
            obj.listeners{5}=addlistener(obj.model.hAOM, 'currentRFpower_dB', 'PostSet', @obj.updateRFpowerTextCallback);
            obj.listeners{5}=addlistener(obj.model.hAOM, 'currentExternalBlankingEnabled', 'PostSet', @obj.updateExternalBlankingCheckboxCallback);
            obj.listeners{5}=addlistener(obj.model.hAOM, 'currentExternalChannelEnabled', 'PostSet', @obj.updateExternalChannelCheckboxCallback);

            V=ver; % To search for presence of a toolbox
            if ~isempty(obj.parentView)
                if any(strcmp({V.Name},'Image Processing Toolbox'))
                    %Place next to laser GUI            
                    iptwindowalign(parentView.hFig, 'right', obj.hFig, 'left');
                    iptwindowalign(parentView.hFig, 'top', obj.hFig, 'top');
                else
                    % Hack in case toolbox missing
                    obj.hFig.Position(1) = parentView.hFig.Position(1)+50;
                    obj.hFig.Position(2) = parentView.hFig.Position(2)-100;
                end
            end
        end %constructor

        function delete(obj)
            %Flush the buffer on the AOM (just in case)
            if isa(obj.model.hAOM.hC,'serial') && isvalid(obj.model.hAOM.hC)
                flushinput(obj.model.hAOM.hC)
            end
            obj.hSI=[];
            delete@laserControl.gui.child_view(obj);
        end

        % UI Callback functions
        function setFreqEditPanel(obj,~,~)
            %Runs when the user enters a new value in the frequency edit box
            newValue=get(obj.editFreq,'String');
            newValue=str2double(newValue);
            if isempty(newValue) || isnan(newValue)
                %If it wasn't numeric, set it back to what it was before
                fprintf('Not a valid wavelength value\n');
                return
            end
            obj.model.hAOM.setFrequency(newValue);
        end




        function setPowerEditPanel(obj,~,~)
            %Runs when the user enters a new value in the power edit box
            newValue=get(obj.editRF_power,'String');
            newValue=str2double(newValue);
            if isempty(newValue) || isnan(newValue)
                %If it wasn't numeric, set it back to what it was before
                fprintf('Not a valid RF power value\n');
                return
            end

            %Will trigger setWavelengthEditPanelToNewTargetWaveLength
            obj.model.hAOM.setPower_dB(newValue);

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
        function updatecurrentFrequency(obj)
            if ~obj.model.hAOM.isControllerConnected
                return
            end

            W=obj.model.hAOM.readFrequency; %updates obj.model.hAOM.currentFrequency which is what triggers this timer callback
            set(obj.currentFrequencyText,'String',sprintf(obj.currentFrequencyString,round(W)))
        end



        %The following methods are used to load and save settings
        function loadSettingsButtonCallBack(obj,~,~)
            obj.model.hAOM.loadSettingsFromDisk;
        end


        function saveSettingsButtonCallBack(obj,~,~)
            obj.model.hAOM.writeCurrentStateToSettingsFile;
        end


        function setExternalBlankingCallback(obj,~,~)
            if obj.checkBox_blankingExternal.Value == true
                obj.model.hAOM.externalAOMBlanking;
            else
                obj.model.hAOM.internalAOMBlanking;
            end
        end


        function setExternalVoltageCallback(obj,~,~)
            if obj.checkBox_externalVoltageControl.Value == true
                obj.model.hAOM.externalChannel;
            else
                obj.model.hAOM.internalChannel;
            end
        end


        function updateAOMConnectedElements(obj,~,~)
            if obj.model.hAOM.isAomConnected==true
                set(obj.connectionText, 'String', 'AOM Connected: YES')
            elseif obj.model.hAOM.isAomConnected==false
                set(obj.connectionText, 'String', 'AOM Connected: NO')
            end
        end %updateAOMConnectedElements


        function updateRefWavelengthTextCallback(obj,~,~)
            if ~obj.model.hAOM.isControllerConnected
                return
            end
            set(obj.currentRefWavelength,'String', ...
                sprintf(obj.currentRefWavelengthString,obj.model.hAOM.referenceWavelength))
        end


        function updateFreqTextCallback(obj,~,~)
            if ~obj.model.hAOM.isControllerConnected
                return
            end
            set(obj.currentFrequencyText,'String', ...
                sprintf(obj.currentFrequencyString,obj.model.hAOM.currentFrequency))
            set(obj.editFreq,'String',obj.model.hAOM.currentFrequency)
        end


        function updateRFpowerTextCallback(obj,~,~)
            if ~obj.model.hAOM.isControllerConnected
                return
            end
            set(obj.currentPowerText,'String', ...
                sprintf(obj.currentPowerString,obj.model.hAOM.currentRFpower_dB))
            set(obj.editRF_power,'String',obj.model.hAOM.currentRFpower_dB)
        end


        function updateExternalBlankingCheckboxCallback(obj,~,~)
            obj.checkBox_blankingExternal.Value=obj.model.hAOM.currentExternalBlankingEnabled;
        end


        function updateExternalChannelCheckboxCallback(obj,~,~)
            obj.checkBox_externalVoltageControl.Value=obj.model.hAOM.currentExternalChannelEnabled;
        end


        function updateLaserWavelengthRelatedElements(obj,~,~)
            if isempty(obj.parentView)
                % If no laser is connected
                obj.button_updateReferenceFreq.Enable='on';
                obj.button_removeRF_power.Enable='on';
                obj.button_insertRF_power.Enable='on';
                return
            end

            cL = obj.parentView.model.laser.currentWavelength;
            rL = obj.model.hAOM.referenceWavelength;
            pT = obj.model.hAOM.powerTable;
            if isempty(cL)
                return
            end
            % The reference frequency should only be settable if the
            % user has set the laser to the reference wavelength
            if abs(rL-cL)<2
                obj.button_updateReferenceFreq.Enable='on';
            else
                obj.button_updateReferenceFreq.Enable='off';
            end

            % It's only possible to remove a value from the power table
            % if the laser wavelength is at that value's wavelength
            f=find(pT(:,1)==cL);
            if isempty(f)
                obj.button_removeRF_power.Enable='off';
            else
                obj.button_removeRF_power.Enable='on';
            end

        end


        function updateRefWavelengthButtonCallback(obj,~,~)
            obj.model.hAOM.referenceFrequency = obj.model.hAOM.readFrequency;
        end


        function tuneLaserToRefWavelengthButtonCallback(obj,~,~)
            fprintf('Tuning laser to %d nm\n',obj.model.hAOM.referenceWavelength)
            obj.parentView.model.laser.setWavelength(obj.model.hAOM.referenceWavelength)
        end


        function showPowerFigButtonCallback(obj,~,~)
            obj.model.hAOM.makePowerWavelengthFig
        end



        function insertRF_powerValueFromTableButtonCallback(obj,~,~)
            obj.model.hAOM.insertCurrentRF_powerIntoTable;
        end


        function removeRF_powerValueFromTableButtonCallback(obj,~,~)
            obj.model.hAOM.removeRF_powerFromTable;
        end


        function tweakModeButtonCallBack(obj,~,~)
            % The tweak button is disabled in the constructor unless ScanImage
            % is connected to the laser GUI. So no further checks needed here
            % as to this fact.

            if isempty(obj.hSI)
                return
            end
            %Set ScanImage to point mode
            obj.inRF_powerTweakMode = ~obj.inRF_powerTweakMode;

            if obj.inRF_powerTweakMode
                obj.button_insertRF_power.Enable='on';
                obj.button_RF_powerTweakMode.String='Leave tweak';
                if strcmpi(obj.hSI.acqState,'idle')
                    obj.hSI.scanPointBeam
                    obj.lastBeamPower=obj.hSI.hBeams.powers(1);
                    obj.hSI.hBeams.powers(1)=100;
                    obj.hSI.hBeams.directMode(1)=true;
                else
                    fprintf('ScanImage not idle. Not entering tweak mode\n')
                    return
                end
            else
                obj.button_insertRF_power.Enable='off';
                obj.button_RF_powerTweakMode.String='Enter tweak';
                obj.hSI.hCycleManager.abort;
                obj.hSI.hBeams.powers(1)=obj.lastBeamPower;
                obj.hSI.hBeams.directMode(1)=false;
            end

        end

        function connectScanImage(obj)
            % Add a reference to the hSI ScanImage object in obj.hSI
            W = evalin('base','whos');
            SIexists = ismember('hSI',{W.name});
            if ~SIexists
                fprintf('Can not find ScanImage object in base workspace\n');
                return
            end

            obj.hSI = evalin('base','hSI'); % get hSI from the base workspace
        end %connectScanImage

    end %end hidden methods

end
