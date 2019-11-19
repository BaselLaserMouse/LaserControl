function [success,reply]=sendAndReceiveSerial(obj,commandString,waitForReply)
    % Send a serial command and optionally read back the reply 
    if nargin<3
        waitForReply=true;
    end

    if isempty(commandString) || ~ischar(commandString)
        reply='';
        success=false;
        return
    end

    fprintf(obj.hC,commandString);

    if ~waitForReply
        reply=[];
        success=true;
        if obj.hC.BytesAvailable>0
            fprintf('Not waiting for reply by there are %d BytesAvailable\n',obj.hC.BytesAvailable)
        end
        return
    end

    reply=fgets(obj.hC);
    doFlush=1;
    if obj.hC.BytesAvailable>0
        if doFlush
            fprintf('Read in from the MPDSaom buffer using command "%s" but there are still %d BytesAvailable. Flushing.\n', ...
                commandString, obj.hC.BytesAvailable)
            flushinput(obj.hC)
        else
            fprintf('Read in from the MPDSaom buffer using command "%s" but there are still %d BytesAvailable. NOT FLUSHING.\n', ...
                commandString, obj.hC.BytesAvailable)
        end
    end

    if ~isempty(reply)
        reply(end)=[];
    else
        msg=sprintf('MPDSaom serial command %s did not return a reply\n',commandString);
        success=false;
        return
    end

    success=true;
end