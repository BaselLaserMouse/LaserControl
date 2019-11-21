function insertCurrentRF_powerIntoTable(obj)
    % Insert current RF power into table. Over-writes the existing value
    % if it's already there.

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
        obj.powerTable(f,2) = obj.readPower_dB;
    else
        pT(end+1,:) = [Lw,obj.readPower_dB];
        [~,ind]=sort(pT(:,1));
        obj.powerTable  = pT(ind,:);
    end

end