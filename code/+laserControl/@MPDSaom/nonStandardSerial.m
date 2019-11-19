function outStr = nonStandardSerial(obj,commandString)
    % Serial read command for the weird commands that don't use a CR and return a question mark
    obj.hC.Terminator='';
    fprintf(obj.hC,commandString); %Because this command does not need a CR
    obj.hC.Terminator='?'; % Yeah...
    outStr = fgets(obj.hC);
    obj.hC.Terminator='CR';
end