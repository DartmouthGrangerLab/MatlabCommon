% EXAMPLE Simple demo of the MFCC function usage.
%   This script is a step by step walk-through of computation of the
%   mel frequency cepstral coefficients (MFCCs) from a speech signal using the MFCC routine.
%
%   See also MFCC, COMPARE.
%   Author: Kamil Wojcicki, September 2011
%downloaded by Eli Bowen 2/6/2018 from https://www.mathworks.com/matlabcentral/fileexchange/32849-htk-mfcc-matlab (and edited only for readability)

% Define variables
Tw = 25;                % analysis frame duration (ms)
Ts = 10;                % analysis frame shift (ms)
alpha = 0.97;           % preemphasis coefficient
M = 20;                 % number of filterbank channels
C = 12;                 % number of cepstral coefficients
L = 22;                 % cepstral sine lifter parameter
LF = 300;               % lower frequency limit (Hz)
HF = 3700;              % upper frequency limit (Hz)
wav_file = 'sp10.wav';  % input audio filename

% Read speech samples, sampling rate and precision from file
[speech,fs] = audioread(wav_file);

% Feature extraction (feature vectors as columns)
[MFCCs,FBEs,frames] = mfcc(speech, fs, Tw, Ts, alpha, @hamming, [LF HF], M, C+1, L);

% Generate data needed for plotting
[Nw,NF] = size(frames);                 % frame length and number of frames
time_frames = [0:NF-1]*Ts*0.001+0.5*Nw/fs;  % time vector (s) for frames
time = [ 0:length(speech)-1 ]/fs;           % time vector (s) for signal samples
logFBEs = 20*log10( FBEs );                 % compute log FBEs for plotting
logFBEs_floor = max(logFBEs(:))-50;         % get logFBE floor 50 dB below max
logFBEs( logFBEs<logFBEs_floor ) = logFBEs_floor; % limit logFBE dynamic range

% Generate plots
figure();

subplot(2, 1, 1);
imagesc( time_frames, [1:M], logFBEs );
axis( 'xy' );
xlim( [ min(time_frames) max(time_frames) ] );
xlabel( 'Time (s)' );
ylabel( 'Channel index' );
title( 'Log (mel) filterbank energies');

subplot(2, 1, 2);
imagesc( time_frames, [1:C], MFCCs(2:end,:) ); % HTK's TARGETKIND: MFCC
axis( 'xy' );
xlim( [ min(time_frames) max(time_frames) ] );
xlabel( 'Time (s)' );
ylabel( 'Cepstrum index' );
title( 'Mel frequency cepstrum' );

% Set color map to grayscale
colormap( 1-colormap('gray') );
