% Eli Bowen 3/2022
% INPUTS:
%   datasetName - (char) name of dataset
% RETURNS:
%   dataset - (struct) with fields:
%       .t      - n x d (table) dataset
%       .t_num  - n x d (table) dataset with categorical variables binarized (continuous variables unchanged)
%       .uniq_* - 1 x X (cell array of chars)
function [dataset] = LoadCredit(datasetName)
    validateattributes(datasetName, 'char', {'nonempty'});

    directory = fullfile(ComputerProfile.DatasetDir(), 'credit', datasetName);

    dataset = struct();
    if strcmp(datasetName, 'uci_credit_screening')
        dataset.t = readtable(fullfile(directory, 'crx.csv'));
        dataset.t.Properties.VariableNames = {'a1','a2','a3','a4','a5','a6','a7','a8','a9','a10','a11','a12','a13','a14','a15','a16_dv'};
        dataset.t.a9  = strcmp(dataset.t.a9, 't');
        dataset.t.a10 = strcmp(dataset.t.a10, 't');
        dataset.t.a12 = strcmp(dataset.t.a12, 't');
        dataset.t.a16_dv = strcmp(dataset.t.a16_dv, '+'); % make logical for simplicity
        dataset.uniq_a1  = {'a','b'};
        dataset.uniq_a4  = {'u','y','l','t'};
        dataset.uniq_a5  = {'g','p','gg'};
        dataset.uniq_a6  = {'c','d','cc','i','j','k','m','r','q','w','x','e','aa','ff'};
        dataset.uniq_a7  = {'v','h','bb','j','n','z','dd','ff','o'};
        dataset.uniq_a13 = {'g','p','s'};
        dataset.t_num = table();
        %TODO: dataset.t_num
    elseif strcmp(datasetName, 'uci_statlog_australian_credit')
        dataset.t = readtable(fullfile(directory, 'australian.csv'));
        dataset.t.Properties.VariableNames = {'a1_idx','a2','a3','a4_idx','a5_idx','a6_idx','a7','a8','a9','a10','a11','a12_idx','a13','a14','a15_dv'};
        dataset.t.a1_idx = dataset.t.a1_idx + 1;
        dataset.t.a8  = logical(dataset.t.a8);
        dataset.t.a9  = logical(dataset.t.a9);
        dataset.t.a11 = logical(dataset.t.a11);
        dataset.t.a15_dv = logical(dataset.t.a15_dv); % despite the description (says values should be 1,2), seems to be logical
        dataset.uniq_a1 = {'a','b'};
        dataset.uniq_a4 = {'p','g','gg'};
        dataset.uniq_a5 = {'ff','d','i','k','j','aa','m','c','w','e','q','r','cc','x'};
        dataset.uniq_a6 = {'ff','dd','j','bb','v','n','o','h','z'};
        dataset.uniq_a12 = {'s','g','p'};
        dataset.t_num = table();
        dataset.t_num.a1    = logical(dataset.t.a1_idx - 1); % it's 2 classes
        dataset.t_num.a2    = dataset.t.a2;
        dataset.t_num.a3    = dataset.t.a3;
        dataset.t_num.a4_p  = (dataset.t.a4_idx == 1);
        dataset.t_num.a4_g  = (dataset.t.a4_idx == 2);
        dataset.t_num.a4_gg = (dataset.t.a4_idx == 3);
        for i = 1 : numel(dataset.uniq_a5)
            dataset.t_num.(['a5_',dataset.uniq_a5{i}]) = (dataset.t.a5_idx == i);
        end
        for i = 1 : numel(dataset.uniq_a6)
            dataset.t_num.(['a6_',dataset.uniq_a6{i}]) = (dataset.t.a6_idx == i);
        end
        dataset.t_num.a7  = dataset.t.a7;
        dataset.t_num.a8  = dataset.t.a8;
        dataset.t_num.a9  = dataset.t.a9;
        dataset.t_num.a10 = dataset.t.a10;
        dataset.t_num.a11 = dataset.t.a11;
        dataset.t_num.a12_s = (dataset.t.a12_idx == StringFind(dataset.uniq_a12, 's', true));
        dataset.t_num.a12_g = (dataset.t.a12_idx == StringFind(dataset.uniq_a12, 'g', true));
        dataset.t_num.a12_p = (dataset.t.a12_idx == StringFind(dataset.uniq_a12, 'p', true));
        dataset.t_num.a13 = dataset.t.a13;
        dataset.t_num.a14 = dataset.t.a14;
    elseif strcmp(datasetName, 'uci_statlog_german_credit')
        dataset.t = readtable(fullfile(directory, 'german.txt'));
        dataset.t.Properties.VariableNames = {'a1','a2_duration','a3','a4','a5_creditscore','a6','a7','a8_percent','a9','a10','a11','a12','a13_age','a14','a15','a16_ncredits','a17','a18_ndependents','a19_hasphone','a20_isforeign','a21_dv'};
        dataset.t.a19_hasphone = strcmp(dataset.t.a19_hasphone, 'A192');
        dataset.t.a20_isforeign = strcmp(dataset.t.a20_isforeign, 'A201');
        dataset.t.a21_dv = logical(dataset.t.a21_dv - 1); % make logical for simplicity
        dataset.t_num = table();
        %TODO: t_num
    elseif strcmp(datasetName, 'kaggle_icl_loan_default_prediction')
        error('TODO');
    else
        error('unexpected datasetName');
    end
end