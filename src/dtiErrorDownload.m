%% Get the example data from Flywheel
%
% A dtiInit output zip file is stored in the local directory of this
% instance.  These are the data that we analyze in the header comments of
% dtiError.
%
% BW Vistasoft Team, 2016

%% Open the Flywheel connection

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

%%
clear srch
srch.path = 'analyses/files';
srch.files.match.name = 'dtiInit_03-Oct-2016_21-17-04.zip';
files = st.search(srch);

baseDir = fullfile(dtiErrorRootPath,'local');
dtiOutput = fullfile(baseDir,'dtiOutput.zip');
st.get(files{1},'destination',dtiOutput);
unzip(dtiOutput);

%%