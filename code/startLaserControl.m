function hLaser=startLaserControl

    settings = laserControl.settings.readSettings;
    hLaser = [];
    if isempty(settings.laser.type)
        return
    end
    


    hLaser = buildLaserComponent(settings.laser.type,settings.laser.COM);







    function thisLaser = buildLaserComponent(laserName,varargin)

    validComponentSuperClassName = 'laser'; %The name of the abstract class that all laser components must inherit


    %Build the correct object based on "laserName"
    switch laserName
        case 'dummyLaser'
            thisLaser = dummyLaser;
        case 'maitai'
            COMPORT = laserControl.settings.parseComPort(varargin{1});
            thisLaser = maitai(COMPORT);
        case 'chameleon'
            COMPORT = laserControl.settings.parseComPort(varargin{1});
            thisLaser = chameleon(COMPORT);
            return
        otherwise
            fprintf('ERROR: unknown laser component "%s" SKIPPING BUILDING\n', laserName)
            thisLaser=[];
            return
    end


    % Do not return component if it's not of the correct class. 
    % e.g. this can happen if the class doesn't inherit the correct abstract class
    if ~isa(thisLaser,validComponentSuperClassName)
        fprintf('ERROR: constructed component %s is not of class %s. SKIPPING BUILDING.\n', ...
         laserName, validComponentSuperClassName);
        delete(thisLaser) %To clean up any open ports, etc
        thisLaser = [];
    end

