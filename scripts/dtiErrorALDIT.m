function nRMSE = dtiErrorALDIT(varargin)
% ALDIT data set error analysis (phantom data)
%
% Syntax
%     nRMSE = dtiErrorALDIT(...);
%
% Description 
%   Analyze the diffusion weighted imaging noise from a site using
%   dtiError. The data from multiple b-values are stored in an acquisition
%   for each site.
%
%   The graph and numerical evaluations can be compared with data from
%   phantom measurements on other scanners.
%
% Inputs (required)
%  None
%
% Inputs (optional)
%  project - Project label
%  session - Session label
%  wmPercentile - White matter percentile
%  nSamples     - Number of bootstrap samples
%  scatter      - Boolean.  Plot scatter
%  histogram    - Boolean.  Plot error histogram
%
% Examples in the source code
%
% BW Scitran Team, 2017
%
% See also:  scitran.runFunction

% st = scitran('vistalab');
%{ 
  % Upload to Flywheel
  thisFile = which('dtiErrorALDIT.m');
  project  = st.search('project','project label exact','ALDIT');
  status = st.upload(thisFile,'project',idGet(project));
%}

% Example:
%{
    project = 'ALDIT';
    session = 'Set 1';
    dtiErrorALDIT('project',project,'session',session);
%}
%{
    clear params; 
    params.project = 'ALDIT';
    params.session = 'Set 2';
    params.wmPercentile = 80; params.nSamples = 500;
    params.scatter = false; params.histogram = true;
    RMSESet2 = dtiErrorALDIT(params);
%}
%{
    clear params; 
    params.session = 'Set 1';
    params.wmPercentile = 80; params.nSamples = 500;
    params.scatter = true; params.histogram = false;
    
    project  = st.search('project','project label exact','ALDIT');
    [localFile,RMSESet3] = st.runFunction('dtiErrorALDIT.m', ...
        'container type','project',...
        'container id', idGet(project),...
        'params',params);
%}

%% Start with initialization
p = inputParser;

p.addParameter('project','ALDIT',@ischar);
p.addParameter('session','Set 1',@ischar);
p.addParameter('wmPercentile',95,@isnumeric);
p.addParameter('nSamples',250,@isnumeric);
p.addParameter('scatter',false,@islogical);
p.addParameter('histogram',false,@islogical);

p.parse(varargin{:});

projectlabel      = p.Results.project;
sessionlabel      = p.Results.session;
wmPercentile = p.Results.wmPercentile;
nSamples     = p.Results.nSamples;
scatter      = p.Results.scatter;
histogram    = p.Results.histogram;

%% Open the Flywheel object
st = scitran('vistalab');

% Check that the required toolboxes are on the path
[~,valid] = st.getToolbox('aldit-toolboxes.json',...
    'project name','ALDIT',...
    'validate',true);

if ~valid
    error('Please install aldit-toolboxes.json toolboxes on your path'); 
end

%% Search for the session and acquisition

% List the Diffusion acquisitions in the first session
acquisitions = st.search('acquisition', ...
    'project label exact',projectlabel, ...
    'session label exact',sessionlabel,...
    'acquisition label contains','Diffusion',...
    'summary',true);

if isempty(acquisitions)
    fprintf('No acquisitions in project %s, session %s\n',projectlabel,sessionlabel);
    return;
end

%% Pull down the nii.gz, bvec and bval from the first acquisition

nAcquisitions = length(acquisitions);
nRMSE = zeros(1,nAcquisitions);
label = cell(1,nAcquisitions);

for ii=1:nAcquisitions
    
    % We group the diffusion data, bvec and bval into a dwi structure as
    % per vistasoft
    dwi = st.dwiLoad(idGet(acquisitions{ii}));
    
    % Check the download this way
    %  niftiView(dwi.nifti);
    %  mrvNewGraphWin; hist(double(dwi.nifti.data(:)),100);
    
    %% Write out a white matter mask
    wmProb = wmCreate(dwi.nifti,wmPercentile);
    niftiWrite(wmProb,'wmProb.nii.gz');
    % niftiView(wmProb);
    
    %% dtiError test
    
    [err, ~, ~, predicted, measured] = ...
        dtiError(dwi.files.nifti,'eType','dsig','wmProb','wmProb.nii.gz','ncoords',nSamples);
    
    label{ii} = acquisitions{ii}.acquisition.label;
    
    if histogram
        mrvNewGraphWin; hist(err,50); title(label{ii});
    end
    
    if scatter
        mrvNewGraphWin;
        plot(predicted(:),measured(:),'o');
        axis equal; identityLine(gca); grid on; title(label{ii});
        xlabel('predicted'); ylabel('measured');
    end
    
    % Normalized RMSE
    nRMSE(ii) = sqrt(mean((predicted(:)-measured(:)).^2))/mean(measured(:));
    
end

%% Always plot the bar graph.

% A reasonable bar graph summary of the normalized RMSE
mrvNewGraphWin;
[label,idx] = sort(label);
b = bar3(nRMSE(idx),0.3); zlabel('Normalized RMSE');
set(b,'FaceLighting','gouraud','EdgeColor',[1 1 1])
set(gca,'YTickLabel',label);
view([-64,23]);
title(sessionlabel)

end




