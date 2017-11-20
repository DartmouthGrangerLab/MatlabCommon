%Eli Bowen
%11/12/2017
%bulk render .fig files to .pngs
%INPUTS:
%   folderPath - path of the folder (e.g. result of fullfile()) - all .fig files within this folder will be rendered as .pngs
%   resolution - OPTIONAL - integer pixels per inch, basically. default = 150.
function [] = ConvertFigs2Png (folderPath, resolution)
    if ~exist('resolution', 'var') || isempty(resolution)
        resolution = 150;
    end
    
    dirStructArr = dir(folderPath);
    
    assert(~isempty(dirStructArr), 'can''t find any files in the folder!');
    
    for i = 1:numel(dirStructArr)
        if ~isempty(regexp(dirStructArr(i).name, '.fig$', 'ONCE'))
            disp(['processing ',dirStructArr(i).name,'...']);
            fileName = fullfile(folderPath, dirStructArr(i).name);
            openfig(fileName, 'invisible');
            h = gcf();
            print(h, regexprep(fileName, '.fig$', '.png'), '-dpng', ['-r',num2str(resolution)]);
            close(h);
        end
    end
    disp('DONE');
end