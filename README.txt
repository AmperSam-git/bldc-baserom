-----------------
Welcome to BLDC2!
-----------------


Getting Started
---------------
Apply "BLDC2.bps" to clean (headered) copy of Super Mario World and save it in the main baserom folder as BLDC2.smc (not .sfc)

NOTE: it is important for all the metadata files have the same name as your rom file to work appropriately.


Baserom Notes
-------------
The baserom was built with Lunar Magic 3.31, to avoid possible problems related to Lunar Magic version it's recommended to make your level with that same version (3.31).


Help & Documentation
-------------
The "Docs" folder in the main baserom directory has files with information about all the things included in the baserom. Please consult those before seeking assistance, they may already have answers.

However, if you have need assistance, reach out on the SMW Central Discord channels for this event or in the event subforum on the website.


Using AddMusicK
---------------
Adding custom music is permitted for this contest but in order for the retry system's death SFX to work, some files are included for AddMusicK (in "AMK Files" folder) ought to be included in your project. If you forget to include these it will be alright.


Retry System
------------
This baserom has a Retry System applied and by default is set to play the vanilla death sequence, but this can be changed with some custom objects (see "What's What - UberASM Objects" in the Docs folder for more details).

Some other settings that are on by default are:

 - Checkpoint Saving, all checkpoints will be saved to SRAM
 - Saving after Game Over
 - START+SELECT to exit is on for every level, this is enabled as an anti-softlock measure
 - RNG is reset for all levels