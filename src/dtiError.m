function [err, dwi, coords, predicted, measured] = dtiError(baseName,varargin)
% Find RMSE between measured and ADC (or dSIG) based on tensor model
%
%      [err, dwi, coords] = dtiError(baseName,...
%                               'coords',coords,...
%                               'eType',{'adc','dsig'}, ...
%                               'wmProb',filename, ...
%                               'ncoords',integer);
%
% Calculate the histogram of differences between dti based predictions
% (ADC or dSig) with the actual ADC or dSig data. Larger deviations suggest
% noisier data.
%
% This is one of a series of methods we are developing to assess the
% reliability of diffusion weighted image data.
%
% Required:
%  baseName:  The full path to the base name of nifti, bvec, bval of a
%             diffusion weighted scan
%
% Optional parameter/value:
%    coords:  Nx3 list of spatial coordinates for the analysis
%    eType:   Error type.  Either ADC or diffusion signal (dSig)
%    wmProb:  A full path to a brain white probability file
%
% Example:
%
%  To run this example, we downloaded a data set from Flywheel and put it
%  in the local dir.  See dtiErrorNotes.m for now for how we did this.
%
%    dirName = 'dtiInit_03-Oct-2016_21-17-04';
%    baseDir = fullfile(dtiErrorRootPath,'local',dirName);
%    d = dir(fullfile(baseDir,'*aligned*.nii.gz'));
%    baseName = fullfile(baseDir,d.name);
%    [X Y Z] = meshgrid(30:50, 30:50, 30:50); coords = [X(:) Y(:) Z(:)];
%    % [X Y Z] = meshgrid(40, 40, 40); coords = [X(:) Y(:) Z(:)];
%
%    err = dtiError(baseName,'coords',coords,'eType','adc');
%    mrvNewGraphWin;
%    hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
%    fprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err));
%
%    err = dtiError(baseName,'coords',coords,'eType','dsig');
%    mrvNewGraphWin;
%    hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
%    fprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err));
%
%    wmProb = fullfile(baseDir,'dti31trilin','bin','wmProb.nii.gz');
%    err = dtiError(baseName,'wmProb',wmProb,'eType','adc','ncoords',5);
%    mrvNewGraphWin;
%    hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
%    fprintf('DWI image quality %.2f (ADC-DTI method, higher better)\n',1/std(err));
%
%    err = dtiError(baseName,'wmProb',wmProb,'eType','dsig','ncoords',250);
%    mrvNewGraphWin;
%    hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
%    fprintf('DWI image quality %.2f (DSIG-DTI eval method, higher better)\n',1/std(err));
%
% LMP/BW Vistalab Team, 2016

%% Identify and load the dwi and metadata files

p = inputParser;
p.addRequired('baseName',@ischar);
p.addParameter('eType','adc',@ischar);
p.addParameter('coords',[],@ismatrix);
p.addParameter('wmProb','',@ischar);
p.addParameter('ncoords',125,@isnumeric);

p.parse(baseName,varargin{:});
eType  = p.Results.eType;
coords = p.Results.coords;

% White matter probability file name given.  Check that it exists.
wmProb = p.Results.wmProb;   
if ~isempty(wmProb) && ~exist(wmProb,'file')
    error('White matter probability file %s not found',wmProb);
end
% ni = niftiRead(wmProb); niftiView(ni);

if exist(baseName,'file'),     dwi = dwiLoad(baseName);
else,                          error('Diffusion data file %s not found\n');
end
% dwiPlot(dwi,'bvecs');

%% Deal with coordinates

% If there are coords passed in, move along
if isempty(coords)
    if ~isempty(wmProb)
        % If there is a white matter brain mask, select ncoords within that
        % mask 
        ncoords = p.Results.ncoords;

        % We read and randomly define selected values here
        bmask = niftiRead(wmProb);
        
        bmask.data(bmask.data <= 180) = 0;
        bmask.data(bmask.data > 180)  = 1;
        % niftiView(bmask);

        [i,j,k] = ind2sub(size(bmask.data),find(bmask.data == 1));
        imax = length(i);
        lst = randi(imax,ncoords,1);
        allCoords = [i,j,k];
        coords = allCoords(lst,:);

    else
        % Not sure what to do here, yet. We might find the b=0 data, select
        % high values, and choose nCoords within that
        disp('No coords and no wmProb.  Returning');
        return;
        % Get the b=0 data and find the nCoords from the top 50% of the top
        % b values
    end
end

%% ADC or dSig from the coordinates and evaluate the tensor

switch eType
    case 'adc'
        % These are the ADC data from the signals in the dwi nifti file
        adc = dwiGet(dwi,'adc data image',coords);
        nBadADCcoords = sum(isnan(adc));
        if nBadADCcoords
            warning('Discarding %d voxels with inaccurate ADC estimates', nBadADCcoords);
        end
        % These are the tensors to predict the ADC data coords
        % It is possible to return the predicted ADC from dwiQ, as well,
        % by a small adjustment to that function.
        Q = dwiQ(dwi,coords);

        % Instead, we separately calculate the predicted ADC values
        bvecs = dwiGet(dwi,'diffusion bvecs');
        adcPredicted = dtiADC(Q,bvecs);

        % A visualization, if you like
        % dwiPlot(dwi,'adc',adc(:,5),squeeze(Q(:,:,5)));
        % mrvNewGraphWin;
        % plot(adc(:),adcPredicted(:),'o')
        % identityLine(gca); axis equal

        % Sometimes data are drawn from just outside of the white matter
        % region and the ADC values are not valid.  This happens from time
        % to time, and we aren't worrying about it.  We just delete those
        % pixels.
        lst = ~isnan(adc);
        err = adc(lst) - adcPredicted(lst);
        measured = adc(lst);
        predicted = adcPredicted(lst);

    case 'dsig'
        % Analyze the diffusion signals in the dwi nifti file
        dsig = dwiGet(dwi,'diffusion signal image',coords);

        % These are the tensors to predict the ADC data coords
        % It is possible to return the predicted ADC from dwiQ, as well,
        % by a small adjustment to that function.
        Q = dwiQ(dwi,coords);

        % Sometimes there are bad coordinates out there.  We protect you.
        nBadADCcoords = sum(isnan(Q(1,1,:)));
        if nBadADCcoords
            goodCoords = squeeze(~isnan(Q(1,1,:)));
            coords = coords(goodCoords,:);
            dsig = dwiGet(dwi,'diffusion signal image',coords);
            Q = dwiQ(dwi,coords);
            warning('Discarding %d predicted DSIG', nBadADCcoords);
        end
        % Instead, we separately calculate the predicted ADC values
        % Fix this code!
        bvecs = dwiGet(dwi,'diffusion bvecs');
        bvals = dwiGet(dwi,'diffusion bvals');
        S0 = dwiGet(dwi,'b0 image',coords);
        
        S0 = mean(S0,2);  % If multiple b=0 images, use the mean
        dsigPredicted = dwiComputeSignal(S0, bvecs, bvals, Q);
        dsigPredicted = dsigPredicted';

        % We could use percentage error by dividing by dsig().
        err = dsig(:) - dsigPredicted(:);
        measured = dsig(:);
        predicted = dsigPredicted(:);

    otherwise
        error('Unknown error type %s\n',eType);
end

end
