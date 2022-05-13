% Eli Bowen
% loads the text file produced by running FAVE
% INPUTS
%   filePath - (char)
function fave = LoadFAVE(filePath)
    validateattributes(filePath, {'char'}, {'nonempty'}, 1);

    fileID = fopen(filePath, 'r');

    header = strsplit(fgetl(fileID), '\t', 'CollapseDelimiters', false);
    fave = struct();
    fave.vowel = {}; assert(strcmp(header{13}, 'vowel'));
    fave.stress = []; assert(strcmp(header{14}, 'stress'));
    fave.f1     = []; assert(strcmp(header{18}, 'F1'));
    fave.f2     = []; assert(strcmp(header{19}, 'F2'));
    fave.f3     = []; assert(strcmp(header{20}, 'F3'));
    fave.t      = []; assert(strcmp(header{24}, 't'));
    fave.beg    = []; assert(strcmp(header{25}, 'beg')); % in units of seconds
    fave.end    = []; assert(strcmp(header{26}, 'end')); % in units of seconds
    fave.dur    = []; assert(strcmp(header{27}, 'dur')); % in units of seconds
    fave.plt_vclass = {}; assert(strcmp(header{28}, 'plt_vclass'));
    fave.plt_manner = {}; assert(strcmp(header{29}, 'plt_manner'));
    fave.plt_place  = {}; assert(strcmp(header{30}, 'plt_place'));
    fave.plt_voice  = {}; assert(strcmp(header{31}, 'plt_voice'));
    fave.plt_preseg = {}; assert(strcmp(header{32}, 'plt_preseg'));
    fave.plt_folseq = {}; assert(strcmp(header{33}, 'plt_folseq'));
    fave.style      = {}; assert(strcmp(header{34}, 'style'));
    fave.glide      = {}; assert(strcmp(header{35}, 'glide'));
    fave.pre_seg    = {}; assert(strcmp(header{36}, 'pre_seg'));
    fave.fol_seg    = {}; assert(strcmp(header{37}, 'fol_seg'));
    fave.context    = {}; assert(strcmp(header{38}, 'context'));
    fave.vowel_index   = []; assert(strcmp(header{39}, 'vowel_index'));
    fave.f1At20Percent = []; assert(strcmp(header{43}, 'F1@20%'));
    fave.f2At20Percent = []; assert(strcmp(header{44}, 'F2@20%'));
    fave.f1At35Percent = []; assert(strcmp(header{45}, 'F1@35%'));
    fave.f2At35Percent = []; assert(strcmp(header{46}, 'F2@35%'));
    fave.f1At50Percent = []; assert(strcmp(header{47}, 'F1@50%'));
    fave.f2At50Percent = []; assert(strcmp(header{48}, 'F2@50%'));
    fave.f1At65Percent = []; assert(strcmp(header{49}, 'F1@65%'));
    fave.f2At65Percent = []; assert(strcmp(header{50}, 'F2@65%'));
    fave.f1At80Percent = []; assert(strcmp(header{51}, 'F1@80%'));
    fave.f2At80Percent = []; assert(strcmp(header{52}, 'F2@80%'));
    fave.nFormants     = []; assert(strcmp(header{53}, 'nFormants'));

    count = 1;
    while ~feof(fileID)
        text = strsplit(fgetl(fileID), '\t', 'CollapseDelimiters', false);
        assert(numel(text) == numel(header));

        fave.vowel{count} = text{13};
        fave.stress(count) = str2double(text{14});
        fave.f1(count)     = str2double(text{18});
        fave.f2(count)     = str2double(text{19});
        fave.f3(count)     = str2double(text{20});
        fave.t(count)      = str2double(text{24});
        fave.beg(count)    = str2double(text{25}); % in units of seconds
        fave.end(count)    = str2double(text{26}); % in units of seconds
        fave.dur(count)    = str2double(text{27}); % in units of seconds
        fave.plt_vclass{count} = text{28};
        fave.plt_manner{count} = text{29};
        fave.plt_place{count}  = text{30};
        fave.plt_voice{count}  = text{31};

        % I dunno what these mean
        fave.plt_preseg{count} = text{32};
        fave.plt_folseq{count} = text{33};
        fave.style{count}      = text{34};
        fave.glide{count}      = text{35};
        fave.pre_seg{count}    = text{36};
        fave.fol_seg{count}    = text{37};

        fave.context{count} = text{38};
        fave.vowel_index(count)   = str2double(text{39});
        fave.f1At20Percent(count) = str2double(text{43});
        fave.f2At20Percent(count) = str2double(text{44});
        fave.f1At35Percent(count) = str2double(text{45});
        fave.f2At35Percent(count) = str2double(text{46});
        fave.f1At50Percent(count) = str2double(text{47});
        fave.f2At50Percent(count) = str2double(text{48});
        fave.f1At65Percent(count) = str2double(text{49});
        fave.f2At65Percent(count) = str2double(text{50});
        fave.f1At80Percent(count) = str2double(text{51});
        fave.f2At80Percent(count) = str2double(text{52});
        fave.nFormants(count)     = str2double(text{53});
        count = count + 1;
    end
    fclose(fileID);
end