%% Create list of movies inside specified directory
clc;
close all; 
clear;
mov.directory=uigetdir; %directory containing the video you want to analyze
cd(mov.directory)
% main folder
suffix='*.mp4'; %*.mp4 or *.avi
direc = dir([mov.directory,filesep,suffix]); filenames={};
[filenames{1:length(direc),1}] = deal(direc.name);
filenames = sortrows(filenames); %sort all image files
amount = length(filenames);

%% Change video to image sequence
% Read Videos
name = char(filenames(1));
obj = VideoReader(name);
FrameRate=obj.FrameRate;
fprintf('Total Playtime: %f\n', obj.duration);
fprintf('Total Frames: %f\n', obj.NumFrames);
fprintf('Framerate: %f\n', FrameRate);
prompt = "Enter the number of frame, you want to analyze : ";
frames = input(prompt);
%frames = 23; %obj.NumFrames;
frame = read(obj); 


%% Generate and export image sequence 
%img.directory = strcat(char(filenames(1)),'-frames');
mkdir frames;
cd frames; % frames
for x = 1 : frames
    %frame(:,:,1,x)=wiener2(frame(:,:,1,x), [30 30]);
    imwrite(frame(:,:,1,x),strcat('frame-',sprintf('%03d',x),'.tif'));
end

clc;
%% Check the number of image sequence
if mod(frames,2) == 1 %Uneven number of images?
    disp('Image folder should contain an even number of images.')
    %remove last image from list
    %frames=frames-1;
    delete(strcat('frame-',sprintf('%03d',frames),'.tif'));
end
disp(['Found ' num2str(frames) ' images (' num2str(frames-1) ' image pairs).'])

close all;
cd ..; % Move up to the parent directory containing all the movies


%% Standard PIV Settings
s = cell(15,2); % To make it more readable, let's create a "settings table"

%Parameter                       %Setting           %Options
s{1,1}= 'Int. area 1';           s{1,2}=32;         % window size of first pass (interrogation window)
s{2,1}= 'Step size 1';           s{2,2}=8;         % step of first pass (displacement or spacing btw consecutive interrogation windows)
s{3,1}= 'Subpix. finder';        s{3,2}=1;          % 1 = 3point Gauss, 2 = 2D Gauss
s{4,1}= 'Mask';                  s{4,2}=[];         % If needed, generate via: imagesc(image); [temp,Mask{1,1},Mask{1,2}]=roipoly;
s{5,1}= 'ROI';                   s{5,2}=[];         % Region of interest: [x,y,width,height] in pixels, may be left empty
s{6,1}= 'Nr. of passes';         s{6,2}=1;          % 1-4 nr. of passes
s{7,1}= 'Int. area 2';           s{7,2}=32;         % second pass window size
s{8,1}= 'Int. area 3';           s{8,2}=16;         % third pass window size
s{9,1}= 'Int. area 4';           s{9,2}=16;         % fourth pass window size
s{10,1}='Window deformation';    s{10,2}='*spline'; % '*linear' default setting; '*spline' is more accurate, but slower


%% Standard image preprocessing settings
p = cell(8,1);
%Parameter                       %Setting           %Options
p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
p{2,1}= 'CLAHE';                 p{2,2}=1;          % 1 = enable CLAHE (contrast enhancement), 0 = disable
p{3,1}= 'CLAHE size';            p{3,2}=50;         % CLAHE window size
p{4,1}= 'Highpass';              p{4,2}=0;          % 1 = enable highpass, 0 = disable
p{5,1}= 'Highpass size';         p{5,2}=15;         % highpass size
p{6,1}= 'Clipping';              p{6,2}=0;          % 1 = enable clipping, 0 = disable
p{7,1}= 'Wiener';                p{7,2}=1;          % 1 = enable Wiener2 adaptive denaoise filter, 0 = disable
p{8,1}= 'Wiener size';           p{8,2}=3;          % Wiener2 window size

%% Initialize variables for piv_FFTmulti
x=cell(frames-1,1);
y=x;
u=x;
v=x;
typevector=x; %typevector will be 1 for regular vectors, 0 for masked areas

% stiffness initialization
prompt = "Do you Know the stiffness of organoid? Y/N : ";
txt = input(prompt, "s");
if (txt == 'Y')
    prompt = "Enter the stiffness : ";
    stiffness = input(prompt);
else
    disp("assume stiffness as 200kPa")
    stiffness = 200000;
end

% px2um initialization
prompt = "Enter the known distance of scale bar: ";
known_distance = str2double(input(prompt, "s"));
prompt = "Enter the distance in pixels of scale bar: ";
distance_in_pixels = str2double(input(prompt, "s"));
px2um = known_distance/distance_in_pixels;

%radius initialization
imshow(frame(:,:,1,1));
hold on;
title("draw radius",'interpreter','none');
h = imdistline;
wait(h);
saveas(gcf, 'measured_radius.png', 'png');
R = getDistance(h);

