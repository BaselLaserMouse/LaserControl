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


## Using the AOM
```
>> LC = startLaserControl
LC = 

  struct with fields:

    hLaser: [1×1 laserControl.maitai]
      hGUI: [1×1 laserControl.gui.laser_view]
      hAOM: [1×1 laserControl.MPDSaom]

%% Upon tuning laser in GUI the AOM changes frequency and power
Tuning to 920 nm: AOM at 100.61 MHz & power at 520

```
To set the reference freq tune laser to 890 (or whatever is in `LC.hAOM.referenceWavelength`).
To do this you have these commands:
```

>> LC.hAOM.readFrequency

ans =

   104
   
%and to set it:
>> LC.hAOM.setFrequency(111.11);



% and we can nudge:

>> LC.hAOM.nudgeFreqUp
111.111 MHz
>> LC.hAOM.nudgeFreqUp
111.112 MHz
>> LC.hAOM.nudgeFreqUp
111.113 MHz
>> LC.hAOM.nudgeFreqUp
111.114 MHz
>> LC.hAOM.nudgeFreqDown
111.113 MHz
>> LC.hAOM.nudgeFreqDown
111.112 MHz
>> LC.hAOM.nudgeFreqDown
111.111 MHz
>> LC.hAOM.nudgeFreqDown
111.110 MHz
```

Then we find the correct frequency for the reference wavelength and set it in the object like this:
```
>> LC.hAOM.referenceFrequency=111.11; 
```


Set RF power of AOM is the same:

```

>> LC.hAOM.readPower_dB

ans =

   11.6000

>> LC.hAOM.setPower_dB(15)

ans =

  logical

   1

>> LC.hAOM.readPower_dB

ans =

    15

>> LC.hAOM.nudgePowerUp
P=618(15.0dBm)
>> LC.hAOM.nudgePowerUp
P=619(15.0dBm)
>> LC.hAOM.nudgePowerUp
P=620(15.1dBm)
>> LC.hAOM.nudgePowerUp
P=621(15.1dBm)
>> LC.hAOM.setPower_raw(666)

ans =

  logical

   1

>> LC.hAOM.readPower_dB

ans =

   16.6000
```

```
>> LC.hAOM.powerTable

ans =

   890   500
   920   520
```


   
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
* v0.9.50 - Settings load and save from disk.
* v0.10.50 - Insert current RF power into table, produce reasonable interpolated value if necessary, plot to show RF power (can be converted into something fancier fairly easily). 
