function thisComponent = buildComponent(componentName,varargin)
%Build the correct object based on "componentName"
%
% function thisComponent = buildComponent(componentName,varargin)
%
%

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

