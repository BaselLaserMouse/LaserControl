classdef laser_view_si_hooked < laserControl.gui.laser_view
    % sub-class of laser_view that can be hooked into ScanImage
    % 

    properties
        hSI
        buttonReadSettings %To force read from laser when GUI is not in update mode
    end


    properties (Hidden, SetObservable, AbortSet)
        isSIAcquiring %True if scanner is acquiring data
    end


    methods
        function obj = laser_view_si_hooked(hLaser)
            obj = obj@laserControl.gui.laser_view(hLaser)
            obj.connectScanImage;

            %If ScanImage is connected we can build additional GUI components
            if ~isempty(obj.hSI)
            obj.listeners{end+1} = addlistener(obj.hSI, 'acqState', 'PostSet', @obj.isAcquiring);
            end
        end

        function delete(obj)
            obj.hSI=[];
            delete@laserControl.gui.laser_view(obj);
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


        function acquiring = isAcquiring(obj,~,~)
            %Returns true if a focus, loop, or grab is in progress even if the system is not
            %currently acquiring a frame. Stops the regular update timer, etc, during
            %acquisition. 

            if strcmp(obj.hSI.acqState,'idle') || strcmp(obj.hSI.acqState,'point')
                obj.isSIAcquiring = false;
            else
                obj.isSIAcquiring = true;
            end

            if obj.isSIAcquiring
                obj.disableRegularGUIupdates
            else
                obj.enableRegularGUIupdates
            end

        end %isAcquiring


        function enableRegularGUIupdates(obj)
            fprintf('Resuming regular laser GUI updates.\n')
            if ~strcmp(obj.laserViewUpdateTimer.Running,'on')
                start(obj.laserViewUpdateTimer)
            end
            %TODO: visual changes that GUI has stopped updating
        end


        function disableRegularGUIupdates(obj)
            fprintf('Stopping regular laser GUI updates.\n')
            if ~strcmp(obj.laserViewUpdateTimer.Running,'off')
                stop(obj.laserViewUpdateTimer)
            end
            %TODO: visual changes that GUI has stopped updating
        end

    end %methods

end %classdef