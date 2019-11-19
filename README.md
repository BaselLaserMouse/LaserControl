# MATLAB Laser Control

Laser control classes for MATLAB. 
Currently supports SpectraPhysics MaiTai (all models) and Coherent Chameleon. 
Basic GUI.


## Example

Basic low-level control
```
>> MT = maitai('COM1');
>> MT.turnOn
>> MT.openShutter
```

To start the GUI:
```
>> startLaserControl
```

For that to work you will need to edit the settings file created in the SETTINGS directory the first time you run the above command. Simply fill in the laser name and the COM port index to which the laser is connected. 


## Planned changes
* GUI so user can tweak AOM power and add current power to lookup table. 
* Is it possible to run polling of serial line in the background? (So it does not block and cause small pause of ScanImage GUI updates). 


## Version History
* v0.0.00 - Basic MaiTai control at command line.
* v0.2.00 - Add Chameleon, settings file, GUI and GUI starter, boilerplate AOM control in `dev` branch, improve wavelength polling. 
* v0.5.00 - `dev` branch MPDS AOM code now interacts with AOM correctly in all major ways.
* v0.5.50 - MPDS AOM: Power and frequency nudge up/down works. Raw power setting (the register value) works.
* v0.6.50 - MPDS AOM: Is now linked to laser and changes frequency and power automatically.
* v0.7.00 - startLaserControl now starts the laser and AOM.
* v0.9.00 - More fine-grained options for setting AOM modes. Tested with laser. 
* v0.9.30 - Settings load and save from disk.