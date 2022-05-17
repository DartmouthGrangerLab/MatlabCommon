% deprecated
function [] = Diary(path, file)
    validateattributes(path, {'char'}, {'nonempty'}, 1);
    validateattributes(file, {'char'}, {'nonempty'}, 2);
    assert(endsWith(file, '.txt'));

    if ~isfolder(path)
        mkdir(path);
    end

    if isfile(fullfile(path, file))
        delete(fullfile(path, file));
    end
    diary(fullfile(path, file));
end