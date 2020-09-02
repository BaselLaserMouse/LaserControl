# MATLAB Laser Control

Laser and AOM control classes for MATLAB. 
Currently supports:
* SpectraPhysics MaiTai (all models)
* Coherent Chameleon. 
* MPDS AOM from [AA Opto-Electronic](http://www.aaoptoelectronic.com/)

## Features
* The AOM control is linked to laser wavelength and automatically adjusts AOM
frequency and RF power as wavelength alters. 
* Laser GUI can be started from the View menu in ScanImage. 
* Laser GUI updating is suspended during ScanImage acquisition to avoid pausing display. 


## Installation
* Add the `code` directory to your MATLAB path. 
* In MATLAB run `laserControl.settings.readSettings` then go to the settings file in the path reported to screen and fill in the missing settings.

## Example
Note that to run all the following examples, the manufacturer's control software must first be closed. 

Basic low-level control without a GUI:
```
>> MT = laserControl.maitai('COM1'); %substitute your COM port and laser
>> MT.turnOn
>> MT.openShutter
```

Starting a GUI based on above class
```
hGUI = laserControl.gui.laser_view(MT);
```

The GUI polls the laser regularly. 
This will cause brief pauses to the ScanImage live display (does not affect stored data) during acquisition. 
To avoid this instead do:
```
>> hGUI = laserControl.gui.laser_view_si_hooked(MT);
```
That loads a sub-class of `laser_view` that is aware of ScanImage. 


To also control an AOM in tandem with the laser do:
```
>> hLaser = laserControl.maitai('COM1');
>> hLaser.hAOM = laserControl.MPDSaom('COM3'); %substitute your COM port
>> hLaser.hAOM.linkToLaser(hLaser);
>> hGUI = laserControl.gui.laser_view_si_hooked(hLaser);
```

The above is automated by the startup script `startLaserControl`.
For this to work you will need a settings file. 
First run `laserControl.settings.readSettings` and edit the settings file in the path displayed on your command line. 
Then you run `startLaserControl`.
If ScanImage is already started then the laser GUI can be started from the View menu in ScanImage.
Otherwise the GUI appears automatically. 
To start the AOM GUI alone run `startAOMControl`. 


For that to work you will need to edit the settings file created in the SETTINGS directory the first time you run the above command. Simply fill in the laser name and the COM port index to which the laser is connected. 


## AOM GUI usage instructions
You will need to tweak the RF power by wavelength:
* Start ScanImage. Run `startLaserControl`.
* Ensure External voltage control is checked and external blanking is unchecked (or that you have enabled the AOM with an external TTL line).
* Press "Enter tweak"
* Set the laser wavelength to a desired value. Wait for the laser to reach wavelength. 
* Edit the RF power box until power in first order beam is max.
* Repeat for other values. 
* Press "Show Fig" to see the curve ([currently](https://github.com/BaselLaserMouse/LaserControl/issues/12) this button needs to be pressed each time to manually update the plot).
* Once happy hit "Leave tweak" then "Save settings".

Optionally, if needed, you can alter the RF frequency associated with each wavelength. 
To do this:
* Press "Tune laser to reference wavelength".
* Alter the frequency in the box
* Press "Update ref frequency"
* Press "Save settings"


## Advanced using: command line control of AOM
```
>> LC = startLaserControl
LC = 

  struct with fields:

    hLaser: [1×1 laserControl.maitai]
      hGUI: [1×1 laserControl.gui.laser_view]

%% Upon tuning laser in GUI the AOM changes frequency and power
Tuning to 920 nm: AOM at 100.61 MHz & power at 520


```
To set the reference freq tune laser to 890 (or whatever is in `LC.hAOM.referenceWavelength`).
To do this you have these commands:


```
>> LC.hLaser.hAOM.readFrequency

ans =

   104
   
%and to set it:
>> LC.hLaser.hAOM.setFrequency(111.11);



% and we can nudge:

>> LC.hLaser.hAOM.nudgeFreqUp
111.111 MHz
% etc
>> LC.hLaser.hAOM.nudgeFreqDown
111.113 MHz
% etc

```

Then we find the correct frequency for the reference wavelength and set it in the object like this:
```
>> LC.hAOM.referenceFrequency=111.11; 
```


Setting RF power of AOM is the same:

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
* v0.11.00 - Add sub-class laser GUI that will be attached to ScanImage
* v0.13.00 - Tie up loose ends and start work on full GUI for AOM.
* v0.14.00 - AOM GUI reads from model. Saves and loads settings. 
* v0.15.00 - AOM GUI sets values in model. 
* v0.16.00 - AOM GUI is talking to ScanImage via SI-hookable Laser GUI.
* v0.16.50 - Link to ScanImage for laser control is working. Test in simulated mode. 
* v0.17.50 - Working with real ScanImage.
* v0.18.00 - Tested and fixed bugs. All works as expected.
* v0.19.00 - Start script for AOM GUI on its own.
