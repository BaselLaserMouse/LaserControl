function [settings,pathToFile] = readSettings
    % Read BakingTray component settings
    %
    % function [settings,pathToFile] = laserControl.settings.readSettings
    %
    % Purpose
    %
    %
    % Outputs
    % settings - a structure containing the settings
    % pathToFile - path to the settings file
    %
    %
    % Rob Campbell - Basel 2017



    settingsDir = laserControl.settings.settingsLocation;
    if isempty(settingsDir)
        return
    end

    pathToFile = fullfile(settingsDir,'laser_Settings.m');

    if ~exist(pathToFile,'file')
        fprintf('\n **** Can not find a component settings file in %s%s\n', settingsDir,filesep)
        fprintf(' **** Copying an empty file to this location but you will need to edit it ****\n\n')
        defaultFile=which('laser_Settings_empty.m');
        copyfile(defaultFile,pathToFile)
        [settings,pathToFile] = laserControl.settings.readSettings;
        return
    end


    % For neatness we don't have the settings directory in the path, so we
    % cd to it, run it, then return to the current directory. 
    CWD=pwd;
    cd(settingsDir);
    if exist('./laser_Settings.m','file')
        settings=laser_Settings;
    else
        fprintf('Can not find laser_Settings.m in %s.\n', settingsDir) %Should be impossible
        return
    end
    cd(CWD)


    if isempty(settings.laser.type)
        fprintf('** Laser not defined in settings file at %s\n', ...
            laserControl.settings.settingsLocation)
    end
