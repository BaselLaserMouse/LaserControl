function writeCurrentStateToSettingsFile(obj)
    settings.referenceWavelength = obj.referenceWavelength;
    settings.referenceFrequency = obj.referenceFrequency;
    settings.powerTable = obj.powerTable;

    settings.blankingEnabled = obj.readAOMBlankingEnabled;
    settings.blankingState = obj.readAOMBlankingState;
    settings.chanOneEnabled = obj.readChannelEnabled; %We have only one channel
    settings.chanOneState = obj.readChannelState; %We have only one channel

    fprintf('Saving settings to %s\n',obj.settingsPath)
    save(obj.settingsPath,'settings')
end