%%
dirName = 'dtiInit_03-Oct-2016_21-17-04';
baseDir = fullfile(dtiErrorRootPath,'local',dirName);
d = dir(fullfile(baseDir,'*aligned*.nii.gz'));
baseName = fullfile(baseDir,d.name);
[X, Y, Z] = meshgrid(30:50, 30:50, 30:50); coords = [X(:) Y(:) Z(:)];
%%
err = dtiError(baseName,'coords',coords,'eType','adc');
mrvNewGraphWin;
hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
fprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err));
%%
err = dtiError(baseName,'coords',coords,'eType','dsig');
mrvNewGraphWin;
hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
fprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err));

%% This shows how to plot the adc and the error, manually

wmProb = fullfile(baseDir,'dti31trilin','bin','wmProb.nii.gz');
[err, dwi, coords] = dtiError(baseName,'wmProb',wmProb,'eType','adc','ncoords',5);
mrvNewGraphWin;
hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
fprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err));

adc = dwiGet(dwi,'adc data image',coords);
Q = dwiQ(dwi,coords);
bvecs = dwiGet(dwi,'diffusion bvecs');
adcPredicted = dtiADC(Q,bvecs);
dwiPlot(dwi,'adc',adc(:,5),squeeze(Q(:,:,5)));

mrvNewGraphWin;
plot(adc(:),adcPredicted(:),'o')
identityLine(gca); axis equal

%%
err = dtiError(baseName,'wmProb',wmProb,'eType','dsig','ncoords',250);
mrvNewGraphWin;
hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
fprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err));

%%