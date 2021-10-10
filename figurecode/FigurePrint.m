% Eli bowen
% 10/7/2021
% INPUTS:
%   h - figure handle
%   outDir - (char) - file path
%   file - (char) - file name
%   paperSz - 1 x 2 (numeric) - size of the paper (in inches?)
%   dpi - scalar (int-valued numeric) - resolution (e.g. 300)
function [] = FigurePrint (h, outDir, file, paperSz, dpi)
    validateattributes(outDir, 'char', {'nonempty'});
    validateattributes(file, 'char', {'nonempty'});
    validateattributes(paperSz, 'numeric', {'nonempty','numel',2});
    validateattributes(dpi, 'numeric', {'nonempty','scalar','positive','integer'});

    set(h, 'PaperPosition', [0,0,paperSz(1),paperSz(2)]);

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    if endsWith(file, '.png')
        print(h, fullfile(outDir, file), '-dpng', ['-r',num2str(dpi)]);
    elseif endsWith(file, '.jpg') || endsWith(file, '.jpeg')
        print(h, fullfile(outDir, file), '-djpeg', ['-r',num2str(dpi)]);
    else % default to png, which is nice and lossless
        print(h, fullfile(outDir, [file,'.png']), '-dpng', ['-r',num2str(dpi)]);
    end
end