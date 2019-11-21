function varargout=startAOMControl
% Start the AOM control GUI without connecting to a laser
%
% startAOMControl
%
% Inputs
% none
%
% Outputs
% hControl - object for GUI and AOM.


% Read laser settings from file
settings = laserControl.settings.readSettings;
hAOM = [];
if isempty(settings.aom.type)
    fprintf('No AOM defined in settings file\n')
    return
end
    

hControl.hAOM = laserControl.settings.buildComponent(settings.aom.type,settings.aom.COM);
hControl.hGUI = laserControl.gui.aom_view(hControl.hAOM);

if nargout>0
    varargout{1}=hControl;
end
