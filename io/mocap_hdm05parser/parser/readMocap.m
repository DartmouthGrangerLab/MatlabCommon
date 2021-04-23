% This code belongs to the HDM05 mocap database which can be obtained from the website http://www.mpi-inf.mpg.de/resources/HDM05 .
% Reads file formats ASF/AMC, BVH or C3D into [skel, mot] structure.
% Possible calls:
%   [skel,mot] = readMocap(ASFfile, AMCfile, frameRange, compute_quats, do_FK, use_TXT_or_BIN)
%   [skel,mot] = readMocap(BVHfile, frameRange, compute_quats, do_FK)
%   [skel,mot] = readMocap(C3Dfile, frameRange, generateSkel, skelFitMethod)
%                   where skelFitMethod can be 'ATS' (default), 'trans_heu', 'trans_opt' or 'none'.
%                   WARNING: If left empty, bone lengths will vary over time!
%   [skel,mot] = readMocap(MPIIfile)
% If you use and publish results based on this code and data, please cite the following technical report:
%   @techreport{MuellerRCEKW07_HDM05-Docu,
%     author = {Meinard M{\"u}ller and Tido R{\"o}der and Michael Clausen and Bernd Eberhardt and Bj{\"o}rn Kr{\"u}ger and Andreas Weber},
%     title = {Documentation: Mocap Database {HDM05}},
%     institution = {Universit{\"a}t Bonn},
%     number = {CG-2007-2},
%     year = {2007}
%   }
%
% THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
% KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
%modified by Eli Bowen 12/2020 for readability, to remove caching option, which takes tons of file space to save a second or two at most (if you load tons of mocap files, save them all together yourself)
function [skel,mot] = readMocap (skelfile, varargin)
    %% set defaults
    motfile = skelfile;
    range = [];
    compute_quats = true;
    do_FK = true;
    use_TXT_or_BIN = true;
    generateSkeleton = true;
    skelFitMethod = 'ATS';

    %% parse parameter list
    fileExtension = upper(skelfile(end-3:end));
    if strcmp(fileExtension, '.C3D')
        if nargin > 1, range = varargin{1}; end
        if nargin > 2, generateSkeleton = varargin{2}; end
        if nargin > 3, skelFitMethod = varargin{3}; end
        if isempty(skelFitMethod)
            skelFitMethod = 'ATS';
        end
    elseif strcmp(fileExtension, '.ASF')
        if nargin > 1, motfile = varargin{1}; end
        if nargin > 2, range = varargin{2}; end
        if nargin > 3, compute_quats = varargin{3}; end
        if nargin > 4, do_FK = varargin{4}; end 
        if nargin > 5, use_TXT_or_BIN = varargin{5}; end 
    elseif strcmp(fileExtension, '.BVH')
        if nargin > 1, range = varargin{1}; end
        if nargin > 2, compute_quats = varargin{2}; end
        if nargin > 3, do_FK = varargin{3}; end
    elseif strcmp(fileExtension, 'MPII')
        % n/a
    else
        error(['Unknown file extension: ' fileExtension]);
    end

    %% delegate to parser
    t = tic();
    switch (fileExtension)
        case '.BVH'
            [skel,mot] = readBVH(skelfile, range, compute_quats, do_FK);
        case '.ASF'
            skel = readASF(skelfile);
            mot = readAMC(motfile, skel, range, compute_quats, do_FK, use_TXT_or_BIN);
            mot.Labels = {};
            mot.Data = {};
        case '.C3D'
            [Markers,VideoFrameRate,AnalogSignals,AnalogFrameRate,Event,ParameterGroup,CameraInfo,ResidualError] = readC3D(skelfile);
            %[skel,mot] = convertC3D_to_skelMot(Markers, ParameterGroup, VideoFrameRate, skelfile, generateSkeleton);
            [skel,mot] = convertC3D_to_skelMot(Markers, ParameterGroup, VideoFrameRate, skelfile);
            %[skel,mot] = convertC3D_to_skelMot_NEFF_dirty(Markers, ParameterGroup, VideoFrameRate, skelfile);
        case 'MPII'
            [skel,mot] = readMPII(skelfile);
    end
    disp(['read mocap file ',motfile,' in ',num2str(toc(t), '%.3f'),' s']);

    if strcmp(fileExtension, '.C3D')
        if generateSkeleton % generate skeleton if needed
            [skel,mot] = generateSkel(skel, mot);
            if ~strcmpi(skelFitMethod, 'none')
                switch(upper(skelFitMethod))
                    case 'ATS'
                        mot = skelfitATS(mot);
                    case 'TRANS_HEU'
                        mot = skelfitH(mot, 'boneNumbers', 0.15);
                    case 'TRANS_OPT'
                        mot = skelfitOptT(mot);
                    otherwise
                        error('Unknown skelfit method!');
                end
            end
        end
    end
    
    %% add useful metadata
    for i = 1:numel(skel) % for each skeleton in the scene
        [~,fileNameNoExt,~] = fileparts(skel(i).filename);
        skel(i).id = [strrep(lower(fileNameNoExt), '_', '-'),'_',num2str(i)]; % add an id field so we can find it again later
    end
end
