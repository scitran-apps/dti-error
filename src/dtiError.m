function err = dtiError(baseName,varargin)
% Find the RMSE between the measured and ADC DTI estimated ADC
%
%     err = dtiError(baseName,'coords',coords)
%
% This is part of a series of methods we are developing to assess the
% reliability of diffusion weighted image data.
%
% Calculate the histogram of differences between dti based predictions
% (ADC or dSig) with the actual ADC or dSig data. Larger deviations are
% treated as noisier data.
%
% Required:
%  baseName:  The full path to the base name of nifti, bvec, bval of a
%             diffusion weighted scan
%
% Optional parameter/value:
%    coords:  Nx3 list of spatial coordinates for the analysis
%    eType:   Error type.  Either ADC or diffusion signal (dSig)
%    brainMask:  A full path to a brain mask file
%
% We haven't figured out what to do about coords in general.  Something
% about the brainMask and coords needs to be figured out.
%
% TODO:
%   Check the dsig coordinate arrangement to make sure we are properly
%   aligned with the data.  Try 1 coordinate, then 3 coordinates and see
%   that the Q values and dsigs make sense as we add in each coordinate
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
%    % [X Y Z] = meshgrid(40:45, 40:45, 40:45);
%    [X Y Z] = meshgrid(40, 40, 40); coords = [X(:) Y(:) Z(:)];
%
%    err = dtiError(baseName,'coords',coords);
%    mrvNewGraphWin; 
%    hist(err,50); xlabel('\Delta ADC'); ylabel('Count')
%
%    err = dtiError(baseName,'coords',coords,'eType','dsig');
%    mrvNewGraphWin; 
%    hist(err,50); xlabel('\Delta DSIG'); ylabel('Count')
%
%    bmask = fullfile(baseDir,'dti31trilin','bin','brainMask.nii.gz');
%    err = dtiError(baseName,'brainMask',bmask,'eType','adc');
%
% LMP/BW Vistalab Team, 2016

%% Identify and load the dwi and metadata files

p = inputParser;
p.addRequired('baseName',@ischar);
p.addParameter('eType','adc',@ischar);
p.addParameter('coords',[],@ismatrix);
p.addParameter('brainMask','',@ischar);
p.addParameter('ncoords',125,@isnumeric);

p.parse(baseName,varargin{:});
eType  = p.Results.eType;
coords = p.Results.coords;
brainMask = p.Results.brainMask;
if ~isempty(brainMask) && ~exist(brainMask,'file')
    error('Brain mask file %s not found',brainMask); 
end
% ni = niftiRead(brainMask); niftiView(ni);

if exist(baseName,'file'),     dwi = dwiLoad(baseName);
else                           error('Diffusion data file %s not found\n');
end
% dwiPlot(dwi,'bvecs');

%% Deal with coordinates

% If there are coords passed in, move along
if isempty(coords)
    if ~isempty(brainMask)
        bmask = niftiRead(brainMask);
        [i,j,k] = ind2sub(size(bmask.data),find(bmask.data == 1));
        
        lst = randi(imax,1.5*nCoords);
        
        coords = zeros(length(i),3);
        coords(:,1) = i; coords(:,2) = j; coords(:,3) = k;
        
    else
        disp('NYI')
        % Get the b=0 data and find the nCoords from the top 50% of the top
        % b values
    end
end

% Else if there is a brain mask passed in use nCoords within that
% Else find the b=0 data, select high values, and choose nCoords within
% that
%

%% ADC or dSig from the coordinates and evaluate the tensor

% We need 
%   * a dsig error type implemented
%   * a way to generate coords through the brain mask
%   * a fix to the code in dwiGet, I think, that receives multiple coors
%   
switch eType
    case 'adc'
        % These are the ADC data from the signals in the dwi nifti file
        adc = dwiGet(dwi,'adc data image',coords);
        
        % These are the tensors to predict the ADC data coords
        % It is possible to return the predicted ADC from dwiQ, as well,
        % by a small adjustment to that function.
        Q = dwiQ(dwi,coords);

        % Instead, we separately calculate the predicted ADC values
        bvecs = dwiGet(dwi,'diffusion bvecs');
        adcPredicted = dtiADC(Q,bvecs);
        
        % A visualization, if you like
        % dwiPlot(dwi,'adc',adc(:,1),squeeze(Q(:,:,1)));
        % mrvNewGraphWin;
        % plot(ADC(:),uData.adcPredicted(:),'o')
        % identityLine(gca);
        
        err = adc(:) - adcPredicted(:);
    case 'dsig'
        
        % These are the ADC data from the signals in the dwi nifti file
        dsig = dwiGet(dwi,'diffusion signal image',coords);
        
        % These are the tensors to predict the ADC data coords
        % It is possible to return the predicted ADC from dwiQ, as well,
        % by a small adjustment to that function.
        Q = dwiQ(dwi,coords);

        % Instead, we separately calculate the predicted ADC values
        % Fix this code!
        bvecs = dwiGet(dwi,'diffusion bvecs');
        bvals = dwiGet(dwi,'diffusion bvals');
        S0 = dwiGet(dwi,'b0valsimage',coords);
        dsigPredicted = dwiComputeSignal(S0, bvecs, bvals, Q);
        dsigPredicted = dsigPredicted';
        
        err = dsig(:) - dsigPredicted(:);
        % Percent error
        % pErr = err ./ dsig(:);
        
    otherwise
        error('Unknown error type %s\n',eType);
end

end




