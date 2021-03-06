%% Finds the Variance Explained by M-Principal Components.
clear all;
close all;
clc;
datapath = '../../MNIST Dataset/';
addpath(['../../Toolbox/MBox']);
addpath(['../../Toolbox/']);

% Digits to include in analysis (to include all, n = 0:9);
n = [0:9];
% The values to show variance explaination by
conf_val = [1 0.975 0.95 0.90 0.80 0.60];
% Feature Mode [0:(pixels),1:(dont use),2:(1x272 v,h,radial histograms,
% radials in-out out-in profiles)].
mode = 2;
% cache feature data;
cache = 1; reset = 0; saveimgs = 0;
% rng(202322)) for report images.
rng(202322);
%% Load Data
addpath(datapath);

if ~cache || ~exist('data_cache.mat','file') || reset
    [Data, nrows, ncols] = loadMNISTImages( ...
        [datapath 'train-images-idx3-ubyte/train-images.idx3-ubyte'] );
    ims = reshape(Data,nrows,ncols,size(Data,2));   
    if mode ~= 0
        Data = feature_extraction( Data , nrows , ncols , mode )';
    end
    if reset
        delete data_cache.mat;
    end
    if cache
        save('data_cache.mat','Data','nrows','nrows','ims');
    end
else
    load data_cache;
end

Labels = loadMNISTLabels( ...
    [datapath 'train-labels-idx1-ubyte/train-labels.idx1-ubyte'] );
classNames = {'0';'1';'2';'3';'4';'5';'6';'7';'8';'9';'10'};
classLabels = classNames(Labels+1);

% Remove digits that are not to be inspected
j = ismember(Labels, n);
Data = Data(j,:);
classLabels = classLabels(j);
classNames = classNames(n+1);
Labels = cellfun(@(str) find(strcmp(str, classNames)), classLabels)-1;
clear 'j'
%% PCA
idx = 1:length(Labels);%find(Labels==1);
% Subtract the mean from the data
Y = bsxfun(@minus, Data, mean(Data));
Y = bsxfun(@rdivide, Y, std(Data));

% Obtain the PCA solution by calculate the SVD of Y
[U, S, V] = svd(Y,'econ');


%% Compute variance explained
rho = diag(S).^2./sum(diag(S).^2);
rhosum = cumsum(rho);

close all
pcs = min(sum(repmat(rhosum,[1,length(conf_val)]) <= ...
    repmat(conf_val,[length(rhosum),1]))+1,numel(rhosum));