%% PIV and Post processing
flag = 0;
while(1)
    %% PIV analysis loop:
    % If masking or ROI selection is needed
    imagesc(frame(:,:,1));
    hold on;
    title("set ROI",'interpreter','none');
    colormap gray; 
    axis image;
    
    % For Masking
    % [temp,Mask{1,1},Mask{1,2}]=roipoly;  
    % s{4,2}={Mask{1,1}, Mask{1,2}};
    
    % For ROI
    if (flag == 0)
        prompt = "Need ROI? Y/N : ";
        txt = input(prompt, "s");
        if (txt == 'Y')
            h=imrect;
            s{5,2}=getPosition(h);
        end
    else 
        prompt = "Change ROI? Y/N : ";
        txt = input(prompt, "s");
        if (txt == 'Y')
            h=imrect;
            s{5,2}=getPosition(h);
        end
    end

    % record ROI
    fROI = fopen('ROI.txt', 'w' );
    if (isempty(s{5,2}) == 1)
        fprintf(fROI, "No ROI\n");
    else
        fprintf( fROI, '%f %f %f %f\n', s{5,2}(1), s{5,2}(2), s{5,2}(3), s{5,2}(4));
    end
    fclose(fROI);
    tic
    %% Initial PIV
    mkdir PIV;
    %cd("PIV");
    counter=0;
    scaleFactor=1;
    image1=frame(:,:,1,1);
    se1 = strel('line',20,0);
    se2 = strel('line',20,90);
    %mask = bwareaopen(imcomplement(im2bw(imgaussfilt(im2gray(image1), 5))), 50000);
    mask = im2gray(image1);
    threshold = graythresh(mask);
    imgaussfilt(mask, 5);
    mask = im2bw(mask, threshold);
    mask = imcomplement(mask);
    mask = bwareaopen(mask, 5000);
    mask = imdilate(mask, [se1 se2], 'full');
    mask(1:10,:) = [];
    mask(905:914,:) = [];
    mask(:,1:10) = [];
    mask(:,1225:1234) = [];
    mask = im2uint8(imcomplement(mask));
    imagesc(mask+image1);
    colormap gray;
    axis image;
    saveas(gcf,'edge detection.tif');
    cd("PIV");
    

    
    for i = 1 : 1 : frames-1
        counter=counter+1;
        image1=frame(:,:,1,i);
        image2=frame(:,:,1,i+1);
        proc_image1 = mask + image1;
        proc_image2 = mask + image2;
        %proc_image1 = image1;
        %proc_image2 = image2;
        [x{counter},y{counter},u{counter},v{counter},typevector{counter}] = piv_FFTmulti (proc_image1,proc_image2,s{1,2},s{2,2},s{3,2},s{4,2},s{5,2},s{6,2},s{7,2},s{8,2},s{9,2},s{10,2});
        
        clc
        disp([int2str((i+1)/frames*100) ' %']);
        
        % vector size
        vecSize{i}=sqrt(u{i}.^2+v{i}.^2);
        vecSum(i) = sum(vecSize{i}(:),'omitnan');

        imagesc(image1);
        hold on
        quiver(x{counter},y{counter},u{counter}*scaleFactor,v{counter}*scaleFactor,'g','AutoScale','off');
        hold off;
        axis image;
        title(strcat("Frame ",sprintf('%d',i)),'interpreter','none')
        set(gca,'xtick',[],'ytick',[])
        drawnow;
        saveas(gcf,strcat('PIV-',sprintf('%03d',i),'.tiff'));
    end
    clc;
    disp("PIV done");
    cd ..;

    % current direc = main folder;
    
    
    %% PIV postprocessing setting
    % uDelmin = 0; % minimum allowed u velocity, adjust to your data
    % uDelmax = 0.03; % maximum allowed u velocity, adjust to your data
    % vDelmin = 0; % minimum allowed v velocity, adjust to your data
    % vDelmax = 0.03; % maximum allowed v velocity, adjust to your data
    % 
    % umin = 0; % minimum allowed u velocity, adjust to your data
    % umax = 0.03; % maximum allowed u velocity, adjust to your data
    % vmin = 0; % minimum allowed v velocity, adjust to your data
    % vmax = 0.03; % maximum allowed v velocity, adjust to your data
    
    stdthresh=8; % threshold for standard deviation check
    epsilon=0.15; % epsilon for normalized median test
    thresh=2; % threshold for normalized median test
    
    %% PIV postprocessing
    u_filt=cell(frames-1,1);
    v_filt=u_filt;
    typevector_filt=u_filt;
    u{size(x,1)+1} = u{size(x,1)};
    v{size(x,1)+1} = v{size(x,1)};
    
    for PIVresult=1:size(x,1)
        disp(PIVresult);
        u_filtered{PIVresult} = u{PIVresult, 1};
        v_filtered{PIVresult} = v{PIVresult, 1};
        typevector_filtered = typevector{PIVresult,1};
    
        % stddev check
        meanu=mean(mean(u_filtered{PIVresult}, "omitnan"), "omitnan");
        meanv=mean(mean(v_filtered{PIVresult}, "omitnan"), "omitnan");
        std2u=std(reshape(u_filtered{PIVresult},size(u_filtered{PIVresult},1)*size(u_filtered{PIVresult},2),1), "omitnan");
        std2v=std(reshape(v_filtered{PIVresult},size(v_filtered{PIVresult},1)*size(v_filtered{PIVresult},2),1), "omitnan");
        minvalu=meanu-stdthresh*std2u;
        maxvalu=meanu+stdthresh*std2u;
        minvalv=meanv-stdthresh*std2v;
        maxvalv=meanv+stdthresh*std2v;
        u_filtered{PIVresult}(u_filtered{PIVresult}<minvalu)=NaN;
        u_filtered{PIVresult}(u_filtered{PIVresult}>maxvalu)=NaN;
        v_filtered{PIVresult}(v_filtered{PIVresult}<minvalv)=NaN;
        v_filtered{PIVresult}(v_filtered{PIVresult}>maxvalv)=NaN;
    
        % normalized median check
        % Westerweel & Scarano (2005): Universal Outlier detection for PIV data
        [J,I]=size(u_filtered);
        medianres=zeros(J,I);
        normfluct=zeros(J,I,2);
        b=1;
        for c=1:2
            if c==1; velcomp=u_filtered;else;velcomp=v_filtered;end %#ok<*NOSEM>
            for i=1+b:I-b
                for j=1+b:J-b
                    neigh=velcomp(j-b:j+b,i-b:i+b);
                    neighcol=neigh(:);
                    neighcol2=[neighcol(1:(2*b+1)*b+b);neighcol((2*b+1)*b+b+2:end)];
                    med=median(neighcol2);
                    fluct=velcomp(j,i)-med;
                    res=neighcol2-med;
                    medianres=median(abs(res));
                    normfluct(j,i,c)=abs(fluct/(medianres+epsilon));
                end
            end
        end
        info1=(sqrt(normfluct(:,:,1).^2+normfluct(:,:,2).^2)>thresh);
        u_filtered{PIVresult}(info1==1)=NaN;
        v_filtered{PIVresult}(info1==1)=NaN;
    
        typevector_filtered(isnan(u_filtered{PIVresult}))=2;
        typevector_filtered(isnan(v_filtered{PIVresult}))=2;
        typevector_filtered(typevector{PIVresult,1}==0)=0; %restores typevector for mask
        
        %Interpolate missing data 
        % these lines makes junk data for unmasked area
        %u_filtered{PIVresult}=inpaint_nans(u_filtered{PIVresult},4);
        %v_filtered{PIVresult}=inpaint_nans(v_filtered{PIVresult},4);
        
        u_filt{PIVresult,1}=u_filtered{PIVresult};
        v_filt{PIVresult,1}=v_filtered{PIVresult};
        typevector_filt{PIVresult,1}=typevector_filtered;
    end

    %% processed vector to scalar
    for i=1:1:frames-1
        % Post-processed vector size
        vecSize_filtered{i}=sqrt(u_filtered{i}.^2+v_filtered{i}.^2);
        vecSum_filtered(i)=sum(vecSize_filtered{i}(:),'omitnan');
    end    
    %% vector to avg velocity
    [maxVecSumValue,maxFrameIndex]=max(vecSum_filtered);
    
    % maxFrame=maxFrameIndex*2-1;
    [maxVec,maxVecPosRow]=max(vecSize{maxFrameIndex});
    [maxMaxVec,maxVecPosCol]=max(max(vecSize{maxFrameIndex}));
    
    for i=1:1:frames-1
        vel(i)=vecSum_filtered(i)/sum(sum(~isnan(vecSize_filtered{1,1})));
    end

    %% Post-processing Verification
    close all
    mkdir Processed_PIV;
    % back to main folder
    counter=0;
    scaleFactor=1;
    % Video Generation
    vW=VideoWriter('PIV-processed','MPEG-4');
    FrameRate=obj.FrameRate;
    F=1;
    vW.FrameRate=FrameRate/F;
    open(vW);
    cd Processed_PIV;
    for i=1:1:frames-1
        counter=counter+1;
        image1=frame(:,:,1,i);
        proc_image1 = mask + image1;
        %proc_image1 = image1;
        clc
        disp([int2str((i+1)/frames*100) ' %']);
        % vector image
        imagesc(image1);
        colormap('gray');
        hold on
        quiver(x{counter},y{counter},u_filtered{counter}*scaleFactor,v_filtered{counter}*scaleFactor,'g','AutoScale', 'off');
        hold off;
        axis image;
        title(strcat("Frame ",sprintf('%d',i)),'interpreter','none')
        set(gca,'xtick',[],'ytick',[])
        drawnow;
        saveas(gcf,strcat('processed-',sprintf('%03d',i),'.tif'));
        writeVideo(vW,getframe(gcf));
    end
    close(vW)
    clc;
    cd ..;
    % current direc = main folder;
    disp('Post Processing DONE.')

    defVector = cellfun(@(x) x*px2um*FrameRate, vecSize_filtered, 'UniformOutput', false);

    mkdir Processed_heatmap;
    maxValue = -inf;
    for i = 1:numel(defVector)
        currentMax = max(defVector{i}(:));
        if currentMax > maxValue
            maxValue = currentMax;
        end
    end

    vW=VideoWriter(strcat('heatmap_processed'),'MPEG-4');
    % FrameRate=10; 
    F=1;
    scaleFactor=1;
    vW.FrameRate=FrameRate/F;
    % current direc = main folder;
    open(vW);
    cd Processed_heatmap;
    for i = 1 : 1 : frames-1
        imagesc(defVector{i});
        colormap turbo;
        clc
        disp([int2str((i+1)/frames*100) ' %']);
        clim([0, maxValue]);
        colorbar;
        axis image;
        title(strcat("Frame ",sprintf('%d',i)),'interpreter','none')
        set(gca,'xtick',[],'ytick',[])
        drawnow;
        saveas(gcf,strcat('heatmap_processed-',sprintf('%03d',i),'.tiff'));
        writeVideo(vW,getframe(gcf));
    end
    cd ..;
    disp("heatmap DONE")
    % current direc = main folder;
    close(vW);

 
    %% force, frame to time calculation
    d0 = px2um * R;             % Diameter of the organoid [um]
    defVel=vel*px2um*FrameRate; %[um/s]= vel[px/frame] x [um/px] x  [frame/s]
    defDis=defVel/FrameRate;    %[um] = defVel [um/s] x interval [s/frame] = FrameRate inverse
    strain=defDis/(d0/2);       % strain = (delta displacement / radius of organoid)
    stress = strain * stiffness; %[Pa] assume stiffness=100Pa ;
    A = pi * (d0/2)^2;    
    force=stress*A/(10^6); %[μN]
    tmax=(size(vel,2)-1)/FrameRate;
    time=0:1/FrameRate:tmax;

    %% raw defVel graph 
    % current direc = main folder;
    plot(time,defVel); %[um/s]
    hold on;
    title("Raw Contraction-Relaxation Velocity",'interpreter','none');
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(defVel)]); % must adjust to all of graphs below
    grid on;
    grid minor;
    h=getframe(gcf);
    imwrite(h.cdata,char(strcat('Raw Contraction-Relaxation Velocity.tiff')));
    elapsed_time = toc;
    clc;
    prompt = "Do it Again? Y/N : ";
    txt = input(prompt, "s");
    if (txt == 'N' || txt == 'n')
        break;
    end
    flag = 1;
