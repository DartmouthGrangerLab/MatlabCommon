% Eli Bowen
% 12/14/2020
% wrapper around an AMC+ASF or c3d file parser from http://resources.mpi-inf.mpg.de/HDM05/
% because few datasets correctly reference asf files in their amc, we require that the dataset downloader make sure each asf's full filename minus extension is the *start* of each matching amc's filename
% see MatlabCommon/frontends/mocap_hdm05parser/animate/animate_showFrame.m for hints on how to *use* the return values
% INPUT:
%	path - folder or valid motion capture file
% RETURNS:
%   anim - 1 x N cell array
%       mocapAnims{i} is a more machine-readable, combined version of each scene - a single struct containing:
%           .nFrames  - scalar double - number of frames in the animation
%           .samplingRate - scalar double (hz)
%           .duration - scalar double (seconds)
%           .nodeName - 1 x nTotNodes cell - name of each node
%           .skelName - 1 x nTotNodes cell
%           .pos      - 3 x nTotNodes x nFrames double - [x,y,z] for each node
%           .line     - 2 x nTotLines double - index into node list ([start of line, end of line]) (assumed consistent set across frames - only their positions change)
%           .joint    - 3 x nTotJoints double - index into node list ([end of line 1, pivot point, end of line 2]) (assumed consistent set across frames - only their angles and positions change)
%   descriptors - 1 x N cell array of file descriptors
function [anim,descriptors] = GetMotionCaptures (path)
    [~,descriptors,mocapAnims] = Helper(path, {}, 0, {}, '');
