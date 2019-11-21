function varargout=startLaserControl
% Start the laser GUI with attached AOM as an option
%
% startLaserControl
%
% Inputs
% none
%
% Outputs
% hLaserControl - object for GUI, laser, and optionally AOM.


% Read laser settings from file
settings = laserControl.settings.readSettings;
hLaser = [];
if isempty(settings.laser.type)
    return
end
    


% Build laser
hLaser = buildComponent(settings.laser.type,settings.laser.COM);



% Optionally build the AOM and link to the laser
if ~isempty(settings.aom.type)
    fprintf('Connecting to AOM and linking to laser\n')
    hLaser.hAOM = buildComponent(settings.aom.type,settings.aom.COM);
    hLaser.hAOM.linkToLaser(hLaser);
else
    hAOM=[];
end

% Attempt to link to ScanImage
success = laserControl.scanimage.integrateLaser(hLaser);

if success == false
    % Open GUI as standalone if link to ScanImage failed
    hLaserControl.hLaser = hLaser;
    hLaserControl.hGUI_laser = laserControl.gui.laser_view_si_hooked(hLaser);
end

if nargout>0
    varargout{1}=hLaserControl;
end




function thisComponent = buildComponent(componentName,varargin)
    %Build the correct object based on "componentName"
    COMPORT = laserControl.settings.parseComPort(varargin{1});

    switch componentName
        case 'dummyLaser'
            thisComponent = laserControl.dummyLaser;
        case 'maitai'
            thisComponent = laserControl.maitai(COMPORT);
        case 'chameleon'
            thisComponent = laserControl.chameleon(COMPORT);
        case 'MPDSaom'
            thisComponent = laserControl.MPDSaom(COMPORT);
        otherwise
            fprintf('ERROR: unknown laser component "%s" SKIPPING BUILDING\n', laserName)
            thisComponent=[];
            return
    end

