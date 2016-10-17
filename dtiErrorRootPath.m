function rootPath = dtiErrorRootPath()
% Determine path to root of the mrVista directory
%
%        rootPath = dtiErrorRootPath;
%
% This function MUST reside in the directory at the base of the directory
% structure
%
% Copyright Stanford team, mrVista, 2011

rootPath=which('dtiErrorRootPath');

rootPath= fileparts(rootPath);

return
