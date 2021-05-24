% Eli Bowen
% 5/21/2021
% RETURNS
%   name - the username of whoever's running matlab
function [name] = NameOfUser ()
    userProfile = getenv('USERPROFILE');
    
    % get last folder in the above path
    [p,fname,ext] = fileparts(userProfile);
    name = strcat(fname, ext); % in case the folder name has a dot in it
end