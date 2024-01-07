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
As you start running this code, you'll be prompted to select the folder where the video you want to analyze is stored. If you've followed the previous steps, you should have one video per folder. Here, select the folder where the video you want to analyze is stored.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/59f7176d-036f-4a46-b9da-d656f3f8b63e)

This feature is designed for efficient analysis when the video is too long, so please enter the appropriate section to analyze based on the total duration, number of frames, and framerate of the video.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/e381400c-48b1-4ad4-b43a-35609807743a)

Next is an input for the stiffness of the organization you want to analyze (for this tutorial, it's an organoid). If you know it, type 'Y' and enter its value. But if you don't, that's okay. If you don't know, enter 'N' and we'll calculate it from the value we got experimentally while developing.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/0aae4752-bf3e-4c11-b29c-f0b098facb6d)

Since the analysis through our software is not direct, but rather imaging through video, we need information about scale. Similar to our videos obtained with standard lab equipment, there will typically be a scalebar in the lower right corner of the video. Using a program like ImageJ, measure its length (in pixels) and enter it as shown in the example photo.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/70db3706-6b8a-4029-994f-0c71461d6ecd)

Then, determine the length of the radius of the tissue to be used for the contraction force calculation using the interactive figure window and double-click the bar. Next, if you want to define the ROI, enter "Y" and set it through the window. Otherwise, enter "N". 

This is followed by an automatic analysis of the organoid contractility using the PIV algorithm. You will be able to see the visualization via vector arrow, heatmap through the figure window. At the same time, these visualizations will be saved in the folder where the video is stored. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/4a03e6fa-1b34-4984-9c10-5b93d403dca5)

When the analysis is complete, you'll see the same results as above and the prompt "Do it Again? Y/N:" If you enter "Y", you'll be returned to the window to enter the ROI again, giving you multiple opportunities to analyze it. If the contractility seen in the video is well reflected in the graph, enter "N" and move on to the next step.
