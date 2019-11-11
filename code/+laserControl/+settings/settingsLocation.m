function settingsDir=settingsLocation
    % Return user settings location of the LaserControl package
    %
	% function settingsDir=laserControl.settings.settingsLocation
	%
	% Prurpose
    % Return user settings directory location of the LaserControl package to 
    % the command line. Makes the directory if needed. Returns an empty 
    % string on error.
    % 


    installDir = laserControl.settings.installLocation;
    if isempty(installDir)
    	settingsDir=[];
        return
    end

    settingsDir = fullfile(installDir,'SETTINGS');

    %Make the settings directory if needed
    if ~exist(settingsDir,'dir')
        success=mkdir(settingsDir);
        if ~success
            fprintf('FAILED TO MAKE SETTINGS DIRECTORY: %s. Check the permissions and try again\n', settingsDir);
            return
        end
    end