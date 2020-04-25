function hpsig = hpfilt_std(SIGNAL,RATE,AGE)
% High-pass filter of signal, using speech-appropriate parameters.
% Syntax:	hpsig = hpfilt_std(SIGNAL,RATE,<AGE>)
% where:
%	SIGNAL	= sampled acoustic signal of speech;
%	RATE	= sampling rate [Hz]; 
%   <AGE>	= age label ("ADULT" or "CHILD") for the freq. limit for this age group,
%			as used by 'lm_hplim_std';
%	hpsig	= high-pass filtered version of SIGNAL, using 'lm_hplim_std'; SIZE(env) = 
%			SIZE(SIGNAL).
%
% Notes:
% 1.If SIGNAL consists of a matrix, each column will be processed separately.
% 2.The high-pass cutoff frequency is likely to be > 60 Hz.  However, the attenuation at
%	somewhat lower frequencies may be modest.  This, any 60-Hz contamination should be 
%	explicitly removed.  For example, use:
%		smooth(SIGNAL,kernel_no60_std(RATE)) .
%	Note that this operation may be performed either before or after the current one,
%	equivalently.
% 3.Nonlinear dynamics may occur at lower frequencies than the cutoff used here.  However,
%	these are generally NOT affected by this filtering (because they are carried as well
%	by the amplitude and other nonlinear signals related to SIGNAL, not only by the
%	linear components).
% 4.The mean value may not be specifically removed here, although it will be attenuated.
%
% See also: smooth, kernel_no60_std, lm_hplim_std.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/9/30	Small addition to "?" processing (ONLY).
%   RP  14/9/19 Name change std_hpfilt -> hpfilt_std.
%   RP  14/9/22 Apply name change from std_* to *_std. Also, reflact name changes in doc.

if nargin == 1 && isequal(SIGNAL,'?'),
    fprintf('%s\n','hpsig = hpfilt_std(SIGNAL,RATE,<AGE>)')
	% 08/9/30: Added (2 lines):
		fprintf('\tbased on:\n')
		lm_hplim_std ? % 14/9/22 std_lm_hplim -> lm_hplim_std
    return
end

if nargin < 3, AGE = ''; end
% Remove all suff. low freq's., each column separately:
hpsig = desmooth(SIGNAL,-(1+2*round(RATE/lm_hplim_std(AGE)))); % 14/9/22 Apply name change
	% >> SIZE(hpsig) = SIZE(SIGNAL). <<
