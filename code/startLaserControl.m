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
    fprintf('No laser defined in settings file\n')
    return
end
    


% Build laser
hLaser = laserControl.settings.buildComponent(settings.laser.type,settings.laser.COM);



% Optionally build the AOM and link to the laser
if ~isempty(settings.aom.type)
    fprintf('Connecting to AOM and linking to laser\n')
    hLaser.hAOM = laserControl.settings.buildComponent(settings.aom.type,settings.aom.COM);
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
