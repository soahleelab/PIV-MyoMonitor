# PIV-MyoMonitor
We developed an open-source, particle image velocimetry-based software (PIV-MyoMonitor) for reliable and comprehensive contractility analysis in both two- and three-dimensional cardiac models using standard lab equipment.

# Setup for PIV-MyoMonitor
### 1. Installation - MATLAB
PIV-MyoMonitor is MATLAB-based open source software and requires MATLAB to be installed in order to use it. 

Here is a link to install MATLAB from Mathworks :
https://www.mathworks.com/products/matlab.html

### 2. Installation - PIVlab
The FFT based particle image velocimetry algorithm of PIV-MyoMonitor uses the piv_FFTmulti function of MATLAB's toolbox PIVlab version 1.43. Therefore, it requires installation of the toolbox. 

Here is a link to install PIVlab 1.43 version:

https://www.mathworks.com/matlabcentral/fileexchange/27659-pivlab-particle-image-velocimetry-piv-tool-with-gui

![pivlab](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/cfe8515a-371a-4f53-90f5-b8b517222feb)

# PIV-MyoMonitor Running Tutorial
### 1. Pre-Run Directory Setup
PIV-MyoMonitor takes in a video with an mp4 or avi extension and analyzes it. Convenience updates such as batch analysis are planned in the future, but they don't exist in the current version, so you'll need to sort the directories in a way that makes sense for the analysis before you start. But don't worry, it's not that complicated a request, just create an empty folder and move the video files you want to analyze into it and start analyzing them. If you have multiple videos, make sure they're stored in separate folders, and inside each folder you'll have the analysis results for each video. 
### 2. Start Analysis
If you've made it this far, make sure the video you want to analyze is in mp4 or avi format, and replace line 8 of the code with "*.mp4" or "*.avi" as appropriate. The default mode is mp4. And run it the same way you would normally run MATLAB code.

### 3. standard workflow
In this tutorial, I will analyze the beating of a 3D cardiac organoid using brightfield imaging.
