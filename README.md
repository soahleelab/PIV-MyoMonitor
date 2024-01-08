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
![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/0002dcb5-a396-40b2-9a06-5e7d45f95b91)
PIV-MyoMonitor takes in a video with an mp4 or avi format and analyzes it. Convenience updates such as batch analysis are planned in the future, but they don't exist in the current version, so you'll need to sort the directories in a way that makes sense for the analysis before you start. But don't worry, it's not that complicated a request, just create an empty folder and move the video files you want to analyze into it and start analyzing them. If you have multiple videos, make sure they're stored in separate folders, and inside each folder you'll have the analysis results for each video. 
### 2. Start Analysis
![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/d122db2c-d102-4572-b322-05f2132a6e5c)

If you've made it this far, make sure the video you want to analyze is in mp4 or avi format, and replace line 8 of the code with "*.mp4" or "*.avi" as appropriate. The default mode is mp4. And run it the same way you would normally run MATLAB code.

### 3. standard workflow
In this tutorial, we'll be analyzing the Organoid_1 video sample, one of the videos pictured above, which is a brightfield recording of a three-dimensional heart organoid beating in a standard lab environment. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/03d923a2-9026-4df3-b55a-130650b8ae9f)

As you start running this code, you'll be prompted to select the folder where the video you want to analyze is stored. If you've followed the previous steps, you should have one video per folder. Here, select the folder where the video you want to analyze is stored.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/59f7176d-036f-4a46-b9da-d656f3f8b63e)

This feature is designed for efficient analysis when the video is too long, so please enter the appropriate section to analyze based on the total duration, number of frames, and framerate of the video. In this case, length of organoid_1.mp4 is about 4 seconds. So, I decided to analyze full video. We recommend choosing a video length that allows you to analyze at least three beats. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/e381400c-48b1-4ad4-b43a-35609807743a)

Next is an input for the stiffness of the organization you want to analyze (for this tutorial, it's an organoid). If you know it, type 'Y' and enter its value. But if you don't, that's okay. If you don't know, enter 'N' and we'll calculate it from the value we got experimentally while developing.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/0aae4752-bf3e-4c11-b29c-f0b098facb6d)

Since the analysis through our software is not direct, but rather imaging through video, we need information about scale. Similar to our videos obtained with standard lab equipment, there will typically be a scalebar in the lower right corner of the video. Using a program like ImageJ, measure its length (in pixels) and enter it as shown in the example photo. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/70db3706-6b8a-4029-994f-0c71461d6ecd)

Then, determine the length of the radius of the tissue to be used for the contraction force calculation using the interactive figure window and double-click the bar. Next, if you want to define the ROI, enter "Y" and set it through the window. Otherwise, enter "N". 

This is followed by an automatic analysis of the organoid contractility using the PIV algorithm. You will be able to see the visualization via vector arrow, heatmap through the figure window. At the same time, these visualizations will be saved in the folder where the video is stored. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/4a03e6fa-1b34-4984-9c10-5b93d403dca5)

When the analysis is complete, you'll see the same results as above and the prompt "Do it Again? Y/N:" If you enter "Y", you'll be returned to the window to enter the ROI again, giving you multiple opportunities to analyze it. If the contractility seen in the video is well reflected in the graph, enter "N" and move on to the next step.

The next step is to deal with noise, where you can view the graph and enter an appropriate threshold value to flatten the graph. This process is designed to be a loop, so iterate to find the right threshold. For example, I considered any peak below 1 to be noise, and entered 1 as the value for the threshold. Once you have a flattened graph, enter a value for the minimum peak prominence that allows you to select the peak of Contraction-Relaxation from the many peaks on the graph. In my case, I entered a value of 0.1. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/607c6d31-0347-42c9-935d-fcf6c1e74591)

Then, you will then be presented with a video that combines the beating video with a graph over time so that you can compare the peaks that have been selected as meaningful peaks while watching the video. The prompt will read "Enter the index of the peak that you want to delete, enter 0 if you dont need or 'r' to restore : " Please enter the index of the peak that you want to delete on the graph while watching the video. In the graph above, I determined that the first peak was not part of the contraction-relaxation cycle, so I entered 1 to remove it. As you can see, the index will be constantly updated during the removal process, so please proceed with caution. This process is also designed as a loop. When you're done, enter 0 to move on to the next step.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/37f821a4-aafd-429a-b965-feaf79d91b37)

After the above steps, only the peak for the Contraction-Relaxation Cycle is considered to be present and PIV-MyoMonitor will proceed to interpolate the data. This process makes it possible to get continuous data even if the video has a low framerate. Then, you can select the max peak of contraction and relaxation in the cycle and enter the index of the peak that will be used as the basis for calculating the BPM. Generally, there is one contraction peak and one relaxation peak per cycle. Make sure that the contraction peak is the first peak in the analysis, as we will analyze the odd numbered contractions and the even numbered relaxations.  
Then, enter the indices of the first and last peaks as the start and end indices at the prompt, and you should be able to see a graph like the following. 

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/f15e9f22-4e33-431d-92d0-2ce6036e8749)

The next step is to determine the start and end of the contraction/relaxation peak, and you'll be given a graph like this, which you can use as a guide to remove meaningless indices.

![image](https://github.com/soahleelab/PIV-MyoMonitor/assets/155861561/389ae1b2-d8c8-42ce-abc6-ace693776a0d)

As you can see in the graph above, the indices highlighted by the red circles are actually points that are not related to the contraction and relaxation peaks, so we need to enter them and remove them. Keep in mind that this removal process is also designed as a loop and the indices are updated. In the example above, after removing the 4th index, instead of entering 8, we would have to enter 7 to remove the index we want because it will be pulled up one space. 

If you're up to this point, you're done with user input. From the data you entered, PIV-Monitor will calculate and output the visualization and 22 parameters. Do not quit MATLAB or shut down your system during this process as there is a lot of math and image processing happening in MATLAB. 

# Contact
If you have any questions or requests, please email ghdus6520@gmail.com
