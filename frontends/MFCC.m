%Eli Bowen
%2/27/2020
%wrapper around the rastamat library MFCC functionality (https://labrosa.ee.columbia.edu/matlab/rastamat/)
%INPUT:
%	data - PCM audio vector
%	Fs - sampling rate of the audio
%	windowSize - in units of number of SAMPLES (not ms)
%	stepSize - in units of number of SAMPLES (not ms)
function [data] = MFCC (data, Fs, windowSize, stepSize)
    % Convert to MFCCs very close to those genrated by feacalc -sr 22050 -nyq 8000 -dith -hpf -opf htk -delta 0 -plp no -dom cep -com yes -frq mel -filt tri -win 32 -step 16 -cep 20
    data = data .* 3.3752;
    data = melfcc(data, Fs, 'maxfreq', 8000, 'numcep', 20, 'nbands', 22, 'fbtype', 'fcmel', 'dcttype', 1, 'usecmp', 1, 'wintime', windowSize/Fs, 'hoptime', stepSize/Fs, 'preemph', 0, 'dither', 1);
    del = deltas(data);
    ddel = deltas(deltas(data, 5), 5); %double deltas are deltas applied twice with a shorter window
    data = [data;del;ddel]; %Composite, 39-element feature vector, just like we use for speech recognition
    data = data';
end
