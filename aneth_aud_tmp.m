regdFs = glob('');
VRdatas = glob('');
%%
%Annotation
load('marks');
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

tmpGChImages =  dir('*gCh.png');
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
%定数定義
soundonset = linspace(5,300,60).';
onsettime = table(soundonset(1:3:length(soundonset)),soundonset(2:3:length(soundonset)),soundonset(3:3:length(soundonset)));
onsettime.Properties.VariableNames = {'kHz6','kHz12','kHz18'};

labelfontsize = 17;
img_sec_x = linspace(-1, 3, 81);
%%
%実行前にリセット
imgcounter_kHz6 = 0;
imgcounter_kHz12 = 0;
imgcounter_kHz18 = 0;

sumimagedata_kHz6 = zeros(288,288,81);
sumimagedata_kHz12 = zeros(288,288,81);
sumimagedata_kHz18 = zeros(288,288,81);
%%
[daq,~,~] = loadVR_Data(VRdatas{1});
timsec = daq.timev(:,1:2000:length(daq.timev));

%onsetindex table
onsetindex = table(zeros(length(onsettime.kHz6),1),zeros(length(onsettime.kHz6),1),zeros(length(onsettime.kHz18),1));
onsetindex.Properties.VariableNames = {'kHz6','kHz12','kHz18'};

for j=1:length(onsetindex.kHz6)
    onsetindex.kHz6(j) = find(timsec==onsettime.kHz6(j));
    onsetindex.kHz12(j) = find(timsec==onsettime.kHz12(j));
    onsetindex.kHz18(j) = find(timsec==onsettime.kHz18(j));
end
    
%フレームずれ補正
onsetindex.kHz6 = onsetindex.kHz6 + 2
onsetindex.kHz12 = onsetindex.kHz12 + 2
onsetindex.kHz18 = onsetindex.kHz18 + 2

for i = 1:length(VRdatas)
    
    %load data
    m = matfile(regdFs{i});
    
    for j = 1:length(onsetindex.kHz6)
        
        %%%%%%%%%%%%6kHz%%%%%%%%%%%%
            
        z = m.regdF(:,:,onsetindex.kHz6(j)-20:onsetindex.kHz6(j) + 60);
        sumimagedata_kHz6 = sumimagedata_kHz6 + z;
        imgcounter_kHz6 = imgcounter_kHz6 + 1
        
        %%%%%%%%%%%%12kHz%%%%%%%%%%%%
        
        z = m.regdF(:,:,onsetindex.kHz12(j) - 20:onsetindex.kHz12(j) + 60);
        sumimagedata_kHz12 = sumimagedata_kHz12 + z;
        imgcounter_kHz12 = imgcounter_kHz12 + 1
        
        %%%%%%%%%%%%18kHz%%%%%%%%%%%%
        
        z = m.regdF(:,:,onsetindex.kHz18(j)-20:onsetindex.kHz18(j) + 60);
        sumimagedata_kHz18 = sumimagedata_kHz18 + z;
        imgcounter_kHz18 = imgcounter_kHz18 + 1
    end
end
%%
%pathの周波数を確認
avipath = '';

%周波数確認
sumimagedata = sumimagedata_kHz6;
imgcounter = imgcounter_kHz6;

aveimagedata = sumimagedata / imgcounter;
baseline = mean(aveimagedata(:,:,1:20),3);
tonestimuimg = aveimagedata - baseline;


tonestimuimg = medfilt3(tonestimuimg, [1 1 3]);

%raw movie
figure
formatSpec = '%.4f';
for n=1:size(tonestimuimg,3)
    if n == 1
        im = imagesc(tonestimuimg(:,:,n), [-0.0005 0.005]);
        axis image;
        axis off
        c = colorbar;
        colormap inferno
        c.Label.String = 'dF';
        c.Label.FontSize = labelfontsize;
        set(gca,'FontSize',labelfontsize);
        title(num2str(n / 20 - 1.05, formatSpec) + " [s]")
    else
        im.CData = tonestimuimg(:,:,n);
        title(num2str(n / 20 - 1.05, formatSpec) + " [s]")
    end
    pause(.1)
    M(n) = getframe(gcf);
end

avipath1 = strcat(avipath, '_raw','.avi');
v = VideoWriter(avipath1,'Motion JPEG AVI');
v.FrameRate = 10;
open(v)
writeVideo(v,M)
close(v)


%ano movie
crd = fitgeotrans(marks(:,2:3)', fixedPos(:,2:3)', 'nonreflectivesimilarity');
refOutImg = imref2d(size(allenImg_resized, [1 2]));
Jregistered = imwarp(tonestimuimg, crd, 'OutputView', refOutImg);

