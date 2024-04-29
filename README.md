Generates a base docker container for building a program in Ubuntu
This was written to run software on an unsupported version of Ubuntu

## QUICKSTART:
cd wireshark
chmod +x ../gen-dockerfile.sh && ../gen-dockerfile.sh
chmod +x run.sh && ./run.sh

## Additional Features:
The configuration file is called ".gendocker", and it contains information such as project name,
base image, and build dependencies.  For the full list of options, see "templates/gendocker.template"

The run.sh script was build for a generic run.  In order to tweak the run command, run with the
"--dry-run" option to print the docker run command.

## New Development
Using the templates as a starting point, feel free to add more programs!
