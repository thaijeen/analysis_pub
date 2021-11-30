regdFs = glob('');
VRdatas = glob('');
csvfiles = glob('');
load('');

frame = orcainfo.nFrames/2;

labelfontsize = 21;

sec_x = linspace(-1, 4, 101);
roi_x = linspace(-1, 3, 81);
%%
%実行前にリセット
imgcounter = 0;
speedcounter = 0;
pupilcounter = 0;

tmpspeed = [];
tmppupil = [];
sumimagedata = zeros(288,288,81);
%%
%Annotation
load('');
load("");
load("");
topview_RGB = topview_RGB(1:size(topview_RGB,2),:,:);
topview_ID = topview_ID(1:size(topview_ID,2),:);

allenImg_resized      = imresize(topview_RGB/255.0, 1/4, 'nearest');
tmpAllenImgID_resized = imresize(topview_ID, 1/4, 'nearest');
allenImgID_resized    = tmpAllenImgID_resized;
allenValues           = unique(tmpAllenImgID_resized);
for i = 1:length(unique(tmpAllenImgID_resized))
allenImgID_resized(allenImgID_resized == allenValues(i)) = i;
end
allenImgID_resized = uint16(allenImgID_resized);

br_lam = ([206, 340]*25/10*1/4);
fixedPos = ([[1 1 1]*size(allenImg_resized, 2)/2 ; [br_lam(1) br_lam(2) 55]]);
refOutImg = imref2d(size(allenImg_resized));

tmp = unique(topview_ID);
for i = 1:length(tmp)
    [B{i}, L{i}, n, A{i}] = bwboundaries(topview_ID==tmp(i));
end

tmpGChImages =  dir('');
tmpGChImage  = imread(tmpGChImages(1).name);

figure;
subplot(1,3,1)
imshow(tmpGChImage);hold on
plot(marks(1,:), marks(2,:), '+y');

subplot(1,3,2)
imshow(allenImg_resized);hold on
plot(fixedPos(1,:), fixedPos(2,:), '+y');
for i = 2:length(B)
    tmp = B{i};
    for j = 1:length(tmp)
        plot(tmp{j}(:,2)/4, tmp{j}(:,1)/4, '-', 'Color', [1 1 1]*.25);
    end
end


% 回転
crd = fitgeotrans(marks(:,2:3)', fixedPos(:,2:3)', 'nonreflectivesimilarity');
refOutImg = imref2d(size(allenImg_resized, [1 2]));
Jregistered = imwarp(tmpGChImage, crd, 'OutputView', refOutImg);
imfluo_rgst = 1*imadjust(Jregistered, [0, 0.95]);

subplot(1,3,3)
imagesc(imfluo_rgst)
hold on; axis image;
for i = 2:length(B)
    tmp = B{i};
    for j = 1:length(tmp)
        plot(tmp{j}(:,2)/4, tmp{j}(:,1)/4, '-', 'Color', [1 1 0]*.95);
    end
end
colormap gray;
axis off;
set(gcf, 'Position', [50 50 1100 423]);

% saveas(gcf,'fig_Annotation.png');
%%
for i = 1:length(VRdatas)
    %load data
    [daq,info,~] = loadVR_Data(VRdatas{i});
    m = matfile(regdFs{i});
    pupildata = readmatrix(csvfiles{i});
    
    %speed
    timsec = daq.timev(:,1:2000:length(daq.timev));
    speed = spe(daq,2000);
    
    %pupil
    [pupilarea, TFblink] = ppl(daq, pupildata, timsec);
    
    %triger_index
    onset_index = triger(daq,timsec);
    
    for j=1:length(onset_index)
        if onset_index(j) - 20 > 0 && onset_index(j) + 60 < frame
            if sum(speed(onset_index(j)-10:onset_index(j)+30)<3) == 0 && sum(TFblink(onset_index(j)-10:onset_index(j)+30)) == 0
                %Speed_collect
                focus_speed = speed(onset_index(j) - 20:onset_index(j) + 80);
                tmpspeed = [tmpspeed;focus_speed];
                speedcounter = speedcounter + 1
                
                %pupil_collect
                focus_pupil = pupilarea(onset_index(j) - 20:onset_index(j) + 80);
                tmppupil = [tmppupil;focus_pupil];
                pupilcounter = pupilcounter + 1
                
                %img_collect
                z = m.regdF(:,:,onset_index(j)-20:onset_index(j) + 60);
%                 z = fliplr(z);
                sumimagedata = sumimagedata + z;
                imgcounter = imgcounter + 1
            end
        end
    end
end
%%
pupilpath = '';

figure
pupilchange = ((tmppupil ./ mean(tmppupil(:,1:20), 2)) - 1) * 100;
plot(sec_x, medfilt2(pupilchange,[1 3]), 'Color','#4DBEEE','LineStyle','--')
hold on
ave_tmpPupil = mean(tmppupil, 1);
ave_pupilchange = (ave_tmpPupil / mean(ave_tmpPupil(1:20)) - 1) * 100;
p = plot(sec_x, medfilt1(ave_pupilchange), 'Color','blue');
p.LineWidth = 2;
title('Pupil area change')
xlabel('Time [s]');
ylabel('Pupil area change [%]');
Square_coloring([0 1.5],'#F0F0F0');
hold off
set(gcf, 'Position', [-1500 -300 1200 600]);
myAxis

saveas(gcf, pupilpath)
%%
speedpath = '';