%       mocapAnims{1,i} is one or more skeleton struct (1 unless there are two actors interacting in a single scene):
%           .njoints       - scalar numeric
%           .rootRotationalOffsetEuler - 3 × 1 double
%           .rootRotationalOffsetQuat  - 4 × 1 double
%           .nodes         - nJoints × 1 struct
%           .paths         - nPaths × 1 cell (each path is a connected set of lines)
%           .jointNames    - nJoints × 1 cell (I actually think this is nodeNames)
%           .boneNames     - nJoints × 1 cell
%           .nameMap       - ? × 3 cell
%           .animated      - ? × 1 double
%           .unanimated    - ? × 1 double
%           .filename      - char (full source file name including path and extension)
%           .version       - char, e.g. '1.10'
%           .name          - char, e.g. 'VICON'
%           .massUnit      - scalar numeric e.g. 1
%           .lengthUnit    - scalar numeric e.g. 0.45
%           .angleUnit     - char, e.g. 'deg'
%           .documentation - char or cell array (may be empty)
%           .fileType      - char, e.g. 'ASF'
%           .skin          - []
%       mocapAnims{2,i} is the matching motion information struct(s):
%           .njoints           - scalar numeric (better match skeleton)
%           .nframes           - scalar numeric
%           .frameTime         - scalar numeric (duration of a frame; 1 / samplingRate)
%           .samplingRate      - scalar numeric (hz)
%           .jointTrajectories - nJoints × 1 cell
%           .rootTranslation   - 3 × nFrames double
%           .rotationEuler     - nJoints × 1 cell (units of radians; https://en.wikipedia.org/wiki/Euler_angles; .rotationEuler{i} is a 3 x nFrames double ([x,y,z] i think); rotation order xyz i think)
%           .rotationQuat      - nJoints × 1 cell
%           .jointNames        - nJoints × 1 cell (may be empty) (I actually think this is nodeNames)
%           .boneNames         - nJoints × 1 cell (may be empty)
%           .nameMap           - ? × 3 cell
%           .animated          - ? × 1 double
%           .unanimated        - ? × 1 double
%           .boundingBox       - ? × 1 double
%           .filename          - char (full source file name including path and extension)
%           .documentation     - char or cell array (may be empty)
%           .angleUnit         - char, e.g. 'deg'
%           .Labels            - cell (may be empty or missing)
%           .Data              - ce.rotationEuler{i} is 3 x nFrames doublell (may be empty or missing)
    
    % now check for duplicates (e.g. same data in two file formats)
    for a = numel(descriptors):-1:1
        dupe = strcmp(descriptors{a}, descriptors);
        dupe(a) = false;
        dupeIdx = find(dupe);
        if any(dupe)
            disp(['removed duplicate entry ',mocapAnims{2,a}.filename,' - consider removing duplicate files from the path']);
            mocamAnims(:,a) = [];
            descriptors(a) = [];
        end
    end
    
    % compute a more machine-readable and vectorized version of each mocap
    anim = cell(1, size(mocapAnims, 2));
    for a = 1:numel(descriptors)
        skel = mocapAnims{1,a};
        mot  = mocapAnims{2,a};
        
        nTotNodes = 0; % constant across frames
        nTotLines  = 0; % constant across frames
        nTotJoints = 0; % constant across frames
        nFrames = mot(1).nframes;
        sampleRate = mot(1).samplingRate;
        for i = 1:numel(skel) % for each skeleton
            nPaths = size(skel(i).paths, 1); % a "path" is a connected set of lines / bones
            assert(nFrames == mot(i).nframes); % for now, not set up to handle skeletons that show up and leave at arbitrary times
            assert(sampleRate == mot(i).samplingRate);
            nNodes = 0;
            for j = 1:nPaths
                path = skel(i).paths{j};
                nNodes = max(nNodes, max(path));
                nTotLines  = nTotLines + numel(path) - 1;
                nTotJoints = nTotJoints + numel(path) - 2;
            end
            nTotNodes = nTotNodes + nNodes;
        end
        
        % path(j) is a pointer to a "node" - a *unique* point
        % NOTE: a node may have multiple points if it participates in multiple joints
        % skel.nameMap lists the pairwise connectivity between <lines> (I think)
        anim{a} = struct();
        anim{a}.nFrames  = nFrames;
        anim{a}.sampleRate = sampleRate;
        anim{a}.duration = nFrames / sampleRate; % in s
        anim{a}.nodeName = cell(1, nTotNodes); % name of each node
        anim{a}.skelName = cell(1, nTotNodes);
        anim{a}.pos      = zeros(3, nFrames, nTotNodes); % [x,y,z] for each node
        anim{a}.line     = zeros(2, nTotLines); % index into nodes ([start of line, end of line]) (assumed consistent set across frames - only their positions change)
        anim{a}.joint    = zeros(3, nTotJoints); % index into nodes ([end of line 1, pivot point, end of line 2]) (assumed consistent set across frames - only their angles and positions change)
        ndCount = 0; % node
        lnCount = 1; % line
        jtCount = 1; % joint
        for i = 1:numel(skel) % for each skeleton
            nNodes = 0;
            nPaths = size(skel(i).paths, 1); % a "path" is a connected set of lines / bones
            for j = 1:nPaths
                path = skel(i).paths{j};
                nNodes = max(nNodes, max(path));
                
                for k = 1:numel(path)
                    anim{a}.skelName{ndCount + path(k)} = skel(i).id;
                    if all(all(anim{a}.pos(:,:,ndCount + path(k)) == 0)) % if we're hitting this node for the first time
                        anim{a}.pos(:,:,ndCount + path(k)) = mot(i).jointTrajectories{path(k)};
                    else % same node may be hit by multiple paths
                        assert(all(all(anim{a}.pos(:,:,ndCount + path(k)) == mot(i).jointTrajectories{path(k)}))); % pos of node should be identical for each path it's mentioned in
                    end
                    if k > 1
                        anim{a}.line(:,lnCount) = ndCount + path([k-1,k]);
                        lnCount = lnCount + 1;
                    end
                    if k > 2
                        anim{a}.joint(:,jtCount) = ndCount + path([k-2,k-1,k]);
                        jtCount = jtCount + 1;
                    end
                end
            end
            
            if ~isempty(skel(i).jointNames)
                nodeName = skel(i).jointNames;
            elseif ~isempty(mot(i).jointNames)
                nodeName = mot(i).jointNames;
            else
                nodeName = repmat({''}, 1, nNodes);
            end
            % above is junky - readMocap has a bug that causes jointNames to be wrong (off by one)
            % instead, we use the industry-standard names, confusing as they are (the knee is named after the bone above the knee, etc)
            for j = 1:size(skel.nameMap, 1)
                nodeName{skel.nameMap{j,3}} = skel.nameMap{j,1};
            end
            
            if i == 1
                anim{a}.nodeName = nodeName(:)';
            else
                anim{a}.nodeName = [anim{a}.nodeName,nodeName(:)'];
            end
            
            ndCount = ndCount + nNodes;
        end
        
        % cleanup
        anim{a}.nodeName = strrep(anim{a}.nodeName, '_@_', '@'); % shortening a common pattern
        anim{a}.nodeName = strrep(anim{a}.nodeName, '_', '-'); % so we can use _ as a delimiter later
        if numel(unique(anim{a}.nodeName)) ~= numel(anim{a}.nodeName)
            error('currently, nodeName must be unique within an animation');
            %TODO: add skelName to the nodeName and we're good if that fixes it, otherwise err
        end
        anim{a}.pos = permute(anim{a}.pos, [1,3,2]); % for future efficiency, move frame number to the last dimension
    end
end


function [count,descriptors,mocapAnims] = Helper (path, mocapAnims, count, descriptors, append)
    listing = dir(path);
    for i = 1:numel(listing)
        if listing(i).isdir && ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            [count,descriptors,mocapAnims] = Helper(fullfile(path, listing(i).name), mocapAnims, count, descriptors, [append,'_',strrep(listing(i).name, '_', '-')]);
        end
    end
%     path = '/pdata/ebowen/MatlabCommon/frontends/mocap_hdm05parser/data';
%     [skel,mot] = readMocap(fullfile(path, 'HDM_dg.asf'), fullfile(path, 'HDM_dg_06-03_03_120.amc'));
%     [skel,mot] = readMocap(fullfile(path, 'HDM_dg_06-03_03_120.c3d'), [], false);
%     animate(skel, mot);
    asfList = {}; % first, load names of all asfs (skeletons), for laterpairing with motion files
    for i = 1:numel(listing)
        [~,fileNameNoExt,ext] = fileparts(listing(i).name);
        if ~listing(i).isdir && strcmpi(ext, '.asf')
            asfList = [asfList,{fileNameNoExt}];
        end
    end
    for i = 1:numel(listing)
        [~,fileNameNoExt,ext] = fileparts(listing(i).name);
        if ~listing(i).isdir && strcmpi(ext, '.amc') || strcmpi(ext, '.c3d') % || strcmpi(ext, '.bvh') || strcmpi(ext, '.mpii')
            compute_quats = true; % no idea whether true or false is better
            do_FK = true; % if true, compues mot.forwardTrajectories using "forward kinematics"
            try
                if strcmpi(ext, '.amc')
                    asfFile = '';
                    for j = 1:numel(asfList)
                        if startsWith(fileNameNoExt, asfList{j})
                            assert(isempty(asfFile), 'need to find 1 matching asf file, instead found several');
                            asfFile = asfList{j};
                        end
                    end
                    if isempty(asfFile) % try again without case sensitivity
                        for j = 1:numel(asfList)
                            if startsWith(fileNameNoExt, asfList{j}, 'IgnoreCase', true)
                                assert(isempty(asfFile), 'need to find 1 matching asf file, instead found 0 case-matched, >1 case-invarient matches');
                                asfFile = asfList{j};
                            end
                        end
                    end
                    use_TXT_or_BIN = true; % no idea - keeping default
                    [skel,mot] = readMocap(fullfile(path, [asfFile,'.asf']), fullfile(path, listing(i).name), [], compute_quats, do_FK, use_TXT_or_BIN);
                elseif strcmpi(ext, '.c3d')
                    generateSkel = false;
                    skelFitMethod = 'ATS'; % can be 'ATS' (default), 'trans_heu', 'trans_opt' or 'none' (WARNING: if 'ATS', bone lengths will vary over time!)
                    [skel,mot] = readMocap(fullfile(path, listing(i).name), [], generateSkel, skelFitMethod);
                % below file types are probably fine - never tested them though
%                 elseif strcmpi(ext, '.bvh')
%                     [skel,mot] = readMocap(fullfile(path, listing(i).name), [], compute_quats, do_FK);
%                 elseif strcmpi(ext, '.mpii')
%                     [skel,mot] = readMocap(fullfile(path, listing(i).name));
                end
                mocapAnims{1,count+1} = skel;
                mocapAnims{2,count+1} = mot;

                descriptors{count+1} = strrep(lower(fileNameNoExt), '_', '-');
                if ~isempty(append)
                    descriptors{count+1} = [append,'_',descriptors{count+1}];
                end
                count = count + 1;
            catch ex
                disp(['error parsing [',listing(i).name,']:']);
                disp(ex.message);
            end
        end
    end
end