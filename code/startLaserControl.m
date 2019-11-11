function startLaserControl

    settings = laserControl.settings.readSettings;
    
    if isempty(settings.laser.type)
        return
    end