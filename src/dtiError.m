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
st = scitran('action', 'create', 'instance', 'scitran');
% 
%
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

%% Another way to search, but it takes a long time
fname = 'dtiInit_03-Oct-2016_21-17-04.zip';
clear srch
srch.path = 'analyses/files';
srch.files.match.name = fname;
files = st.search(srch);
dtiOutput = fullfile(dtiErrorRootPath,'local','dtiOutput.zip');
st.get(files{1},'destination',dtiOutput);
unzip(dtiOutput);

%%
[p,n,e] = fileparts(fname);
baseDir = fullfile(dtiErrorRootPath,'local',n);
bvecsFile = mrvFindFile('*.bvecs',baseDir)
bvecs = textread(bvecsFile);
bvalsFile = mrvFindFile('*.bvals',baseDir);
bvals = textread(bvalsFile);

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

