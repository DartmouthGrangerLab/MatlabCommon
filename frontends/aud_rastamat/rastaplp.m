%[cepstra, spectra, lpcas] = rastaplp(samples, sr, dorasta, modelorder)
%
% cheap version of log rasta with fixed parameters
%
%INPUTS:
%	sr is sampling rate of samples, defaults to 8000
%	dorasta defaults to 1; if 0, just calculate PLP
%	modelorder is order of PLP model, defaults to 8.  0 -> no PLP
%   wintime - window size in seconds
%   steptime - step size in seconds
%RETURNS:
%   output is matrix of features, row = feature, col = frame
%
% rastaplp(d, sr, 0, 12) is pretty close to the unix command line
% feacalc -dith -delta 0 -ras no -plp 12 -dom cep ...
% except during very quiet areas, where our approach of adding noise
% in the time domain is different from rasta's approach
%
% 2003-04-12 dpwe@ee.columbia.edu after shire@icsi.berkeley.edu's version
%Downloaded by Eli Bowen 2/6/2018 from https://labrosa.ee.columbia.edu/matlab/rastamat/ (modified to expose more params and for readibility)
function [cepstra,spectra,pspectrum,lpcas,F,M] = rastaplp (samples, sr, dorasta, modelorder, wintime, steptime)
    if nargin < 2
        sr = 8000;
    end
    if nargin < 3
        dorasta = 1;
    end
    if nargin < 4
        modelorder = 8;
    end
    if nargin < 5
        wintime = 0.025;
    end
    if nargin < 6
        steptime = 0.010;
    end
    minfreq = 0;
    maxfreq = sr/2;
    
    % add miniscule amount of noise
    %samples = samples + randn(size(samples))*0.0001;
    
    % first compute power spectrum
    pspectrum = powspec(samples, sr, wintime, steptime);
    
    % next group to critical bands
    aspectrum = audspec(pspectrum, sr, ceil(hz2bark(sr/2))+1, 'bark', minfreq, maxfreq);
    nbands = size(aspectrum, 1);
    
    if dorasta ~= 0
        nl_aspectrum = log(aspectrum); %put in log domain
        ras_nl_aspectrum = rastafilt(nl_aspectrum); %next do rasta filtering
        aspectrum = exp(ras_nl_aspectrum); %do inverse log
    end
    
    % do final auditory compressions
    postspectrum = postaud(aspectrum, sr/2); % 2012-09-03 bug: was sr
    
    if modelorder > 0
        lpcas = dolpc(postspectrum, modelorder); %LPC analysis
        cepstra = lpc2cep(lpcas, modelorder+1); %convert lpc to cepstra
        [spectra,F,M] = lpc2spec(lpcas, nbands); %.. or to spectra
    else
        % No LPC smoothing of spectrum
        spectra = postspectrum;
        cepstra = spec2cep(spectra);
    end
    
    cepstra = lifter(cepstra, 0.6);
end