figure
plot(sec_x, medfilt2(tmpspeed,[1 3]), 'Color','#4DBEEE','LineStyle','--')
hold on
p = plot(sec_x, medfilt1(mean(tmpspeed, 1)), 'Color','blue');
p.LineWidth = 2;
title('Speed')
xlabel('Time [s]');
ylabel('Speed [cm/s]');
Square_coloring([0 1.5],'#F0F0F0');
hold off

set(gcf, 'Position', [-1500 -300 1200 600]);
myAxis

saveas(gcf, speedpath)
%%
avipath = '';

aveimagedata = sumimagedata / imgcounter;
baseline = mean(aveimagedata(:,:,1:20),3);
dFimg = aveimagedata - baseline;


dFimg = medfilt3(dFimg, [1 1 3]);

%raw movie
figure
formatSpec = '%.4f';
for n=1:size(dFimg,3)
    if n == 1
        im = imagesc(dFimg(:,:,n), [-0.005 0.015]);
        axis image;
        axis off
        c = colorbar;
        colormap inferno
        c.Label.String = 'dF';
        c.Label.FontSize = labelfontsize;
        set(gca,'FontSize',labelfontsize);
        title(num2str(n / 20 - 1.05, formatSpec) + " [s]")
    else
        im.CData = dFimg(:,:,n);
        title(num2str(n / 20 - 1.05, formatSpec) + " [s]")
    end
    pause(.1)
%     M(n) = getframe(gcf);
end

%動画保存
% avipath1 = strcat(avipath,'.avi');
% v = VideoWriter(avipath1,'Motion JPEG AVI');
% v.FrameRate = 10;
% open(v)
% writeVideo(v,M)
% close(v)

%ROI部分の蛍光変化プロット
% ROI = drawrectangle;
% ROI_dF = mean(dFimg(round(ROI.Position(2)):round(ROI.Position(2) + ROI.Position(4)), round(ROI.Position(1))...
%     :round(ROI.Position(1) + ROI.Position(3)),:), [1 2]);
% figure
% plot(img_sec_x, squeeze(ROI_dF))
% title('ROI dF change')
% xlabel('Time [s]');
% ylabel('dF');
% Square_coloring([0 1.5],'#F0F0F0');

%ano movie
crd = fitgeotrans(marks(:,2:3)', fixedPos(:,2:3)', 'nonreflectivesimilarity');
refOutImg = imref2d(size(allenImg_resized, [1 2]));
Jregistered = imwarp(dFimg, crd, 'OutputView', refOutImg);

figure
formatSpec = '%.4f';
for i = 1:size(Jregistered, 3)
    if i == 1
        im = imagesc(Jregistered(:,:,i), [-0.005 0.015]);
        axis image;
        axis off
        c = colorbar;
        colormap inferno
        c.Label.String = 'dF';
        c.Label.FontSize = labelfontsize;
        set(gca,'FontSize',labelfontsize);
        title(num2str(i / 20 - 1.05, formatSpec) + " [s]",'FontSize',labelfontsize)
        hold on; axis image;
        for j = 2:length(B)
            tmp = B{j};
            for j = 1:length(tmp)
                plot(tmp{j}(:,2)/4, tmp{j}(:,1)/4, '-', 'Color', [0 1 1]);
            end
        end
        rectangle('Position',roi,'EdgeColor','white','LineWidth',2)
    else
        im.CData = Jregistered(:,:,i);
        title(num2str(i / 20 - 1.05, formatSpec) + " [s]",'FontSize',labelfontsize)
    end
    pause(.1)
%     M(i) = getframe(gcf);
end

%ROI保存
% ROI = drawrectangle;
% roi = ROI.Position;
% save('roi','roi')

%動画保存
avipath2 = strcat(avipath, '_ano.avi');
v = VideoWriter(avipath2,'Motion JPEG AVI');
v.FrameRate = 10;
open(v)
writeVideo(v,M)
close(v)
%%
roicounter = 0;
tmproi = [];

for i = 1:length(VRdatas)
    
    %load data
    [daq,~,~] = loadVR_Data(VRdatas{i});
    m = matfile(regdFs{i});
    
    %speed
    timsec = daq.timev(:,1:2000:length(daq.timev));
    speed = spe(daq,2000);
    
    %triger_index
    onset_index = triger(daq,timsec);
    
    for j=1:length(onset_index)
        if onset_index(j) - 20 > 0 && onset_index(j) + 60 < frame
            if sum(speed(onset_index(j)-10:onset_index(j)+30)<3) == 0 && sum(TFblink(onset_index(j)-10:onset_index(j)+30)) == 0
                z = m.regdF(:,:,onset_index(j)-20:onset_index(j) + 60);
                rotz = imwarp(z, crd, 'OutputView', refOutImg);
                
                focusroi = mean(rotz(round(roi(2)):round(roi(2) + roi(4)),...
                    round(roi(1)):round(roi(1) + roi(3)),:), [1 2]);
                tmproi = [tmproi;focusroi];
                roicounter = roicounter + 1
            end
        end
    end
end
%%
roipath = '';

tmproi = squeeze(tmproi);
baseroi = mean(tmproi(:,1:20), 2);
dFroi = tmproi - baseroi;
filtdFroi = medfilt2(dFroi,[1 3]);

figure

plot(roi_x, filtdFroi, 'Color','#4DBEEE','LineStyle','--')
hold on

filtmeandFroi = medfilt2(mean(dFroi, 1),[1 3]);
p = plot(roi_x, filtmeandFroi, 'Color','blue');
p.LineWidth = 2;
title('ROI dF')
xlabel('Time [s]');
ylabel('dF');
myAxis
Square_coloring([0 1.5],'#F0F0F0');
hold off
set(gcf, 'Position', [-1500 -300 1200 600]);

saveas(gcf, roipath)