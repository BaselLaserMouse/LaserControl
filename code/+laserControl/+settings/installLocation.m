function installPath = installLocation
    % Return install location of the LaserControl package to the command line
    %
    % function installPath = laserControl.settings.installLocation
    %
    %
    % Purpose
    % Return the full path to the install location of the LaserControl 
    % package to the command line. The path returned is root path of the whole
    % package, not the path to the code directory. i.e. it's the directory 
    % that *contains* the code directory and readme file. 
    %
    % Returns an empty string on error.
    % 
    % Inputs
    % None
    %
    % Outputs
    % installPath - String defining path to install location. 
    %               Empty if something went wrong.
    %
    %
    % 


    pth = which('startLaserControl');

    installPath = regexprep(pth,['code\',filesep,'startLaserControl\.m'],''); %Strip the end of the path. 

    if ~exist(installPath,'dir')
        fprintf(['Install location expected at %s but not found there\n'...
            'Your LaserControl install might be broken'],installPath)
        installPath=[];
    end