end

%cd(img.directory);
% current direc = main folder;
nflag = 0;
while(1)
    close;
    temp_defVel = defVel;
    plot(time,temp_defVel);
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none')
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(temp_defVel)]); % must adjust to all of graphs below
    grid on;
    grid minor;
    hold off;
    if (nflag == 0)
        prompt = "Enter noise filter threshold : ";
        nft_val = input(prompt);
        close;
    else
        prompt = "Enter new noise filter threshold : ";
        nft_val = input(prompt);
        close;
    end
    temp_defVel(temp_defVel <= nft_val) = 0;
    plot(time,temp_defVel);
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none');
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(temp_defVel)]); % must adjust to all of graphs below
    grid on;
    grid minor;
    hold off;
    nflag = 1;
    prompt = "Do it Again? Y/N : ";
    txt = input(prompt, "s");
    if (txt == 'N' || txt == 'n')
        defVel = temp_defVel;
        close;
        break;
    end
end

pflag = 0;
while(1)
    plot(time,defVel);
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none');
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(defVel)]); % must adjust to all of graphs below
    grid on;
    grid minor;
    hold off;

    % peak setting
    if (pflag == 0)
        prompt = "Enter MinPeakProminence : ";
        mpp_val = input(prompt);
        close;
    else
        prompt = "Enter new MinPeakProminence : ";
        mpp_val = input(prompt);
        close;
    end

    % peak detection
    [forcePks,forcePksLocs] = findpeaks(defVel,'MinPeakProminence',mpp_val);
    forcePksTime = time(forcePksLocs)';
    pflag = 1;

    plot(time,defVel);
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none');
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(defVel)]); % must adjust to all of graphs below
    grid on;
    grid minor;
    text(forcePksTime, forcePks, num2str((1:numel(forcePks))'));
    hold off;

    prompt = "Do it Again? Y/N : ";
    txt = input(prompt, "s");
    if (txt == 'N' || txt == 'n')
        break;
    end
end
close;

% combine video creation for peak data deletion
% current direc = main folder;
mkdir rawPeaks;
cd rawPeaks;
for i=1:1:length(defVel)
    plot(time,defVel,'k',LineWidth=1.0);
    hold on
    xlim([min(time), max(time)]);
    ylim([min(defVel), max(defVel)]);
    text(forcePksTime, forcePks, num2str((1:numel(forcePks))'));
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none');
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(defVel)]); % must adjust to all of graphs below
    x_value = time(i);
    y_range = ylim();
    plot([x_value, x_value], y_range, 'g', LineWidth=1.0);
    grid on;
    grid minor;
    hold off;
    set(gca,'xtick',[],'ytick',[])
    saveas(gcf, strcat('graph-',sprintf('%03d',i),'.tif'))
end
cd ..;
% current direc = main folder;
vW=VideoWriter(strcat('rawCombine'),'MPEG-4');
F=1;
scaleFactor=1;
vW.FrameRate=FrameRate/F;
open(vW);
mkdir rawCombine;
cd rawCombine;
for i=1:1:length(defVel)
     out1 = imtile({strcat('..\rawPeaks\graph-',sprintf('%03d',i),'.tif'), strcat('..\frames','\frame-',sprintf('%03d',i),'.tif')});
     imshow(out1);
     saveas(gcf,strcat('combine-',sprintf('%03d',i),'.tif'))
end

% video process
for i=1:1:length(defVel)
    imshow(strcat('combine-',sprintf('%03d',i),'.tif'),'Border','tight');
    frames = getframe(gcf);
    writeVideo(vW, frames);
end
close(vW);
cd ..;
close;
% current direc = main folder;

% display video for choose
implay("rawCombine.mp4");


%% denoise redundant peak data delete
rflag = 0;
while(1)
    [everyPks,everyPksLocs] = findpeaks(defVel);
    everyPksTime = time(everyPksLocs)';
    plot(time,defVel);
    hold on;
    title("Raw Contraction-Relaxation Velocity",'interpreter','none');
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(defVel)]);
    grid on;
    grid minor;
    plot(forcePksTime, forcePks, 'o');
    text(everyPksTime, everyPks, num2str((1:numel(everyPks))'));
    hold off;

    prompt = "Enter the index of the peak that you want to delete, enter 0 if you dont need or 'r' to restore : ";
    rp_idx = input(prompt, 's');
    if strcmp(rp_idx, 'r')
        defVel = temp_defVel;
        time = temp_time;
        forcePks = temp_forcePks;
        forcePksLocs = temp_forcePksLocs;
        forcePksTime = temp_forcePksTime;
    elseif str2double(rp_idx) == 0
        break;
    else
        rp_idx = str2double(rp_idx);
        temp_defVel = defVel;
        temp_time = time;
        temp_forcePks = forcePks;
        temp_forcePksLocs = forcePksLocs;
        temp_forcePksTime = forcePksTime;
        checker = find(forcePksLocs == everyPksLocs(rp_idx));
        if isempty(checker)
            defVel(everyPksLocs(rp_idx)) = 0;
        else
            defVel(everyPksLocs(rp_idx)) = 0;
            forcePks(checker) = [];
            forcePksLocs(checker) = [];
            forcePksTime = time(forcePksLocs)';
        end
    end
end

%% interpolation
intdefVel = interp1(1:length(defVel), defVel, 1:0.1:length(defVel), 'pchip');
inttime = interp1(1:length(time), time, 1:0.1:length(time), 'pchip');

%% plot save
[forcePks,forcePksLocs]=findpeaks(defVel,'MinPeakProminence',mpp_val);
forcePksTime=time(forcePksLocs)';
plot(time,defVel);
hold on
plot(forcePksTime,forcePks,'o');
title("Contraction-Relaxation Velocity",'interpreter','none')
xlabel('time(sec)');
ylabel('μm/s');
axis([0 max(time) 0 max(defVel)]);
grid on;
grid minor;
hold off
h=getframe(gcf);
imwrite(h.cdata,char(strcat('Contraction-Relaxation Velocity.tiff')));

close
plot(time, force);
hold on;
title("Contraction-Relaxation Force", 'Interpreter','none')
xlabel('time(sec)');
ylabel('μN');
grid on;
grid minor;
hold off;
axis([0 max(time) 0 max(force)]);
h=getframe(gcf);
imwrite(h.cdata,char(strcat('Contraction-Relaxation Force.tiff')));
close;
clc;
%% peak deselection
while(1)
    plot(inttime,intdefVel)
    %plot(time, defVel);
    forcePksTime = time(forcePksLocs)';
    text(forcePksTime, forcePks, num2str((1:numel(forcePks))'))
    title("Contraction-Relaxation Velocity",'interpreter','none')
    xlabel('time(sec)');
    ylabel('μm/s');
    grid on;
    grid minor;
    axis([0 max(time) 0 max(defVel)]);
    
    prompt = "Enter the index of the peak that you do not want to analyze with peak, enter 0 if you dont need or 'r' to restore : ";
    Deletion = input(prompt, 's');
    if strcmp(Deletion, 'r')
        forcePks = temp_forcePks;
        forcePksLocs = temp_forcePksLocs;
    elseif str2double(Deletion) == 0
        break;
    else
        Deletion = str2double(Deletion);
        temp_forcePks = forcePks;
        temp_forcePksLocs = forcePksLocs;
        forcePksLocs(Deletion) = NaN;
        forcePksLocs = rmmissing(forcePksLocs);
        forcePks(Deletion) = NaN;
        forcePks = rmmissing(forcePks);
        close;
    end
end


%% Define the indice for analysis
while(1)
    forcePksTime = time(forcePksLocs)';
    prompt = "Start Index : ";
    Start = input(prompt);
    prompt = "End Index : ";
    End = input(prompt);

    plot(inttime, intdefVel);
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none')
    xlabel('time(sec)');
    ylabel('μm/s');
    grid on;
    grid minor;
    axis([0 max(inttime) 0 max(intdefVel)]);

    for i = 1:length(forcePksTime)
        if mod(i, 2) == 1
            plot(forcePksTime(i),forcePks(i),'o','MarkerEdgeColor','red');
        else
            plot(forcePksTime(i),forcePks(i),'o','MarkerEdgeColor','green');
        end
    end

    plot(forcePksTime(Start),forcePks(Start),"pentagram");
    plot(forcePksTime(End),forcePks(End),"pentagram");
    text(forcePksTime(Start),forcePks(Start), 'First');
    text(forcePksTime(End),forcePks(End), 'Last');

    prompt = "Do it Again? Y/N : ";
    txt = input(prompt, "s");
    if (txt == 'N' || txt == 'n')
        break;
    end
end;

forcePksTime = forcePksTime(Start:End);
forcePks = forcePks(Start:End);
forcePksLocs = forcePksLocs(Start:End);
%% Determine Starting and End Points
% zero to nonzero
idx1 = find(defVel(1:end-1) == 0 & defVel(2:end) ~= 0);
% nonzero to zero
idx2 = find(defVel(1:end-1) ~= 0 & defVel(2:end) == 0);
% denoise external peak
defVel(1:idx1(1)-1) = 0;
defVel(idx2(end)+1:end) = 0;
% zero to nonzero : denoised
idx1 = find(defVel(1:end-1) == 0 & defVel(2:end) ~= 0);
% nonzero to zero : denoised
idx2 = find(defVel(1:end-1) ~= 0 & defVel(2:end) == 0);

% interpolation
intdefVel = interp1(1:length(defVel), defVel, 1:0.1:length(defVel), 'pchip');
inttime = interp1(1:length(time), time, 1:0.1:length(time), 'pchip');

% Calculate the first derivative (slope) of intdefVel with respect to inttime
d_intdefVel = diff(intdefVel) ./ diff(inttime);
d_intdefVel = [0 d_intdefVel];

% Find the indices where d_intdefVel changes from 0 to a non-zero value
zero_to_nonzero_indices = find(d_intdefVel(1:end-1) == 0 & d_intdefVel(2:end) ~= 0);

% Find the indices where d_intdefVel changes from non-zero to 0 value
nonzero_to_zero_indices = find(d_intdefVel(1:end-1) ~= 0 & d_intdefVel(2:end) == 0);
nonzero_to_zero_indices = nonzero_to_zero_indices + 1; % Add 1 to get the correct positions

% Find the indices of local minima in intdefVel data
local_minima_indices = find(islocalmin(intdefVel));

% Merge all sets of indices and remove any duplicates
all_indices = unique([zero_to_nonzero_indices, local_minima_indices, nonzero_to_zero_indices]);

% Plot the original intdefVel data as a dotted line
plot(inttime, intdefVel);
hold on;
title("Contraction-Relaxation Velocity",'interpreter','none')
xlabel('time(sec)');
ylabel('μm/s');
grid on;
grid minor;
axis([0 max(inttime) 0 max(intdefVel)]);
% Mark points where slope changes from 0 to non-zero or local minima or from non-zero to 0 with green triangles up
plot(inttime(all_indices), intdefVel(all_indices), 'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 6);

% Use the 'text' function to label the markers with their corresponding order in all_indices
for i = 1:length(all_indices)
    index = all_indices(i);
    text(inttime(index), intdefVel(index), num2str(i), 'FontSize', 8, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

hold off;

%xlabel('Time (sec)');
%ylabel('Velocity (μm/s)');
%title('Velocity');
grid on;
close;

%% select start-end point
while(1)
    % Plot the original intdefVel data as a dotted line
    plot(inttime, intdefVel);
    hold on;
    title("Contraction-Relaxation Velocity",'interpreter','none')
    xlabel('time(sec)');
    ylabel('μm/s');
    grid on;
    grid minor;
    axis([0 max(time) 0 max(defVel)]);
    % Mark points where slope changes from 0 to non-zero or local minima or from non-zero to 0 with green triangles up
    plot(inttime(all_indices), intdefVel(all_indices), 'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
    
    % Use the 'text' function to label the markers with their corresponding order in all_indices
    for i = 1:length(all_indices)
        index = all_indices(i);
        text(inttime(index), intdefVel(index), num2str(i), 'FontSize', 8, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
    end
    
    for i = 1:length(forcePksTime)
        if mod(i, 2) == 1
            plot(forcePksTime(i),forcePks(i),'o','MarkerEdgeColor','red');
        else
            plot(forcePksTime(i),forcePks(i),'o','MarkerEdgeColor','green');
        end
    end

    hold off;
    
    grid on;
    
    % delete point
    prompt = "Delete Index? enter 0 if you dont need or 'r' to restore : ";
    Deletion = input(prompt, 's');
    if strcmp(Deletion, 'r')
        all_indices = temp_all_indices;
    elseif str2double(Deletion) == 0
        break;
    else
        Deletion = str2double(Deletion);
        temp_all_indices = all_indices;
        all_indices(Deletion) = NaN;
        all_indices = rmmissing(all_indices);
        close;
    end;
end

%% Deformation Distance Calculation
% Initialize arrays to store the integrated data
integral_val = [];
itv_idx = 1;

% initialize arrays to store start-end point 
start_dp = [];
end_dp = [];

% Integrate the data in intervals defined by all_indices
for i = 1:length(all_indices) - 1
    start_index = all_indices(i);
    end_index = all_indices(i + 1);
    integral_val(itv_idx) = trapz(inttime(start_index:end_index), intdefVel(start_index:end_index));
    start_dp(itv_idx) = start_index;
    end_dp(itv_idx) = end_index;
    itv_idx = itv_idx + 1;
end

% Remove zeros from integral_val and start_end data point array
blank_indices = find(integral_val == 0);
start_dp(blank_indices) = [];
end_dp(blank_indices) = [];
integral_val = integral_val(integral_val ~= 0);

% contraction
contract_integ = integral_val(1:2:end);

% relaxation
relax_integ = integral_val(2:2:end);

% Plot & Save the FINAL avg velocity graph (smoothing, denoise) 
plot(inttime,intdefVel,'black');
hold on
%text(forcePksTime, forcePks, num2str((1:numel(forcePks))'));
plot(inttime(all_indices), intdefVel(all_indices), 'o', 'MarkerEdgeColor', 'blue');
for i = 1:length(forcePksTime)
    if mod(i, 2) == 1
        plot(forcePksTime(i),forcePks(i),'o','MarkerEdgeColor','red');
    else
        plot(forcePksTime(i),forcePks(i),'o','MarkerEdgeColor','green');
    end
end
title("Contraction-Relaxation Velocity",'interpreter','none')
xlabel('time(sec)');
ylabel('μm/s');
axis([0 max(inttime) 0 max(intdefVel)]);
grid on;
grid minor;
hold off
h=getframe(gcf);
imwrite(h.cdata,char(strcat('Smoothed Refined Contraction-Relaxation Velocity.tiff')));

if 1 < 0
% refined plot save
    plot(time,defVel,'black');
    hold on
    %text(forcePksTime, forcePks, num2str((1:numel(forcePks))'));
    title("Contraction-Relaxation Velocity",'interpreter','none')
    xlabel('time(sec)');
    ylabel('μm/s');
    axis([0 max(time) 0 max(defVel)]);
    grid on;
    grid minor;
    hold off
    h=getframe(gcf);
    imwrite(h.cdata,char(strcat('Refined Contraction-Relaxation Velocity.tiff')));
end


%refined smoothed force
intdefDis=intdefVel/FrameRate; 
intstrain=intdefDis/d0;
intstress = intstrain * stiffness;
intforce=intstress*A/(10^6); %[pN]
cal_force_Pks = forcePks/FrameRate/d0*stiffness*A/(10^6);
plot(inttime, intforce);
hold on
plot(inttime(all_indices), intforce(all_indices), 'o', 'MarkerEdgeColor', 'blue');
for i = 1:length(forcePksTime)
    if mod(i, 2) == 1
        plot(forcePksTime(i),cal_force_Pks(i),'o','MarkerEdgeColor','red');
    else
        plot(forcePksTime(i),cal_force_Pks(i),'o','MarkerEdgeColor','green');
    end
end
title("Contraction Force", 'Interpreter','none')
xlabel('time(sec)');
ylabel('μN');
grid on;
grid minor;
axis([0 max(inttime) 0 max(intforce)]);
hold off;
h=getframe(gcf);
imwrite(h.cdata,char(strcat('Smoothed Contraction Force.tiff')));

%% Final Video Creation
mkdir Final_Video;
cd Final_Video;
for i=1:1:length(defVel)
    plot(time,defVel,'LineStyle',':');
    hold on
    plot(inttime, intdefVel);
    title("Contraction-Relaxation Velocity",'interpreter','none')
    xlabel('time(sec)');
    ylabel('μm/s');
    xlim([min(inttime), max(inttime)]);
    ylim([min(intdefVel), max(intdefVel)]);
    text(forcePksTime, forcePks, num2str((1:numel(forcePks))'))
    hold on;
    plot(inttime(all_indices), intdefVel(all_indices), 'o', 'MarkerEdgeColor', 'blue');
    for j = 1:length(forcePksTime)
        if mod(j, 2) == 1
            plot(forcePksTime(j),forcePks(j),'o','MarkerEdgeColor','red');
        else
            plot(forcePksTime(j),forcePks(j),'o','MarkerEdgeColor','green');
        end
    end
    grid on;
    grid minor;
    x_value = time(i);
    y_range = ylim();
    plot([x_value, x_value], y_range, 'g');
    hold off;
    set(gca,'xtick',[],'ytick',[])
    saveas(gcf, strcat('final_graph-',sprintf('%03d',i),'.tif'))
end

% combine process
for i=1:1:length(defVel)
     out1 = imtile({strcat('..\Final_Video\final_graph-',sprintf('%03d',i),'.tif'), strcat('..\frames','\frame-',sprintf('%03d',i),'.tif')});
     imshow(out1);
     saveas(gcf,strcat('combined_final-',sprintf('%03d',i),'.tif'))
end

%% video process
myVideo = VideoWriter('combined final', 'MPEG-4');
myVideo.FrameRate = FrameRate/F;
cd ..;
open(myVideo)
cd Final_Video;
for i=1:1:length(defVel)
    imshow(strcat('combined_final-',sprintf('%03d',i),'.tif'),'Border','tight');
    frames = getframe(gcf);
    writeVideo(myVideo, frames);
end
disp("done");
close;
close(myVideo);
movefile("combined final.mp4", "..");
cd ..;

%% Beating Rate
BPMsize=size(forcePksTime,1)-2;
for i=1:1:BPMsize
BPM(i)=60/(forcePksTime(i+2)-forcePksTime(i));
end
BPM=BPM';
BPM(BPMsize+1:BPMsize+2,1)=[0;0];

% Find Contraction Peak
conPksCount=0;
relPksCount=0;

for i=1:2:size(forcePksTime,1)-1
    if (forcePksTime(3)-forcePksTime(2))>(forcePksTime(2)-forcePksTime(1))
        % the first peak is contraction peak
        conPksCount=conPksCount+1;
        conPks(conPksCount)=forcePks(i);
        conPksTime(conPksCount)=forcePksTime(i);
    
        % the second peak is relaxation peak
        relPksCount=relPksCount+1;
        relPks(relPksCount)=forcePks(i+1);
        relPksTime(relPksCount)=forcePksTime(i+1);
       
    else
        % the first peak is relaxation peak
        relPksCount=relPksCount+1;
        relPks(relPksCount)=forcePks(i);
        relPksTime(relPksCount)=forcePksTime(i);
    
        % the second peak is relaxation peak
        conPksCount=conPksCount+1;
        conPks(conPksCount)=forcePks(i+1);
        conPksTime(conPksCount)=forcePksTime(i+1);
        
    end
end

% BPM Calculation
for i=1:1:size(conPksTime,2)-1
    conPksTimeDif(i,1)=conPksTime(i+1)-conPksTime(i);
end

for i=1:1:size(relPksTime,2)-1
    relPksTimeDif(i,1)=relPksTime(i+1)-relPksTime(i);
end

conPksTimeDif(size(conPksTime,2),1)=0;
relPksTimeDif(size(relPksTime,2),1)=0;

BPM_con=60./conPksTimeDif;
BPM_rel=60./relPksTimeDif;

for i = 1:1:size(BPM_rel)
    if BPM_rel(i) == inf
        BPM_rel(i) = NaN;
    end
end
for i = 1:1:size(BPM_con)
    if BPM_con(i) == inf
        BPM_con(i) = NaN;
    end
end

%% time to decay calculation

zero_dp = find(intdefVel == 0);
%decay_point = [0.9, 0.5, 0.1];
T10_dp = zeros(1, numel(relPks));
T50_dp = zeros(1, numel(relPks));
T90_dp = zeros(1, numel(relPks));
T10 = zeros(1, numel(relPks));
T50 = zeros(1, numel(relPks));
T90 = zeros(1, numel(relPks));
for i=1:1:numel(relPks)
    relPksdp = find(intdefVel == relPks(i));
    reltozerodp = min(zero_dp(zero_dp > relPksdp));
    inttime_subset = inttime(relPksdp:reltozerodp);
    intdefVel_subset = intdefVel(relPksdp:reltozerodp);
    % 90% time to decay
    target_value = intdefVel(relPksdp) * 0.9;
    end_interval_idx = find(intdefVel_subset <= target_value, 1, 'first');
    start_interval_idx = end_interval_idx - 1;
    % linear approximation
    x1 = inttime_subset(start_interval_idx);
    y1 = intdefVel_subset(start_interval_idx);
    x2 = inttime_subset(end_interval_idx);
    y2 = intdefVel_subset(end_interval_idx);
    slope = (y2 - y1) / (x2 - x1);
    y_intercept = y1 - slope * x1;
    target_time = (target_value - y_intercept) / slope;
    T90_dp(i) = target_time;
    T90(i) = target_time - inttime(relPksdp);

    % 50% time to decay
    target_value = intdefVel(relPksdp) * 0.5;
    end_interval_idx = find(intdefVel_subset <= target_value, 1, 'first');
    start_interval_idx = end_interval_idx - 1;
    % linear approximation
    x1 = inttime_subset(start_interval_idx);
    y1 = intdefVel_subset(start_interval_idx);
    x2 = inttime_subset(end_interval_idx);
    y2 = intdefVel_subset(end_interval_idx);
    slope = (y2 - y1) / (x2 - x1);
    y_intercept = y1 - slope * x1;
    target_time = (target_value - y_intercept) / slope;
    T50_dp(i) = target_time;
    T50(i) = target_time - inttime(relPksdp);

    % 10% time to decay
    target_value = intdefVel(relPksdp) * 0.1;
    end_interval_idx = find(intdefVel_subset <= target_value, 1, 'first');
    start_interval_idx = end_interval_idx - 1;
    % linear approximation
    x1 = inttime_subset(start_interval_idx);
    y1 = intdefVel_subset(start_interval_idx);
    x2 = inttime_subset(end_interval_idx);
    y2 = intdefVel_subset(end_interval_idx);
    slope = (y2 - y1) / (x2 - x1);
    y_intercept = y1 - slope * x1;
    target_time = (target_value - y_intercept) / slope;
    T10_dp(i) = target_time;
    T10(i) = target_time - inttime(relPksdp);
end

%% Index array generation
Peak_Index = 1:numel(conPks);
Peak_Index = Peak_Index';

%% Start-End time & Peak time array generation
Contraction_Start_Time = inttime(start_dp(1:2:end))';
Contraction_End_Time = inttime(end_dp(1:2:end))';
Contraction_Peak_Time = conPksTime';
Relaxation_Start_Time = inttime(start_dp(2:2:end))';
Relaxation_End_Time = inttime(end_dp(2:2:end))';
Relaxation_Peak_Time = relPksTime';

%% Time to Decay array generation
Time_to_Decay_10 = T10';
Time_to_Decay_50 = T50';
Time_to_Decay_90 = T90';

%% Time byproduct generation
Contraction_Time_to_Peak = Contraction_End_Time - Contraction_Peak_Time;
Relaxation_Time_to_Peak = Relaxation_End_Time - Relaxation_Peak_Time;
Contraction_Duration = Contraction_End_Time - Contraction_Start_Time;
Relaxation_Duration = Relaxation_End_Time - Relaxation_Start_Time;
Contraction_to_Relaxation_Time = Relaxation_Peak_Time - Contraction_Peak_Time;

%% BPM array generation
BPM_Contraction = BPM_con;
BPM_Relaxation = BPM_rel;

%% deformation velocity byproduct array generation
AVG_Contraction_Velocity = conPks';
AVG_Relaxation_Velocity = relPks';
AVG_Contraction_Force = cal_force_Pks(1:2:end)';
AVG_Relaxation_Force = cal_force_Pks(2:2:end)';
Contraction_Deformation_Distance = contract_integ';
Relaxation_Deformation_Distance = relax_integ';

%% Make a Summary Table
T1 = table(Peak_Index, Contraction_Start_Time, Contraction_Peak_Time, Contraction_End_Time, Contraction_Time_to_Peak, AVG_Contraction_Velocity, BPM_Contraction, Contraction_Duration, Contraction_Deformation_Distance, AVG_Contraction_Force, ...
    Relaxation_Start_Time, Relaxation_Peak_Time, Relaxation_End_Time, Relaxation_Time_to_Peak, AVG_Relaxation_Velocity, BPM_Relaxation, Relaxation_Duration, Relaxation_Deformation_Distance, AVG_Relaxation_Force, Contraction_to_Relaxation_Time, Time_to_Decay_10, Time_to_Decay_50, Time_to_Decay_90 ...
    , 'VariableNames', {'Peak Index', 'Contraction Start time(s)', 'Contraction Peak Time(s)', 'Contraction End Time(s)', 'Contraciton Time to Peak(s)', 'AVG Contraction Velocity(μm/s)', 'BPM(Contraction)', 'Contraction Duration(s)', 'Contraction Deformation Distance(μm)', 'AVG Contraction Force(μN)' ...
    , 'Relaxation Start time(s)', 'Relaxation Peak Time(s)', 'Relaxation End Time(s)', 'Relaxation Time to Peak(s)', 'AVG Relaxation Velocity(μm/s)', 'BPM(Relaxation)', 'Relaxation Duration(s)', 'Relaxation Deformation Distance(μm)', 'AVG Relaxation Force(μN)', 'Contraction-Relaxation Time(s)' ...
    , 'Time to Decay 10%(s)', 'Time to Decay 50%(s)', 'Time to Decay 90%(s)'});

exportName = strcat('Summary.xlsx');
%delete(exportName)
writetable(T1, exportName, 'Sheet', 'Table1', 'WriteRowNames', true);

mkdir images;
movefile frames images;
movefile PIV images;
movefile Processed_PIV images;
movefile rawPeaks images;
movefile rawCombine images;
movefile Processed_heatmap images;
movefile Final_Video images;

save("data.mat")
disp("analysis finished");