% Plot variance explained
figure1 =  mfig('Digits: Var. explained');  clf;
set(figure1,'DefaultTextInterpreter', 'latex')
axes1 = axes( 'Parent',figure1, ...
    'XTick',[pcs(end:-1:1)], ...
    'YTick',[rhosum(1) rhosum(pcs(end:-1:1))'], ...
    'DataAspectRatio',[140 1 1]);
box(axes1,'on');
hold(axes1,'all');
plot(rhosum, 'Marker','.','Color',[0 0 1]);hold on

for j = 1:length(conf_val)
    npcs = [rhosum(1) pcs(j) pcs(j) ;rhosum(pcs(j)) rhosum(pcs(j)) rhosum(1)    ];
    plot(npcs(1,:),npcs(2,:),'r-');
end
ylim([rhosum(1) rhosum(end)]);

title('Variance explained by principal components','Interpreter','latex');
xlabel('M Principal component','Interpreter','latex');
ylabel('\% Variance explained by M PCs','Interpreter','latex');
axis tight

if saveimgs
    print -depsc epsFig
    copyfile('epsFig.eps','../../conf/img/var_explained.eps');
    print -djpeg epsFig
    copyfile('epsFig.jpg','../../conf/img/var_explained.jpg');
        delete('epsFig.eps');
    delete('epsFig.jpg');
end

%% Correlation

figure1 =  mfig('Digits: Corralation');  clf;
set(figure1,'DefaultTextInterpreter', 'latex')



N = 2000;
rng(202322);
ridx = randi([1,length(Data)],N,1);
[sortLabels sortIdx] = sort(Labels(ridx));  
n = hist(sortLabels);
nn = cumsum(n);


corrm = corr(Data(ridx,:)');
imagesc(corrm(sortIdx,sortIdx))%dont translate to get attribute corralation
test = corrm(sortIdx,sortIdx);
for r = 1:10
    for c = 1:10
        str = sprintf('%.2f',mean(mean(test(nn(r)-n(r)+1:nn(r),nn(c)-n(c)+1:nn(c)))));
        text(nn(c)-n(c)/2,nn(r)-n(r)/2,str,'FontSize',15,'FontWeight','bold','HorizontalAlignment','center');
    end
end
%caxis([-1 1])
colormap hot



set(gca,'XTick', nn-n/2);
set(gca,'XTickLabel',classNames); 
set(gca,'YTick', nn-n/2);
set(gca,'YTickLabel',classNames);
%set(gca,'DataAspectRatio',[1 1 1 ]);
axis equal square
xlim([0 N])
cb = colorbar('peer',gca);
ylabel(cb, 'Corralation Cooficient')
title('The corralation of 2000 samples sorted by class');
xlabel('2000 Samples over 10 classes');
ylabel('2000 Samples over 10 classes');
if saveimgs
    print -depsc corr_explained
    copyfile('corr_explained.eps','../../conf/img/corr_explained.eps');
    print -djpeg corr_explained
    copyfile('corr_explained.jpg','../../conf/img/corr_explained.jpg');
    delete('corr_explained.eps');
    delete('corr_explained.jpg');
end


figure1 =  mfig('Digits: Std');  clf;
set(figure1,'DefaultTextInterpreter', 'latex')


standalizedData = bsxfun(@minus, Data(ridx,:), mean(Data(ridx,:)));
standalizedData = bsxfun(@rdivide, standalizedData, std(Data(ridx,:)));
imagesc(max(min(standalizedData(sortIdx,:),3),-3));

colormap hot

set(gca,'XTick', [28/2 28/2+28 28*2+72/2 28*2+72+72/2  28*2+72+72+72/2]);
set(gca,'XTickLabel',{'V-Hist','H-Hist','Radial Histogram','In-Out','Out-in'}); 
set(gca,'YTick', nn-n/2);
set(gca,'YTickLabel',classNames);
%set(gca,'DataAspectRatio',[1 1 1 ]);
axis equal square
xlim([1 size(Data,2)])
cb = colorbar('peer',gca);
ylabel(cb, 'Std')
title('The std map of 2000 samples column standardized to zero mean and unit std.');
xlabel('Attributes');
ylabel('2000 Samples');
if saveimgs
    print -depsc std_explained
    copyfile('std_explained.eps','../../conf/img/std_explained.eps');
    print -djpeg std_explained
    copyfile('std_explained.jpg','../../conf/img/std_explained.jpg');
    delete('std_explained.eps');
    delete('std_explained.jpg');
end
%%

figure1 =  mfig('Digits: Attribute Correlation');  clf;
set(figure1,'DefaultTextInterpreter', 'latex')
imagesc(corr(Data))
axis image
colormap hot
xlim([0 size(Data,2)])
set(gca,'XTick', [28/2 28/2+28 28*2+72/2 28*2+72+72/2  28*2+72+72+72/2]);
set(gca,'XTickLabel',{'V-Hist','H-Hist','Radial Histogram','In-Out','Out-in'}); 
set(gca,'YTick', [28/2 28/2+28 28*2+72/2 28*2+72+72/2  28*2+72+72+72/2]);
set(gca,'YTickLabel',{'V-Hist','H-Hist','Radial Histogram','In-Out','Out-in'}); 
xlabel('Attributes')
ylabel('Attributes')
cb = colorbar('peer',gca);
title('The Correlation between attributes');

if saveimgs
    print -depsc att_corr_explained
    copyfile('att_corr_explained.eps','../../conf/img/att_corr_explained.eps');
    print -djpeg att_corr_explained
    copyfile('att_corr_explained.jpg','../../conf/img/att_corr_explained.jpg');
    delete('att_corr_explained.eps');
    delete('att_corr_explained.jpg');
end
%%
% Compute the projection onto the principal components
ridx = 1:length(U);
Z = U(ridx,:)*S;
co = [1 2];
mfig(['Digits: PCA']); clf; hold all; 
C = length(classNames);
for c = 0:C-1
    Xc = [ Z(Labels(ridx)==c,co(1)) Z(Labels(ridx)==c,co(2))];%  Z(Labels(ridx)==c,3)];
%    plot(Z(Labels(ridx)==c,1), Z(Labels(ridx)==c,2), 'o');
    error_ellipse(cov(Xc),'conf',0.75,'mu',mean(Xc),'style','-');
end
legend(classNames);
xlabel('PC1');
ylabel('PC2');
zlabel('PC3');
title('PCA of digits data');
%% BETTER PC1 vs PC2 Plot
figure1 = mfig(['Digits: Projections']); clf; hold all; 
set(figure1,'DefaultTextInterpreter', 'latex');
rng(202322);
Z = U*S;
C = length(classNames);
N=1000;
idx = zeros(N,C);
[1 0 0]
scale = 6;
mapsize=500*scale;
map = zeros(mapsize,mapsize,3);
cmap =[1 0 0    %0
       0 1 0    %1
       0.5 0 1  %2
       1 1 0    %3
       0 1 1    %4
       1 0.5 1  %5
       0.5 0.5 0%6
       .2 0.5 0.5%7
       0.5 1 .5 %8
       0.5 0 0 ]%9
maxx = -inf;
minx = inf;
maxy = -inf;
miny = inf;
idx = [];
for c = 0:C-1
    allidx = find(Labels==c);    
    idx = [idx allidx(randi([1,length(allidx)],N,1))];
    
end
idx = randperm(idx);
Xc = [ Z(idx,1) Z(idx,2)]*scale*9;
    for n = 1:length(Xc);
       % (round(Xc(n,2))-14:round(Xc(n,2))+13)+1000
       % (round(Xc(n,1))-14:round(Xc(n,1))+13)+1000
       if ~any( map(  (round(Xc(n,2))-14:round(Xc(n,2))+13)+mapsize/2, (round(Xc(n,1))-14:round(Xc(n,1))+13)+mapsize/2,: ))
        im = repmat(flipud(ims(:,:,idx(n)))/255,[1 1 3]);
        im(:,:,1) = im(:,:,1)*cmap(Labels(idx(n))+1,1);
        im(:,:,2) = im(:,:,2)*cmap(Labels(idx(n))+1,2);
        im(:,:,3) = im(:,:,3)*cmap(Labels(idx(n))+1,3);
        if miny > round(Xc(n,2))-14
            miny = round(Xc(n,2))-14;
        end
        if minx > round(Xc(n,1))-14
            minx = round(Xc(n,1))-14;
        end
        if maxx < round(Xc(n,1))+13
            maxx = round(Xc(n,1))+13;
        end
        if maxy < round(Xc(n,2))+13
            maxy = round(Xc(n,2))+13;
        end
           map(  (round(Xc(n,2))-14:round(Xc(n,2))+13)+mapsize/2, ... 
               (round(Xc(n,1))-14:round(Xc(n,1))+13)+mapsize/2,: ) = ...
               im;
        %imagesc([Xc(n,1)-14.5 Xc(n,1)+14.5],[Xc(n,2)-14.5 Xc(n,2)+14.5], repmat(ims(:,:,idx(n))/255,[1 1 3]));
       end
    end
    image(1-map);

    xlim([minx+100 maxx-300]+mapsize/2);
    ylim([miny+400 maxy-100]+mapsize/2);
axis equal
set(gca,'XTickLabel',(get(gca,'XTick')-mapsize/2) / scale/9 ); 
set(gca,'YTickLabel',(get(gca,'YTick')-mapsize/2) / scale/9); 
xlabel('PC1');
ylabel('PC2');
title('Projections of data to PC1 and PC2')
%set(gca,'YTick', [28/2 28/2+28 28*2+72/2 28*2+72+72/2  28*2+72+72+72/2]);
%set(gca,'YTickLabel',{'V-Hist','H-Hist','Radial Histogram','In-Out','Out-in'}); 
if saveimgs
    print -depsc pc_projections
    copyfile('pc_projections.eps','../../conf/img/pc_projections.eps');
    print -djpeg pc_projections
    copyfile('pc_projections.jpg','../../conf/img/pc_projections.jpg');
    delete('pc_projections.eps');
    delete('pc_projections.jpg');
end

%%
N = 50000;
ridx = 1:length(Data) ;%randi([1,length(Data)],N,1)  
Z = U(ridx,:)*S;
clear pcs Q
mfig(['Digits: Test']);  clf; hold all;
set(figure1,'DefaultTextInterpreter', 'latex')
C = length(classNames);
N = 5;
co = jet(10);%{'r','y','b','g'};
labels = [0 1 2]
for cc = 1:4
subplot(2,2,cc)

for c = 1:3
   % size(Z(Labels(ridx)==c,1:10)')
   pcs = Z(Labels(ridx)==labels(c),1:N);
   %  plot(Z(Labels(ridx)==c,1:10)','color',co(c+1,:))
   %plot(1:N,mean(pcs),'.','color',co(c+1,:))
   if 0
   text(((c+1)/3:N),mean(pcs),['\mu_' num2str(labels(c)) ])
   text((1:N),mean(pcs)+std(pcs)*2,['\sigma_' num2str(labels(c)) ])
   text((1:N),mean(pcs)-std(pcs)*2,['\sigma_' num2str(labels(c)) ])
   line([1:N;1:N],[mean(pcs)-std(pcs)*2 ;mean(pcs)+std(pcs)*2], 'color',co(c+1,:))
   else
   % STEP 1 - rank the data
    y = sort(pcs);
for n = 1:N
% compute 25th percentile (first quartile)
    Q(1,n) = median(y(find(y(:,n)<median(y(:,n))),n));

% compute 50th percentile (second quartile)
    Q(2,n) = median(y(:,n));

% compute 75th percentile (third quartile)
    Q(3,n) = median(y(find(y(:,n)>median(y(:,n))),n));

% compute Interquartile Range (IQR)
    IQR(n) = Q(3,n)-Q(1,n);

% compute Semi Interquartile Deviation (SID)
% The importance and implication of the SID is that if you 
% start with the median and go 1 SID unit above it 
% and 1 SID unit below it, you should (normally) 
% account for 50% of the data in the original data set
    SID = IQR/2;
   text(n-1+(c+2)/4+0.01,Q(2,n),['\mu^' num2str(labels(c)) ''])
   text(n-1+(c+2)/4+0.01,Q(1,n),['p_{25}^' num2str(labels(c)) ])
   text(n-1+(c+2)/4+0.01,Q(3,n),['p_{75}^' num2str(labels(c)) ])
   line([n;n]-1+(c+2)/4,[Q(1,n);Q(3,n)], 'color',co(c+1,:))
   end
   end
   
   
     %boxplot(Z(Labels(ridx)==c,1:10));
   % plot(1:10, Z(Labels(ridx)==c,1:10), 'o');
end
set(gca,'XTick', 1:N);
set(gca,'XTickLabel',{'PC1','PC2','PC3','PC4','PC5','PC6','PC7','PC8','PC9','PC10'}); 
%set(gca,'YTick', [28/2 28/2+28 28*2+72/2 28*2+72+72/2  28*2+72+72+72/2]);
%set(gca,'YTickLabel',{'V-Hist','H-Hist','Radial Histogram','In-Out','Out-in'}); 
xlim([0.5 N+0.5])
ylim([-20 15])
labels = labels+2;
end
if saveimgs
    print -depsc pca_projections_explained
    copyfile('pca_projections_explained.eps','../../conf/img/pca_projections_explained.eps');
    print -djpeg pca_projections_explained
    copyfile('pca_projections_explained.jpg','../../conf/img/pca_projections_explained.jpg');
    delete('pca_projections_explained.eps');
    delete('pca_projections_explained.jpg');
end
%%
%S = 60;M = 1;N =10; C((S-M*N+N-1),(N-1)) / C(S+N-1,(N-1))