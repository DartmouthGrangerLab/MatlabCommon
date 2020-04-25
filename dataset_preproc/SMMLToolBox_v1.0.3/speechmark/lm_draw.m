%  Plots a speech-acoustic signal and s/gram with its associated landmark array, in current figure.
%  Syntax:	lm_draw(<FIGNO>,SIGNALD,<Fs>,LMARRAY,<PCONT>,<ENV>,<PTIMES>,<ZCRH>,<BW>)
% 	<FIGNO>	= figure number (scalar: default = current figure), or 0 for new figure using 'stdfig';
% 	SIGNALD	= speech signal as processed (typically Differentiated, possibly HP-filtered);
% 			assumed to be a complete utterance (thus, only silence is assumed to be present
% 			beyond the end of SIGNALD); or a cell array of same (see Notes);
% 	<Fs>	= sampling rate of 'SIGNALD' [dflt = 16kHz].  Rates < 11kHz are likely to 
% 			produce unreliable landmarks; rates > 16kHz are unlikely to be better 
% 			than 16kHz.
%    LMARRAY	= 2xN array of landmarks (glottis, burst, sonorant, etc.: +g/-g, +b/-b, +s/-s)
%    		of SIGNALD, for some N >= 0; each landmark is denoted by a time & type (code);
% 			the codes are as in 'landmarks'; may be empty; may be a LM structure array;
% 			must be well formed;
% 	<PCONT>	= pitch-period track of 'signal', as from 'pitch_utt'; ignored if empty
% 			or missing; see PTIMES;
% 	<ENV>	= SIGNALD's amplitude-envelope (as from 'envelope'), sampled at Fs and smoothed 
% 			over intervals characteristic of speech (~ 50-100 msec); values within ~ 1/2 
% 			this distance of the ends of the signal are suspect and will not be plotted; 
% 			this is only plotted over SIGNALD, so ENV may be set to 0 on any intervals that 
% 			were suppressed during landmark processing (e.g., if smaller than some
% 			ignorability threshhold); ignored if missing or [];
% 	<PTIMES> = times at which PCONT is given (of exactly same length); if missing or 
% 			[], PCONT and voicing (with transitions in LMARRAY) will be assumed to be 
% 			sampled at 125 Hz (8 msec), with the first value at .008 sec;
% 	<ZCRH>	= 1/2 of SIGNALD's zero-crossing rate [Hz], sampled at Fs and smoothed over 
% 			intervals typical of speech; the maximum possible value is Fs/2;
% 	BW		= case-insensitive bandwidth name [dflt. = "nb"] for display of the spectrogram; 
% 			use either "nb" for narrow-band or "wb" for wide-band.  This must be the last
% 			input argument, although other inputs may be suppressed entirely (need not be []).
% 
%  Notes: 
%  1.The figure is not immediately displayed.  Use DRAWNOW to do this.
%  2.If ENV is supplied, it will be used (via 'lm_sylfilter') to determine too-weak syllables 
% 	and their LMs (via 'syl_lms'); these will be plotted with dotted line instead of solid.
%  3.If SIGNALD is a cell array, then ONLY the top part of the plot will be created (waveform and
% 	landmarks, no spectrogram), and it will be created in the CURRENT axes, as determined by GCA.
%  4.If necessary, this function will assume that SIGNALD is a complete utterance, rather than
% 	a segment of a longer but similar signal.  (This complete-utterenace assumption is the 
% 	same one that 'envelope0' and 'env0_std' make, in contrast to 'envelope' and 'env_std'.)
%  5.A landmark sequence is considered well formed if:
% 	(a) all landmarks are in increasing time-order, ans
% 	(b) any coinciding largyngeal landmarks (+-p, +-g) are listed with +p following the
% 	coinciding +g, and -p preceding the coinciding -g.
% 
%  See also: landmarks, pitch_utt, envelope, DRAWNOW, syl_lms, lm_sylfilter, stdfig, GCA,
% 			envelope0, env_std, env0_std.
%
