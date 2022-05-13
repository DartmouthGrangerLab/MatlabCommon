% mot = readAMC(filename,skel,range,compute_quats,do_FK,use_TXT_or_BIN)
% modified by Eli Bowen 12/2020 for readability, bringing some functions in as local
function [mot] = readAMC (varargin)
    switch (nargin)
        case 2
            filename = varargin{1};
            skel = varargin{2};
            range = [-inf inf];
            compute_quats = true;
            do_FK = true;
            use_TXT_or_BIN = true;
        case 3
            filename = varargin{1};
            skel = varargin{2};
            range = varargin{3};
            compute_quats = true;
            do_FK = true;
            use_TXT_or_BIN = true;
        case 4
            filename = varargin{1};
            skel = varargin{2};
            range = varargin{3};
            compute_quats = varargin{4};
            do_FK = true;
            use_TXT_or_BIN = true;
        case 5
            filename = varargin{1};
            skel = varargin{2};
            range = varargin{3};
            compute_quats = varargin{4};
            do_FK = varargin{5};
            use_TXT_or_BIN = true;
        case 6
            filename = varargin{1};
            skel = varargin{2};
            range = varargin{3};
            compute_quats = varargin{4};
            do_FK = varargin{5};
            use_TXT_or_BIN = varargin{6};
        otherwise
            error('wrong number of arguments');
    end

    mot = emptyMotion;

    %%%%%%%%%%%%%% open AMC file
    cl1 = clock;
    fid = fopen(filename, 'rt');
    if fid ~= -1
        mot.njoints    = skel.njoints;
        mot.jointNames = skel.jointNames;
        mot.boneNames  = skel.boneNames;
        mot.nameMap    = skel.nameMap;
        mot.animated   = skel.animated;
        mot.unanimated = skel.unanimated;    
        mot.angleUnit  = skel.angleUnit;
        
        idxBackSlash = findstr(filename, '\');
        if ~isempty(idxBackSlash)
            mot.filename = filename(idxBackSlash(end)+1:end);
        else
            mot.filename = filename;
        end

        mot = readSamplesPerSecond(mot, fid);

        if use_TXT_or_BIN
            h = fopen([filename,'.BIN'], 'r'); % first try to read compact BIN version of the file
            if h > 0 % does compact BIN file exist?
                [result,mot] = readFramesBIN(skel, mot, h, range);
            else
                h = fopen([filename,'.TXT'], 'r'); % try reading compact TXT version of the file
                if h > 0 % does compact TXT file exist?
                    [result,mot] = readFramesTXT(skel, mot, h, range);
                else
                    [result,mot] = readFrames(skel, mot, fid, range);
                end
            end
        else % don't use TXT or BIN format, resort to original AMC data
            [result,mot] = readFrames(skel, mot, fid, range);
        end

        fclose(fid);        
        if ~result
            error(['error reading frames from AMC file ',filename]);
        end
    else
        error('could not open AMC file');
    end
    t = etime(clock, cl1);
    disp(['read ',num2str(mot.nframes),' frames in ',num2str(t, '%.3f'),' s']);

    if compute_quats
    %%%%%%%% convert rotation data to quaternion representation
%         tic();
        mot = convert2quat(skel, mot);
%         disp(['converted motion data in ',num2str(toc(), '%.3f'),' s']);
    end

    %%%%%%%%%%%%%%%%%% forward kinematics
    if do_FK
%         tic();
        if compute_quats
            mot.jointTrajectories = forwardKinematicsQuat(skel, mot);
        else
            mot.jointTrajectories = forwardKinematicsEuler(skel, mot);
        end
%         disp(['computed joint trajectories in ',num2str(toc(), '%.3f'),' s']);

        %%%%%%%%%%%%%%%%%%%%%% bounding box
        mot.boundingBox = computeBoundingBox(mot);
    end
end


function [mot] = readSamplesPerSecond (mot, fid)
    pos = ftell(fid);
    [result,lin] = findNextASFSection(fid);
    if ~result
        return; % SAMPLES-PER-SECOND is optional!
    end

    [token,lin] = strtok(lin);
    token = token(2:end); % remove leading colon
    if ~strcmpi(token, 'SAMPLES-PER-SECOND')
        fseek(fid, pos, 'bof');
        return; % UNITS are optional!
    end

    [token,lin] = strtok(lin);
    mot.samplingRate = str2double(token); % eli converted from str2num to str2double
    mot.frameTime = 1 / mot.samplingRate;

    fseek(fid, pos, 'bof');
end