% Example:
%
% scitranClient and vistasoft are required.
%
%   cd ../scitranApps/dtiError/
%   addpath(genpath(pwd))
%   chdir(fullfile(dtiErrorRootPath,'local'))
%
% Notes:
%
% * There are many different functions floating around, like dt6to33() and
% dt6toQ and dt6VECtoMAT.  We should say which ones we want, and write the
% code properly for the collection.
%
% * It appears that this code run on the dtiInit output also gets us a
% perfectly good tensor
%
% * The function dtiLoadTensorFromNifti
%  * Should be niftiReadTensor()
%  * Reorders the directions
%  * It seems that this works OK, as per the code at the bototm of this
%  file
%
% * The dtiInit produces a tensor file that seems OK
%   * tensorsFile = mrvFindFile('tensors.nii.gz',baseDir);
%   * dt6Data = dtiLoadTensorsFromNifti(tensorsFile);
%% For getting started, we go get an example from Flywheel

% st = scitran('action', 'create', 'instance', 'scitran');

%% List all projects

% In this example, we use the structure 'srch' to store the search parameters.
% When we are satisfied with the parameters, we attach srch to the mean search
% structure, s, and then run the search command.

% clear srch
% srch.path = 'sessions/analyses';
% srch.analyses.match.label = 'dtiInit';
% srch.files.match.type = 'zip';
% sessions = st.search(srch);
% fprintf('Found %d sessions with dtiInit analyses.\n',length(sessions));
%
% for ii=1:length(sessions)
%     for jj=1:length(sessions{ii}.source.files)
%         if strfind(sessions{ii}.source.files{jj}.name,'.zip')
%             thisZip = sessions{ii}.source.files{jj}.name;
%             disp(thisZip)
%         end
%     end
% end
% clear srch
% srch.path = 'analyses/files';
% srch.files.match.name = fname;
% files = st.search(srch);
% dtiOutput = fullfile(baseDir,'dtiOutput.zip');
% st.get(files{1},'destination',dtiOutput);
% unzip(dtiOutput);
%
%
% %% Read the b=0 file
%
% % Ask LMP:  We should probably be getting the b0 from the bin directory
% % inside of dti31trilin.  But this is the idea.
% d = dir(fullfile(baseDir,'*b0*.nii.gz'));
% b0Name = fullfile(baseDir,d.name);
% exist(b0Name,'file')
%
% %% Check the alignment of different files
%
% % It looks to me that these three b0 data sets differ a bit
% % The first one is not even the same size.
%
%
% % b=0 in the base directory
% b0 = niftiRead(b0Name);
% niftiView(b0);
% dim = niftiGet(b0,'dim');
% slice = round(dim(3)/3);
% niftiView(b0,'slice',slice);
%
% % These two are the same size.
% % But they differ in detail
%
% % The b=0 data in the dti31trilin directory
% b0TriName = fullfile(baseDir,'dti31trilin','bin','b0.nii.gz');
% exist(b0TriName,'file')
% b0Tri = niftiRead(b0TriName);
% dim = niftiGet(b0,'dim');
% slice = round(dim(3)/3);
% niftiView(b0Tri,'slice',slice);
%
% % The b=0 volume in the dwi file
% dim = niftiGet(dwi.nifti,'dim');
% dim = niftiGet(b0,'dim');
% slice = round(dim(3)/3);
% niftiView(dwi.nifti,'slice',slice);
%
% % So, I am thinking that the trilin/bin b=0 is in the same coordinate frame
% % as the dwi.nifti data in the root directory with '_aligned_trilin' in the
% % title.
% % If this is so, then we can use the trilin/bin b0 and the bvecs, bvals and
% % dwi.nifti and tensors.nii.gz data.
%
% % Plus, the tensor.nii.gz seems to match, too. Yippee!
% tensorsName = fullfile(baseDir,'dti31trilin','bin','tensors.nii.gz');
% exist(tensorsName,'file')
% tensors = niftiRead(tensorsName);
% d = tensors.data;
% tensors.data = abs(squeeze(d(:,:,:,1,:)));
% niftiView(tensors,'slice',round(dim(3)/3));

%% So, here is the calculation
%
% Read the dwiLoad() data
%
% Read the b0 in bin
% Read the tensors(i,j,k) in bin
%
% Calculate for all bvecs
%
%     ADC(i,j,k; bvec) = b0 * exp(-bval (bvec*tensor*bvec'))
%

%%  Other ways I have read and found files

% [p,n,e] = fileparts(fname);
% baseDir = fullfile(dtiErrorRootPath,'local',n);
% bvecsFile = dir('*.bvecs'); % mrvFindFile('*.bvecs',baseDir);
% fname = bvecsFile.name; exist(fname,'file'); bvecs = dlmread(fname);
% bvalsFile = dir('*.bvals'); % mrvFindFile('*.bvecs',baseDir);
% fname = bvalsFile.name; exist(fname,'file'); bvals = dlmread(fname);

% mrvFindFile('*.bvals',baseDir)


% Sig = S0 * exp(-b*ADC)
% ADC = (bvec Q bvec')
% b = bvecs;  % Do not scale.  We scale when we compute diffusion.
%
% % Here is the big matrix
% V = [b(:,1).^2, b(:,2).^2, b(:,3).^2, 2* b(:,1).*b(:,2), 2* b(:,1).*b(:,3), 2*b(:,2).*b(:,3)];
%
% % Now, we divide the matrix V by the measured ADC values to obtain the qij
% % values in the parameter, tensor
% tensor = V\ADC;
% Q2 = dt6VECtoMAT(tensor);  % eigs(Q)
%
% % To compare the observed and predicted, do this
% ADCest = zeros(size(ADC));
% for ii=1:size(bvecs,1)
%     u = bvecs(ii,:);
%     ADCest(ii) = u(:)'*Q2*u(:);
% end
% mrvNewGraphWin; plot(ADC,ADCest,'o');
% grid on; identityLine(gca);
% dwiPlot(dwi,'adc',ADC,Q);
%
% %%
% Sig = squeeze(dwi.nifti.data(41,41,41,:));
% mrvNewGraphWin;
% plot(Sig(2:end));