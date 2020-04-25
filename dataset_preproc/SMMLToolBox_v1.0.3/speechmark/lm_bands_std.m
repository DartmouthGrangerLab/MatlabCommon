%  Produce the standard freq. bands for landmark speech-signal processing.
% 	Syntax:	bandlims = lm_bands_std(AGE)
%    <AGE>	= (case-insensitive) "ADULT" [default] or "CHILD" for the band parameters 
% 			for this age group; or the age/gender symbols:
% 				"M", "F", "N", "E" => "ADULT";
% 				"I", "C" => "CHILD";
% 	bandlims = Nx2 array of [lower; upper] frequencies [Hz], in increasing order.
% 
%  Notes:
%  1.Freq. bands are NOT necessarily disjoint.
%  2.It is generally advisable to remove low freq's. (< 75 is typical for adults).
% 	However, this is NOT necessarily reflected in the lowest freq. band, which might
% 	extend as far down as DC.  The function 'lm_hplim_std' returns the typ. high-pass limit.
%  3.The highest freq. band should be reduced to whatever the sampling rate dictates.
% 	For a sampling rate of R, this would be
% 			min(R/2, bandlims).
%  4.The age/gender symbols are intended to be similar to those accepted by (especially) 
% 	'maxf0_std'.  However, this is NOT guaranteed.
%  5.If AGE is not recognized, a warning (through 'warnmsg') is produced, and the default
% 	value is used.
% 
%  See also: band_energies, lm_hplim_std, warnmsg.
%
