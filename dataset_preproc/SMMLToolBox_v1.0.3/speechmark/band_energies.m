%  Define & smooth several standard freq. bands of a speech signal over 50-msec sliding windows.
%    [bands,bandsf,bandrate,wdwlen] = band_energies(SIGNAL,RATE,<AGE>,<NOMED>,<FIGNO>,<NOISESPEC>):
%    SIGNAL  = acoustic speech signal to be processed;
%    RATE    = sampling rate [Hz] of SIGNAL;
%    <AGE>	= "CHILD" or other age/gender code will cause the band parameters to be set 
% 			accordingly; the default here is "CHILD" for compatibility with prior work;
% 	<NOMED>	= "nomed" [dflt., case-insensitive] to suppress s/gram median filtering across 
% 			times, or "med" to perform this; the filtering is slow but suppresses certain
% 			unlikely brief, non-speech noises that can introduce (e.g.) spurious landmarks;
% 	<FIGNO>	= figure number into which to plot 'bands' and 'bandsf':
% 				[] (the default) if none;
% 				0 for new figure;
% 				else number;
% 	<NOISESPEC> = power spectral density [dflt. = 0; linear units, not log!] vector to be 
% 				subtracted from all time-slices of the s/gram, uniformly sampled in 
% 				frequency from DC to RATE/2; 
% 			or a non-negative Real scalar to use a single value at all freq's.; 
% 			or the string 'sgest' (case-insensitive) to estimate it from the s/gram 
% 				itself with 'estnoisesgram'; see Notes;
%    bands, -f = coarse, fine smoothings of log(energy) [dB] in each frequency band,
% 			after subtraction of noise spectrum if specified;
%    bandrate = sampling rate of 'bands' & 'bandsf' (generally a sub-multiple of RATE);
%    wdwlen  = length of spectrogram window used to estimate energy; the first values 
% 			reflect energy centered in a window starting at the first sample, and of 
% 			'wdwlen' samples.
% 
%  Notes: 
%  1.The number of FFT signal samples used in the s/gram equals 'wdwlen'.
%  2.If NOISESPEC is given as an array, it will be resampled to cover the frequency range
% 	before subtracting.
%  3.Wherever the noise exceeds the signal power, the difference will be set to a
% 	tiny positive value.
%  4.The age/gender code (if not the default) must be one recognized by 'lm_bands_std'.
%  5.Energies are plotted (if at all) as their time derivatives, with 'plot_bandenergies'.  The
% 	time offset for plotting is 'wdwlen/2/RATE-.5/bandrate'.
%  6.The sounds that NOMED="med" suppresses are typically pure sliding tones with harmonics in
% 	in multiple broad bands.  (Possibly trombones?)  As descibed, these are rare.  Therefore,
% 	this choice is NOT the default; it is retained for backward compatibility.
% 
%  See also: sgram, smoothspecbands, estnoisesgram, lm_bands_std, plot_bandenergies.
%
