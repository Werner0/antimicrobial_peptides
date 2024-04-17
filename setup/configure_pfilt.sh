#!/bin/bash

# Untar the pfilt tarball
tar -xzf pfilt1.5.tar.gz

# Move to extracted directory
cd pfilt

# Compile pfilt
make

# Copy the pfilt executable to the Conda environment's bin directory
cp pfilt $CONDA_PREFIX/bin

# Return to working directory
cd - > /dev/null
rm -r pfilt

# Run stat and redirect its output to /dev/null
stat $CONDA_PREFIX/bin/pfilt > /dev/null 2>&1

# Check the exit status of the stat command
if [ $? -eq 0 ]; then
	    echo "Pfilt successfully placed in conda environment path"
    else
	        echo "Installation failed"
fi

