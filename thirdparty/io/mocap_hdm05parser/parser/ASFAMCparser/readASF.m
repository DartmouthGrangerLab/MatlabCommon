% skel = readASF(filename)
% modified by Eli Bowen 12/2020 for readability and to bring some functions local
function skel = readASF (filename)
    %%%%%%%%%%%%%% open ASF file
    fid = fopen(filename, 'rt');
    if fid ~= -1
        skel = emptySkeleton;

        idxBackSlash = findstr(filename, '\');
        if ~isempty(idxBackSlash)
            skel.filename = filename(idxBackSlash(end)+1:end);
        else
            skel.filename = filename;
        end

        if strncmp(skel.filename, 'TOM', 3) == 1
            % for the database of tomohiko assign another asf-filetype as
            % for the HDM05-ASF-filem because the tomokiko-files contain
            % different joints. The filetype is used in the constructNameMap
            % file where for the tomohiko asf-files a different name map has to
            % be constructed.
            skel.fileType = 'TOM.ASF';
        else
            skel.fileType = 'ASF';
        end

        [result1, skel] = readVersion(skel,fid);
        [result2, skel] = readName(skel,fid);
        [result3, skel] = readUnits(skel,fid);
        [result4, skel] = readDocumentation(skel,fid);
        [result5, skel] = readRootASF(skel,fid);
        [result6, skel] = readBonedata(skel,fid);
        [result7, hierarchy] = readHierarchyASF(fid);
        [result8, skel] = readSkin(skel,fid);
        if ~(result1 & result2 & result4 & result5 & result6 & result7)
            fclose(fid);
            error(['error parsing ASF file ',filename]);
        end

        fclose(fid);        
    else
        error(['could not open ASF file ',filename]);
    end

    %%%%%%%%% build skeleton data structure
    [result,skel] = constructSkeleton(skel, 1, hierarchy, 1); 
    assert(result, ['error constructing ASF skeleton topology from hierarchy data in ',filename]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % traverse kinematic chain to generate a minimal edge-disjoint path covering used in the rendering process
    skel = constructPaths(skel, 1, 1); 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % traverse kinematic chain filling in skel's "name" and "animated/unanimated" arrays
    skel = constructAuxiliaryArrays(skel, 1); 
    skel.animated = sort(skel.animated);
    skel.unanimated = sort(skel.unanimated);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    skel.nameMap = constructNameMap(skel);
end


function [result,skel] = constructSkeleton (skel, currentNode_id, hierarchy, currentHierarchyIndex)
    result = false;

    k = 2; % in an ASF file, k = 1 should be referring to currentNode, the parent of the child nodes to be inserted
    while (k <= size(hierarchy,2)) & ~isempty(hierarchy{currentHierarchyIndex,k}) % insert all child nodes
        childBoneName = hierarchy{currentHierarchyIndex,k};
        childBoneIndex = strmatch(upper(childBoneName), upper({skel.nodes.boneName}), 'exact');
        if length(childBoneIndex) > 1
            error(['ASF bone name "',childBoneName,'" is not unique']);
        end
        if length(childBoneIndex) < 1
            error(['ASF unknown bone "',childBoneName,'"']);
        end

        skel.nodes(currentNode_id).children = [skel.nodes(currentNode_id).children; childBoneIndex];
        skel.nodes(childBoneIndex).parentID = currentNode_id;

        % in which lines of the hierarchy data does the current child appear as a parent?
        childHierarchyIndex = strmatch(upper(childBoneName), upper({hierarchy{:,1}}), 'exact'); 

        if length(childHierarchyIndex) >= 1 % found one or more lines where current child appears as a parent.
            for m = 1:length(childHierarchyIndex)
                [result,skel] = constructSkeleton(skel, childBoneIndex, hierarchy, childHierarchyIndex(m));
            end
        end        

        k = k + 1;
    end

    result = true;
end


% traverse kinematic chain to generate a minimal edge-disjoint path covering used in the rendering process
function [skel,currentPath] = constructPaths (skel, currentNode_id, currentPath)
    %%%%%%%%%%%%% append current node to current path
    if isempty(skel.paths)
        p = [];
    else
        p = skel.paths{currentPath,1};
    end
    skel.paths{currentPath,1} = [p; currentNode_id];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    childCount = length(skel.nodes(currentNode_id).children);

    if childCount == 0 % this is a childless bone
        if size(skel.paths,1) == currentPath % no children at all AND current path nonempty => start new current path
        	currentPath = currentPath + 1;
        end
        return;
    end

    childCount = length(skel.nodes(currentNode_id).children);

    for k = 1:childCount
        if k > 1 % start a new path at a joint with more than one child
            if size(skel.paths, 1) == currentPath % current path is nonempty
                currentPath = currentPath + 1;
            end
            skel.paths{currentPath,1}(1) = currentNode_id;
        end
        [skel,currentPath] = constructPaths(skel, skel.nodes(currentNode_id).children(k), currentPath);
    end
end


% traverse kinematic chain filling in skel's "name" and "animated/unanimated" arrays
function [skel] = constructAuxiliaryArrays (skel, currentNode_id)
    if size(skel.nodes(currentNode_id).DOF) > 0
        skel.animated = [skel.animated; currentNode_id];
    else
        skel.unanimated = [skel.unanimated; currentNode_id];
    end

    if currentNode_id > 1 % leave the root alone!
        % Eli FYI: the original way creates a "root@hipjoint" node, but hipjoint is the name of the bone that comes out from root (i know...), so first name should be hipjoint@femur
        %   in other words, nodes must be named currentNode@child not parent@currentNode
        %   but this is complicated - instead, we'll go back later and use nameMap to revise these
        skel.nodes(currentNode_id).jointName = [skel.nodes(skel.nodes(currentNode_id).parentID).boneName,'@',skel.nodes(currentNode_id).boneName];
    end

    childCount = size(skel.nodes(currentNode_id).children, 1);
    if childCount <= 0 % for childless nodes, simply copy the existing joint/bone names into name arrays
        skel.jointNames{currentNode_id,1} = skel.nodes(currentNode_id).jointName;
        skel.boneNames{currentNode_id,1} = skel.nodes(currentNode_id).boneName;
        return;
    end

    for k = 1:childCount
        skel = constructAuxiliaryArrays(skel, skel.nodes(currentNode_id).children(k));
    end

    skel.jointNames{currentNode_id,1} = skel.nodes(currentNode_id).jointName;
    skel.boneNames{currentNode_id,1} = skel.nodes(currentNode_id).boneName;
end
