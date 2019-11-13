classdef (Abstract) aom < handle
%%  aom
%
% The aom abstract class is a software entity that represents the physical
% acousto-optical modulator that is used to control AOM power at the sample. 
%
% The aom abstract class declares methods and properties that are used by the 
% AOM contol object to set AOM frequency and power such that the first order
% beam is undeflected and is at maximum intensity. The user also interacts with 
% the aom controller to tweak RF power when a new AOM wavelength is selected.
%
% Classes the control the AOM must inherit aom. Objects that inherit aom 
% are "attached" to instances of the AOM class. 
%
% An example of a class that inherits aom is MPDSaom
%
% Rob Campbell - SWC 2019


    properties 

        hC  %A handle to the hardware object or port (e.g. COM port) used to 
            %control the aom.

        controllerID % The information required by the method that connects to the 
                     % the controller at connect-time. This can be specified in whatever
                     % way is most suitable for the hardware at hand. 
                     % e.g. COM port ID string
    end %close public properties

    properties (Hidden)
        parent  %A copy of the parent object (likely one of class AOM) to which this component is attached
    end %close hidden properties


    % These are GUI-related properties. The view class that comprises the GUI listens to changes in these
    % properties to know when to update the GUI. It is therefore necessary for these to be updated as 
    % appropriate by classes which inherit AOM. e.g. If the shutter is opened then the shutterOpen 
    % property must be set to true. Failing to do this will cause the GUI to fail to update. All 
    % properties in this section should be updated in the constructor once the AOM is connected
    properties (Hidden, SetObservable, AbortSet)
        currentFrequency=-1
        targetFrequency=0
        
        currentPower
        targetPower
        
        minFrequency
        maxFrequency
 
        minPower
        maxPower

        enableChannel=true
        enableBlanking=true

        isAomConnected=false % Set by isControllerConnected
        isAomReady=false % Must be updated by isReady
    end %close GUI-related properties



    % The following are all critical methods that your class should define
    % You should also define a suitable destructor to clean up after you class
    methods (Abstract)
        success = connect(obj)
        % connect
        %
        % Behavior
        % Establishes a connection between the hardware device and the host PC. 
        % The method uses the controllerID property to establish the connection. 
        %
        % Outputs
        % success - true or false depending on whether a connection was established


        success = isControllerConnected(obj)
        % isControllerConnected
        %
        % Behavior
        % Reports whether the link to the AOM is functional. This method must update
        % the hidden property isAOMConnected. If the interface, e.g. the COM port
        % is closed, the function must return false. 
        %
        % Outputs
        % success - true or false depending on whether a working connection is present 
        %           with the physical AOM device (or whatever device controls it). 
        %           i.e. it is not sufficient that, say, a COM port is open. For success 
        %           to be true, the AOM must prove that it can interact in some way 
        %           with the host PC.  


        [AOMReady,msg] = isReady(obj)
        % isReady
        %
        % Behavior
        % Returns true if the AOM is currently in a state in which it is able to 
        % excite the sample. So it should be, for example, turned on, modelocked,
        % with the shutter open, etc, etc. This command will be called at least
        % once per section. If it returns false the acquisition will stop and wait for
        % user intervention. Updates the hidden property isAOMReady.
        %
        %
        % Outputs
        % AOMReady - true/false depending on whether the AOM is turned on and ready to go.
        % msg- if the AOM is not ready, it should return a string that indicates the 
        %      the reason for the failure. This will be logged or sent as a Slack or 
        %      e-mail message to the operator. 

        frequency = readFrequency(obj)
        % readFrequency
        %
        % Behavior
        % Reads the currently set frequency of the AOM and returns the value in Hz. 
        % Returns zero if the AOM is switched off. 
        % Returns empty if it fails. 
        % Updates the hidden property currentFrequency
        % On failing to read the wavelength, set currentFrequencyto zero. 
        %
        % Outputs
        % frequency - a scalar defining the AOM's current frequency. 


        success = setFrequency(obj, frequencyInHz)
        % setWavelength
        %
        % Behavior
        % Sets the AOM to a new frequency and updates hidden property
        % targetFrequency
        %
        % Inputs
        % frequencyInHz - scalar defining frequency in Hz
        %
        % Outputs
        % success - true or false depending on whether the command succeeded


        AOMPower = readPower(obj)
        % readPower
        %
        % Behavior
        % Reads the current AOM power and returns the value as a scalar integer in mW.
        % It should discard the decimal point. Returns zero if the AOM is switched off. 
        % Returns empty if it fails.
        %
        %
        % Outputs
        % AOMPower - a scalar defining the AOM's current power in dB.
     
        
        success = setPower(obj, powerIndB)
        % setWavelength
        %
        % Behavior
        % Sets the AOM to a new power and updates hidden property
        % targetPower
        %
        % Inputs
        % powerIndB - scalar defining power in dB
        %
        % Outputs
        % success - true or false depending on whether the command succeeded

  
        AOMID = readAOMID(obj)
        % readAOMID
        %
        % Behavior
        % Returns a string that contains the AOM serial number, ID, etc. 
        % If your AOM has a serial command that returns this information then you
        % may use this. Failing that, you could hard-code the details into the 
        % class or have it read the details from a text file you make. If you really
        % don't care about logging this, then your method should just return the AOM
        % model as a string. 
        %
        % You choose...

    end %close abstract methods


    %The following methods are common to all AOMs
    methods
        function [inRange,msg] = isTargetFrequencyInRange(obj,targetFrequency)
            %Return false if the target frequency supplied by the user is
            %out of the allowed range. True otherwise. targetFrequency is
            %defined in Hz. 
            if targetFrequency<obj.minPower || targetFrequency>obj.maxPower
                msg=sprintf('Wavelength %d nm is out of range -- max=%d nm, min=%d nm\n', ...
                    targetFrequency, obj.maxWavelength, obj.minWavelength);
                sprintf(msg);
                inRange=false;
                return
            end
            msg='';
            inRange=true;
        end
        
        function [inRange,msg] = isTargetPowerInRange(obj,targetPower)
            %Return false if the target power supplied by the user is
            %out of the allowed range. True otherwise. targetPower is
            %defined in dB. 
            if targetPower<obj.minPower || targetPower>obj.maxPower
                msg=sprintf('Wavelength %d nm is out of range -- max=%d nm, min=%d nm\n', ...
                    targetPower, obj.maxWavelength, obj.minWavelength);
                sprintf(msg);
                inRange=false;
                return
            end
            msg='';
            inRange=true;
        end

    end %close methods

end %close classdef
