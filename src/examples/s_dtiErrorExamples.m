
%% Load data

% dirName = 'dtiInit_03-Oct-2016_21-17-04';
dirName = 'dtiInit_27-Jan-2017_16-12-48';
baseDir = fullfile(dtiErrorRootPath,'local',dirName);
d = dir(fullfile(baseDir,'*aligned*.nii.gz'));
baseName = fullfile(baseDir,d.name);


%% Error based on coords

[X, Y, Z] = meshgrid(30:50, 30:50, 30:50); 
coords = [X(:) Y(:) Z(:)];

% ADC
err = dtiError(baseName,'coords',coords,'eType','adc');
FH = mrvNewGraphWin;
hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
fprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err));
title(sprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err)));
saveas(gcf, fullfile(mrvDirup(baseDir),'adc_error_coords.png'));


% Diffusion Signal
err = dtiError(baseName,'coords',coords,'eType','dsig');
mrvNewGraphWin;
hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
fprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err));
title(sprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err)));
saveas(gcf, fullfile(mrvDirup(baseDir),'dsig_error_coords.png'));


%% Plot the adc and the error manually using wmProb image to choose voxels

wmProb = fullfile(baseDir,'dti32trilin','bin','wmProb.nii.gz');
[err, dwi, coords] = dtiError(baseName,'wmProb',wmProb,'eType','adc','ncoords',5);


mrvNewGraphWin;
hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
fprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err));
title(sprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err)));
saveas(gcf, fullfile(mrvDirup(baseDir),'adc_error_wmprob.png'));


% Plot adc prediction vs observed

% Plot surface
adc = dwiGet(dwi,'adc data image',coords);
Q = dwiQ(dwi,coords);
bvecs = dwiGet(dwi,'diffusion bvecs');
adcPredicted = dtiADC(Q,bvecs);
dwiPlot(dwi,'adc',adc(:,5),squeeze(Q(:,:,5)));
saveas(gcf, fullfile(mrvDirup(baseDir),'adc_observed_predicted_surface.png'));

% Plot points 
mrvNewGraphWin;
plot(adc(:),adcPredicted(:),'o')
xlabel('ADC Observed') 
ylabel('ADC Predicted')
identityLine(gca); axis equal
title('ADC Observed/Predicted');
saveas(gcf, fullfile(mrvDirup(baseDir),'adc_observed_predicted.png'));


%% WM Probability, DSIG, Coords

[err, dwi, coords] = dtiError(baseName,'wmProb',wmProb,'eType','dsig','ncoords',250);

mrvNewGraphWin;
hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
fprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err));
title(sprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err)));
saveas(gcf, fullfile(mrvDirup(baseDir),'wmprob_dsig_250coords.png'));

%%

