function success=loadSettingsFromDisk(obj)
    if ~exist(obj.settingsPath,'file')
        success=false;
        fprintf('Failed to find settings file at path: %s\n',obj.settingsPath)
        return
    end

    fprintf('Loading AOM settings from disk and applying\n')
    load(obj.settingsPath);
    obj.referenceWavelength = settings.referenceWavelength;
    obj.referenceFrequency = settings.referenceFrequency;
    obj.powerTable = settings.powerTable;

    successes=zeros(1,4);
    if settings.blankingEnabled
        successes(1)=obj.enableAOMBlanking;
    else
        successes(1)=obj.disableAOMBlanking;
    end

    if strcmp(settings.blankingState,'internal')
        successes(2)=obj.internalAOMBlanking;
    else
        successes(2)=obj.externalAOMBlanking;
    end

    if settings.chanOneEnabled
        successes(3)=obj.enableChannel;
    else
        successes(3)=obj.disableChannel;
    end

    if strcmp(settings.chanOneState,'internal')
        successes(4)=obj.internalChannel;
    else
        successes(4)=obj.externalChannel;
    end

    success=all(successes);

    if ~success
        fprintf('Some settings failed to set correctly\n')
    end

end