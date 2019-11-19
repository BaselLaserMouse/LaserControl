function newRF_powerVal = interpPowerValue(obj)
    % Choose a default value for the AOM RF power for the current
    % wavelength based upon existing values in the power table. 
    % Does this by generating an interpolated power value based 
    % on existing values. Interpolates between adjacent larger and 
    % smaller values on the table. If no larger or smaller value 
    % exists then takes the nearest value. 
    %
    % If the value already exists then we return the existing value
    if isempty(obj.laser)
        newRF_powerVal=[];
        return
    end

    Lw=obj.laser.currentWavelength;
    pT=obj.powerTable;

    % If the wavelength already exists in the table then return
    % the existing value
    f=find(pT(:,1)==Lw);
    if ~isempty(f)
        newRF_powerVal = pT(f,2);
        return
    end

    % If this value does not existin the table then we need
    % find a plausible value. 
    if all( (pT(:,1)-Lw)<0) %greater than all wavelength values
        newRF_powerVal = pT(end,2); % Value of largest existing wavelength
    elseif all( (pT(:,1)-Lw)>0) %smaller than all wavelength values
        newRF_powerVal = pT(1,2); %value of smallest existing wavelength
    else 
        %Get the adjacent wavelength values above and below the 
        %current laser wavelength.
        fAbove = find((pT(:,1)-Lw>0));
        Labove = pT(fAbove(1),1);
        fBelow = find((pT(:,1)-Lw<0));
        Lbelow = pT(fBelow(end),1);
        % Linearly interpolate
        p=(Lw-Lbelow)/(Labove-Lbelow);
        newRF_powerVal = pT(fBelow(end),2) + (pT(fAbove(1),2)-pT(fBelow(end),2))*p;
    end
end