figure
formatSpec = '%.4f';
for i = 1:size(Jregistered, 3)
    if i == 1
        im = imagesc(Jregistered(:,:,i), [-0.0005 0.005]);
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
    else
        im.CData = Jregistered(:,:,i);
        title(num2str(i / 20 - 1.05, formatSpec) + " [s]",'FontSize',labelfontsize)
    end
    pause(.1)
%     M(i) = getframe(gcf);
end

ROI = drawrectangle;
roi = ROI.Position;

save('roi', 'roi');

%pathのrun or stable確認
avipath2 = strcat(avipath, '_ano','.avi');
v = VideoWriter(avipath2,'Motion JPEG AVI');
v.FrameRate = 10;
open(v)
writeVideo(v,M)
close(v)
%%
%roi collect
roi_x = linspace(-1, 3, 81);

roicounter_kHz6 = 0;
roicounter_kHz12 = 0;
roicounter_kHz18 = 0;

tmproi_kHz6 = [];
tmproi_kHz12 = [];
tmproi_kHz18 = [];

for i = 1:length(VRdatas)
    
    %load data
    m = matfile(regdFs{i});
    
    for j = 1:length(onsetindex.kHz6)
        
        %%%%%%%%%%%%6kHz%%%%%%%%%%%%
            
        z = m.regdF(:,:,onsetindex.kHz6(j)-20:onsetindex.kHz6(j) + 60);
        rotz = imwarp(z, crd, 'OutputView', refOutImg);
            
        focusroi_kHz6 = mean(rotz(round(roi(2)):round(roi(2) + roi(4)),...
            round(roi(1)):round(roi(1) + roi(3)),:), [1 2]);
        tmproi_kHz6 = [tmproi_kHz6;focusroi_kHz6];
        roicounter_kHz6 = roicounter_kHz6 + 1
        
        %%%%%%%%%%%%12kHz%%%%%%%%%%%%
        
        z = m.regdF(:,:,onsetindex.kHz12(j)-20:onsetindex.kHz12(j) + 60);
        rotz = imwarp(z, crd, 'OutputView', refOutImg);
            
        focusroi_kHz12 = mean(rotz(round(roi(2)):round(roi(2) + roi(4)),...
            round(roi(1)):round(roi(1) + roi(3)),:), [1 2]);
        tmproi_kHz12 = [tmproi_kHz12;focusroi_kHz12];
        roicounter_kHz12 = roicounter_kHz12 + 1
        
        %%%%%%%%%%%%18kHz%%%%%%%%%%%%
        
        z = m.regdF(:,:,onsetindex.kHz18(j)-20:onsetindex.kHz18(j) + 60);
        rotz = imwarp(z, crd, 'OutputView', refOutImg);
        
        focusroi_kHz18 = mean(rotz(round(roi(2)):round(roi(2) + roi(4)),...
            round(roi(1)):round(roi(1) + roi(3)),:), [1 2]);
        tmproi_kHz18 = [tmproi_kHz18;focusroi_kHz18];
        roicounter_kHz18 = roicounter_kHz18 + 1
    end
end
%%
roipath = '';

tmproi = tmproi_kHz18;
tmproi = squeeze(tmproi);

baseroi = mean(tmproi(:,1:20), 2);
dFroi = tmproi - baseroi;

filtdFroi = medfilt2(dFroi,[1 3]);

figure

plot(roi_x, filtdFroi, 'Color','#dda0dd','LineStyle','--')
hold on

filtmeandFroi = medfilt2(mean(dFroi, 1),[1 3]);
p = plot(roi_x, filtmeandFroi, 'Color',[1 0 1])
p.LineWidth = 2;

%タイトルの周波数変更
title('ROI dF 18 kHz')
xlabel('Time [s]');
ylabel('dF');
myAxis
Square_coloring([0 1],'#F0F0F0');
legend(p,'Aneth')
hold off
set(gcf, 'Position', [-1500 -300 1200 600]);

saveas(gcf, roipath)

%roiの範囲を示す画像
figure
formatSpec = '%.4f';


im = imagesc(Jregistered(:,:,i), [-0.005 0.015]);
axis image;
axis off
c = colorbar;
colormap inferno
c.Label.String = 'dF';
c.Label.FontSize = labelfontsize;
set(gca,'FontSize',labelfontsize);
hold on; axis image;
for j = 2:length(B)
    tmp = B{j};
    for j = 1:length(tmp)
        plot(tmp{j}(:,2)/4, tmp{j}(:,1)/4, '-', 'Color', [0 1 1]);
    end
end
rectangle('Position',roi,'EdgeColor','white','LineWidth',2)

roipath2 = '';
saveas(gcf, roipath2)