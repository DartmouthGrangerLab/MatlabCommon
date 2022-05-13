% Enforcing fixed bone lengths of skeleton. Implementation of proposal by
% Aguiar, Theobalt and Seidel in "Automatic Learning of Articulated Skeletons from 3D Marker Trajectories".
% mot_new = skelfit (mot)
%       mot = motion variable
% modified by Eli Bowen 12/20202 for readability and to bring skelfitATSrek and refitBone as local functions
function [mot_new] = skelfitATS (mot)
    skelTree = buildSkelTree(mot.nameMap);
    mot_new = mot;

    rootIdx = strmatch('root', skelTree(:,1));
    assert(~isempty(rootIdx), 'Could not find ''root''-joint in mot.nameMap!');

    mot_new = skelfitATSrek(mot, rootIdx, skelTree, []);
end


function [mot] = skelfitATSrek (mot, jointIdx, skelTree, parentJoints)
    childIdx = skelTree{jointIdx,2};

    for i = 1:length(childIdx)
        if ~ismember(childIdx(i), parentJoints)
            mot = refitBone(mot, jointIdx, childIdx(i));
            mot = skelfitATSrek(mot, childIdx(i), skelTree, [parentJoints jointIdx]);
        end
    end
end


% enforces fixed bone length for this bone over all frames of the animation
function mot = refitBone (mot, jointIdx1, jointIdx2)
    % determine desired length
    diffVect = mot.jointTrajectories{jointIdx2} - mot.jointTrajectories{jointIdx1};
    diffLen  = sqrt(dot(diffVect,diffVect));
    targetLength = mean(diffLen);

    % crop to length
    mot.jointTrajectories{jointIdx2} = mot.jointTrajectories{jointIdx1} + targetLength * (diffVect ./ [diffLen;diffLen;diffLen]);
end