# BLDC Baserom

This is the source of SMW Central's Baserom Level Design Contest baserom.

## Getting Started

The first thing you're going to do is provide your copy of Super Mario World. For the build system to work properly, you'll need to provide a clean copy of a headered (U) [!] ROM Super Mario World ROM renamed to 'clean.smc'. Ensure the file extension is `.smc` and not `.sfc`.

### Initialize the Baserom

To start using the baserom you will first have to initialize the baserom folder and download all of the tools used by it. You can do this by running `@initialize_baserom.bat` this will check for all of the tools used by the build system and download them on demand. This is done to keep the baserom pretty lean and avoid distributing a lot of executables and binary files.

## Building the Baserom

This baserom was built with Lunar Helper and is your new best friend, run the `LunarHelper.exe` in the LunarHelper folder to get started. This tool will entirely rebuild the baserom (from scratch) to make sure it all assembles smoothly. It will also help you with quickly editing, testing and packaging.

Lunar Helper is bundled with with Lunar Monitor which exports modified levels, map16, palettes and so forth for rebuilding instead of doing so manually. You'll find when you open Lunar Magic via the "Edit" action in Lunar Helper, there will be a toolbar button between the Save and Undo buttons to run a manual export.

## Resource Credits

See [CREDITS.txt](CREDITS.txt) file for a list of all resources included in the baserom.

Important: this project has no license nor do the authors or organizers claim any rights to the resources included in this project, those remain the rights of their respective authors.