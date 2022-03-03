% INPUTS:
%   data - vector of data points to test
%   nanflag - OPTIONaL (same as built-in std or mean functions) if set to 'omitnan', neither stddev nor sqrt(N) will consider NaN points!
% RETURNS:
%   stdErr
function [stdErr] = StdErr(data, nanflag)
    if ~exist('nanflag', 'var') || isempty(nanflag) || strcmp(nanflag, 'includenan')
        if sum(size(data)>1) > 1 % just to be clear
            assert(ismatrix(data));
            stdErr = std(data, 0, 1) ./ sqrt(size(data, 1));
        else
            stdErr = std(data, 0) / sqrt(numel(data));
        end
    else
        assert(strcmp(nanflag, 'omitnan'));
        if sum(size(data)>1) > 1 % just to be clear
            assert(ismatrix(data));
            stdErr = std(data, 0, 1, 'omitnan');
            for i = 1 : numel(stdErr)
                stdErr(i) = stdErr(i) / sqrt(size(data, 1)-sum(isnan(data(:,i))));
            end
        else
            stdErr = std(data, 0, 'omitnan') / sqrt(numel(data)-sum(isnan(data)));
        end
    end
end