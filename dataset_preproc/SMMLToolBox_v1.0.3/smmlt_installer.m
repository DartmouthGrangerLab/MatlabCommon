% SpeechMark Toolbox installer script
%
up = userpath;
if ~isempty(up), up = up(1:end-1); end
% Ask user to enter the destination path
path = uigetdir(up,'Please select the installation path');

DIRNAME = 'SMMLToolBox';

if exist(fullfile(path,DIRNAME),'dir')==7,
    fprintf('Directory %s already exists!\n',DIRNAME);
    fprintf('Please remove existing directory before installing new version of toolbox\n');
    fprintf('or select another destination to install toolbox.\n');
    return;
end

disp('Installation in progress ...');

success = mkdir(path,DIRNAME);
if success, path = fullfile(path,DIRNAME); end

% unzip files to destination folder
unzip('Contents.zip',path); 
% Add the destination folder to MATLAB search path
addpath(fullfile(path,'speechmark'));
addpath(fullfile(path,'smdemos'));
addpath(path);
status = savepath;
if status
    fprintf('\nCouldn''t save path!\n');
    fprintf('When you are using SpeechMark, please add following directories to your matlab path\n');
    fprintf('\n%s\n',fullfile(path,'speechmark'));
    fprintf('%s\n',fullfile(path,'smdemos'));
    fprintf('%s\n\n',path);
    fprintf('For convenience, you can add following lines to your ''startup.m''\n');
    fprintf('\naddpath(''%s'')\n',fullfile(path,'speechmark'));
    fprintf('addpath(''%s'')\n',fullfile(path,'smdemos'));
    fprintf('addpath(''%s'')\n\n',path);
end
% Display version number
disp('Installation finished!');
[ version, builddate ] = smmlt_version;
fprintf('SpeechMark Toolbox Version: %s\n', version);
fprintf('Build Date: %s\n', builddate);