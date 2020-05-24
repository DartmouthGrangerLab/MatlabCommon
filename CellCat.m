%Eli Bowen
%5/22/2020
%assumes val is already the right size
%INPUTS:
%   cellData
%   sizeOfVal - OPTIONAL
function [val] = CellCat (cellData, sizeOfVal)
    if ~exist('sizeOfVal', 'var') || isempty(sizeOfVal)
        sizeOfVal = sum(cellfun(@numel, cellData(:)));
    end
    
    val = zeros(1, sizeOfVal);
    count = 1;
    for i = 1:numel(cellData)
        val(count:count+numel(cellData{i})-1) = cellData{i}(:)';
        count = count + numel(cellData{i});
    end
end