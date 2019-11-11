classdef MPDSaom < aom
%%  MPDSaom - control class for OptoElectronic MPDFnCxx opto-acoustic modulators
%
% Example
% M = MPDSaom('COM1');
%
%
% For detailed method docs, please see the aom abstract class. 
%
%
% Rob Campbell - SWC 2019



    methods
        function obj = MPDSaom(serialComms)
        end
        
        function delete(obj)
        end


        function success = isControllerConnected(obj)
        end
        
        
        function [AOMReady,msg] = isReady(obj)
        end

        
        function frequency = readFrequency(obj)
        end
        

        function success = setFrequency(obj, frequencyInHz)
        end
        

        function AOMPower = readPower(obj)
        end
        
        
        function success = setPower(obj, powerIndB)
        end

  
        function AOMID = readAOMID(obj)
        end
        
    end %close abstract methods


    
end %close classdef
