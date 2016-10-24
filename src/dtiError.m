function err = dtiError(dtiInitZip,parametersJSON)
% Find the RMSE between tensor and data from dtiInit output files
%
%     err = dtiError(zipDtiInit,jsonParameters)
%
% Example:
%
% scitranClient and vistasoft are required.
%
%   cd ../scitranApps/dtiError/
%   addpath(genpath(pwd))
%   chdir(fullfile(dtiErrorRootPath,'local'))
%   

%% For getting started, we go get an example from Flywheel

st = scitran('action', 'create', 'instance', 'scitran');

%% List all projects

% In this example, we use the structure 'srch' to store the search parameters.
% When we are satisfied with the parameters, we attach srch to the mean search
% structure, s, and then run the search command.

clear srch
srch.path = 'sessions/analyses';
srch.analyses.match.label = 'dtiInit';
srch.files.match.type = 'zip';
sessions = st.search(srch);
fprintf('Found %d sessions with dtiInit analyses.\n',length(sessions));

for ii=1:length(sessions)
    for jj=1:length(sessions{ii}.source.files)
        if strfind(sessions{ii}.source.files{jj}.name,'.zip')
            thisZip = sessions{ii}.source.files{jj}.name;
            disp(thisZip)
        end
    end
end

%% This takes a long time, but it is one of this thisZip results

% So we know we can find it.
fname = 'dtiInit_03-Oct-2016_21-17-04.zip';
[~,baseName,~] = fileparts(fname);
baseDir = fullfile(dtiErrorRootPath,'local');

clear srch
srch.path = 'analyses/files';
srch.files.match.name = fname;
files = st.search(srch);
dtiOutput = fullfile(baseDir,'dtiOutput.zip');
st.get(files{1},'destination',dtiOutput);
unzip(dtiOutput);

% New base directory for the DWI data
baseDir = fullfile(baseDir,baseName);

%% Identify and load the dwi and metadata files

% Ask LMP:  It seems to me that the 'aligned' files in this base directory
% are aligned to the T1.  
% Not sure if these in the base directory are the ones we want, or the
% trilin directory ones.
clear dwi
d = dir(fullfile(baseDir,'*aligned*.nii.gz'));
baseName = fullfile(baseDir,d.name);
exist(baseName,'file')
dwi = dwiLoad(baseName);
dwiPlot(dwi,'bvecs');

%% Read the b=0 file  

% Ask LMP:  We should probably be getting the b0 from the bin directory
% inside of dti31trilin.  But this is the idea.
d = dir(fullfile(baseDir,'*b0*.nii.gz'));
b0Name = fullfile(baseDir,d.name);
exist(b0Name,'file')

%% Check the alignment of different files

% It looks to me that these three b0 data sets differ a bit
% The first one is not even the same size.

% b=0 in the base directory
b0 = niftiRead(b0Name);
niftiView(b0);
dim = niftiGet(b0,'dim');
niftiView(b0,'slice',dim(3)/2);

% These two are the same size.
% But they differ in detail

% The b=0 data in the dti31trilin directory
b0TriName = fullfile(baseDir,'dti31trilin','bin','b0.nii.gz');
exist(b0TriName,'file')
b0Tri = niftiRead(b0TriName);
niftiView(b0Tri,'slice',round(dim(3)/3));

% The b=0 volume in the dwi file
dim = niftiGet(dwi.nifti,'dim');
niftiView(dwi.nifti,'slice',round(dim(3)/3));

% So, I am thinking that the trilin/bin b=0 is in the same coordinate frame
% as the dwi.nifti data in the root directory with '_aligned_trilin' in the
% title.
% If this is so, then we can use the trilin/bin b0 and the bvecs, bvals and
% dwi.nifti and tensors.nii.gz data.

% Plus, the tensor.nii.gz seems to match, too. Yippee!
tensorsName = fullfile(baseDir,'dti31trilin','bin','tensors.nii.gz');
exist(tensorsName,'file')
tensors = niftiRead(tensorsName);
d = tensors.data;
tensors.data = abs(squeeze(d(:,:,:,1,:)));
niftiView(tensors,'slice',round(dim(3)/3));


%% Read the tensors

% Why are the directories like this: dti<N>trilin?
% Can't we give the directory a reliable name?  We can always figure out N
% from the bvecs file.

% The predicted DWI data from the


%%  Other ways I have read and found files

% [p,n,e] = fileparts(fname);
% baseDir = fullfile(dtiErrorRootPath,'local',n);
% bvecsFile = dir('*.bvecs'); % mrvFindFile('*.bvecs',baseDir);
% fname = bvecsFile.name; exist(fname,'file'); bvecs = dlmread(fname);
% bvalsFile = dir('*.bvals'); % mrvFindFile('*.bvecs',baseDir);
% fname = bvalsFile.name; exist(fname,'file'); bvals = dlmread(fname);

% mrvFindFile('*.bvals',baseDir)

%%
tensorsFile = mrvFindFile('tensors.nii.gz',baseDir);
dt6Data = dtiLoadTensorsFromNifti(tensorsFile);
% coords = [40:44;40:44;40:44]';
[X,Y,Z] = meshgrid(40:44,40:44,40:44);
coords = [X(:), Y(:), Z(:)];

Q = dt6toQ(dt6Data,coords);
[V,D] = eig(reshape(Q(1,:),3,3))

%%
% These are the 6 dimensions of the quadratic form.
% We need to wrap them into a Q matrix, multiply them by the bvec data,
% which we have to get, and then stuff them back into a NIfTI file
Q = niTensors.data;

t = squeeze(Q(30,10,10,1,:));

dt6VECtoMAT(t)

%%  The raw data and the bvec data are

%%

