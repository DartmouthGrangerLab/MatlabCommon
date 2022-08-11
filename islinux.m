% Eli Bowen 8/2022
% not sure why this isn't built in...
% RETURNS
%   tf - scalar (logical) true iff the OS is linux
function tf = islinux()
    tf = (isunix() && ~ismac());
end