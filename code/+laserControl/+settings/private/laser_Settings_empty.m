function settings=laser_Settings
    % laser settings file
    %



    %-------------------------------------------------------------------------------------------
    % Laser
    laser.type=''; % One of: 'maitai', 'chameleon', or 'dummyLaser'
    laser.COM=[];  % COM port number on which the laser is attached. e.g. the scalar 1




    %-------------------------------------------------------------------------------------------
    % AOM
    aom.type=''; % One of: 'XXX' or left empty
    aom.COM=[];  % COM port number on which the cutter is attached


    %-------------------------------------------------------------------------------------------
    % Assemble the output structure
    % -----> DO NOT EDIT BELOW THIS LINE <-----
    settings.laser   = laser ;
    settings.aom     = aom ;
    %-------------------------------------------------------------------------------------------

