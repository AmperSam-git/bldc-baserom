# BLDC Baserom

This is the source of SMW Central's Baserom Level Design Contest baserom.

## Getting Started

The first thing you're going to do is provide your copy of Super Mario World. For the build system to work properly, you'll need to provide a clean copy of a headered (U) [!] ROM Super Mario World ROM renamed to 'clean.smc'. Ensure the file extension is `.smc` and not `.sfc`.

### Initialize the Baserom

To start using the baserom you will first have to initialize the baserom folder and download all of the tools used by it. You can do this by running `@initialize_baserom.bat` this will check for all of the tools used by the build system and download them on demand. This is done to keep the baserom pretty lean and avoid distributing a lot of executables and binary files.

## Building the Baserom

To make life easier for you as a hacker, this baserom has a few build tools included that will automagically rebuild your hack everytime you make changes to it.

### Lunar Helper

When working on your hack Lunar Helper is your new best friend, you can find it by running `Lunar Helper.exe` in the LunarHelper folder. This tool will entirely rebuild your rom (from scratch) each time you want to add (or remove) things to make sure it all builds smoothly. It will also help you with quickly editing, testing and packaging your hack for distribution. See the Lunar Helper readme in the Docs folder for more information.

### Lunar Monitor

In addition to Lunar Helper, a tool is bundled with Lunar Magic to monitor your hack and enable you to quickly export levels, map16, palettes and so forth for rebuilding instead of doing so manually. You'll find when you open Lunar Magic, there will be a new button between the Save and Undo buttons in the toolbar to enable this with one-click. See the Lunar Monitor readme in the Docs folder for more information.

## Resource Credits

It is good practice to keep track of all resources used in your hacks if you can help it and credit their authors. See the included [CREDITS.txt](CREDITS.txt) file for a list of all resources included in the baserom.

Important: this project has no license nor do the authors or organizers claim any rights to the resources included in this project, those remain the rights of their respective authors.