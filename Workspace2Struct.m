%Saves all the variables from the current workspace into a single structure array
%Author: Andres Gonzalez, 2012 (version 0.2)
%Modified slightly by Eli Bowen
%#########################################################################
%Sometimes you need to save the variables from your base workspace, but using "save" function will have them all stored individually so if you reload them into a new workspace it could be a mess, and some variables could be overwritten.
%With this function, you can save all of them into a struct array, and so they'll be nicely packaged and ready to be saved to a .mat file that, when reloaded, will be easy to identify.
%Example:
% a='LALALA'
% b=[1:12:258]
% c={'cell1', 'cell2', 'cell3'}
% d=768
% e=true(3)
% theworkspace=ws2struct();
% theworkspace = 
%     a: 'LALALA'
%     b: [1x22 double]
%     c: {'cell1'  'cell2'  'cell3'}
%     d: 768
%     e: [3x3 logical]
function [WStruct] = Workspace2Struct ()
    WSVARS = evalin('caller', 'who');
    for wscon = 1:size(WSVARS, 1)
        thisVar = evalin('caller', WSVARS{wscon});
        theWorkspace.(WSVARS{wscon}) = thisVar;
    end

    WStruct = theWorkspace;
end