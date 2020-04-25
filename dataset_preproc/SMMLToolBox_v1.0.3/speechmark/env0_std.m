%  Envelope (instantaneous ampl.) of signal in silence, using speech-appropriate parameters.
%  Syntax:	env0 = env0_std(SIGNAL,RATE)
%  where:
% 	SIGNAL	= sampled acoustic signal of speech;
% 	RATE	= sampling rate [Hz]; 
% 	env0	= envelope of SIGNAL, assuming silence before & after SIGNAL: 
% 			SIZE(env) = SIZE(SIGNAL).
% 
%  Notes:
%  1.If SIGNAL consists of a matrix, each column will be processed separately.
%  2.Frequencies > ~ 8kHz (thus, sampling rates > ~ 16kHz) are not appropriate for
% 	most speech and may be suppressed here.
%  3.This function uses 'envelope0' with a speech-appropriate window.  As such, is assumes
% 	that SIGNAL is a segment of a longer signal from the same source, which is assumed to 
% 	be SILENT in adjacent segments.  (I.e., the signal value in such adjacent segments 
% 	is assumed to equal zero.)  Therefore, 'env0' at its ends will fall to zero.  
% 	In speech, this would be typical of a complete utterance.  If SIGNAL is NOT expected 
% 	to be such a segment, it may be more appropriate to use 'env_std', which assumes that 
% 	the source continues in adjacent segments, and that SIGNAL is representative of those 
% 	segments.  In speech, this would be typical of words or smaller segments within an 
% 	utterance.
%  4.It is typical to use the envelope of the differentiated SIGNAL, although this is
% 	not performed here.  Thus, a typical call to this function would be:
% 		env0 = env0_std(diff(ORIGINALSIGNAL),RATE).
% 	Notice that 'env0' will be 1 sample shorter than ORIGINALSIGNAL in this case.
%  5.Any offset in SIGNAL can greatly affect 'env0'.  The mean value is removed here; 
% 	however, it may be helpful to remove other very low frequencies in SIGNAL (e.g., 
% 	with 'hpfilt_std'), particularly those lower than ~ 10-30 Hz, before calling this 
% 	function; often, differentiation is appropriate anyway, and also accomplishes this 
% 	conveniently.
%  6.To plot 'env0' on the same axes as SIGNAL, it is generally helpful to use '2*env0'.
%  7.In case of out-of-memory, 'env_std' will convert SIGNAL to single precision and generate a warning.
% 
%  See also: envelope0, hpfilt_std, env_std.
%
