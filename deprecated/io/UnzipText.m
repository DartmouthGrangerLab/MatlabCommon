% deprecated
function text = UnzipText(fileName, func)
    validateattributes(fileName, {'char'}, {'nonempty'}, 1);
    assert(endsWith(fileName, '.zip'));
    if ~exist('func', 'var') || isempty(func)
        func = @fileread;
    end
    if ~isa(func, 'function_handle')
        func = str2func(func);
    end

    [~,rawFileName,~] = fileparts(fileName);
    rawFileName = strrep(rawFileName, '.', '_');
    unzipDir = fullfile(ComputerProfile.CacheDir(), ['unziptext_',GetMD5(now, 'array', 'hex'),'_',rawFileName]);
    assert(~isfolder(unzipDir));

    fileNames = unzip(fileName, unzipDir);
    assert(numel(fileNames) == 1);

    text = func(fileNames{1});

    delete(fullfile(unzipDir, '*'));
    rmdir(unzipDir);
end