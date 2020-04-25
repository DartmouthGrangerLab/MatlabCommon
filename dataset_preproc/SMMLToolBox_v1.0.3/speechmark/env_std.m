%  Envelope (instantaneous amplitude) of signal using of speech-appropriate parameters.
%  Syntax:	env = env_std(SIGNAL,RATE)
%  where:
% 	SIGNAL	= sampled acoustic signal of speech;
% 	RATE	= sampling rate [Hz]; 
% 	env		= envelope of SIGNAL: SIZE(env) = SIZE(SIGNAL).
% 
%  Notes:
%  1.If SIGNAL consists of a matrix, each column will be processed separately.
%  2.Frequencies > ~ 8kHz (thus, sampling rates > ~ 16kHz) are not appropriate for
% 	most speech and may be suppressed here.  
%  3.This function uses 'envelope' with a speech-appropriate window.  As such, it assumes
% 	that SIGNAL is a segment of a longer signal from the same speech source, and is
% 	representative of adjacent segments.  Therefore, 'env' at its ends will rise or fall 
% 	to its mean value, as the best estimate of the envelope in the adjacent segments.  
% 	In speech, this is typical of a word or smaller segment within an utterance.  If 
% 	SIGNAL is NOT expected to be a segment from such a source, it may be more appropriate 
% 	to use 'env0_std', which assumes that the source is silent in adjacent segments.  
% 	In speech, this would be typical of a complete utterance.
%  4.It is typical to use the envelope of the differentiated SIGNAL, although this is
% 	not performed here.  Thus, a typical call to this function would be:
% 		env = env_std(diff(ORIGINALSIGNAL),RATE).
% 	Notice that 'env' will be 1 sample shorter than ORIGINALSIGNAL in this case.
%  5.Any offset in SIGNAL can greatly affect 'env'.  The mean value is removed here; 
% 	however, it may be helpful to remove other very low frequencies in SIGNAL (e.g., 
% 	with 'hpfilt_std'), particularly those lower than ~ 10-30 Hz, before calling this 
% 	function; often, DIFF(SIGNAL) is appropriate anyway, and also accomplishes this 
% 	conveniently.
%  6.To plot 'env' on the same axes as SIGNAL, it is generally helpful to double 'env'.
%  7.In case of out-of-memory, 'env_std' will convert SIGNAL to single precision and generate a warning.
% 
%  See also: envelope, hpfilt_std, env0_std.
%
