function removeRF_powerFromTable(obj)
    % If the current wavelength of the laser corresponds to an RF power value
    % then we can optionally remove it from the table


    if isempty(obj.laser)
        return
    end

    Lw=obj.laser.currentWavelength;
    pT=obj.powerTable;

    % If the wavelength already exists in the table then we can remove it. 
    f=find(pT(:,1)==Lw);
    if ~isempty(f)
        obj.powerTable(f,:) = [];
    else
        fprintf('Laser wavelength of %d is not in the power table. Not removing any values.\n', Lw)
    end

end