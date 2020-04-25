%  Real signal's estimated stationary background ("noise") spectrum from its s/gram, using only rank filters.
%  Syntax:	nspec = estnoisesig(SIGNAL,NFREQ)
%  where:
% 	SIGNAL	= the (Real-valued) signal to be analyzed;
% 	NFREQ	= number of (uniformly spaced) frequencies at which to eval. the noise spectrum;
% 			SIGNAL must be ~ 10-20x longer than NFREQ, or more;
% 	nspec	= ROW-vector of the estimated power spectrum of the "noise", that is, of the 
% 			stationary part of the signal (present at all times); evaluated at NFREQ 
% 			frequencies; an estimate of overall noise power is given by 2*SUM(nspec), or, 
% 			more carefully, by SUM(nspec([1 end])) + 2*SUM(nspec(2:end-1)).
% 
%  Example:
% 	>> ns = estnoisesig(12*randn(1,1e5),1025)
% 	assigns 'ns' the (essentially white) spectrum of this all-noise signal.  The mean value 
% 	of 'ns' is 12^2 (on average), the mean power in a white, Normal random variable having
% 	an amplitude of 12.  'ns' has size 1x1025, with each frequency's estimate computed from 
% 	2048 samples, 'ns(1)' = DC noise power, and 'ns(end)' = noise at half of sampling rate.  
% 	The full (two-sided) spectrum, with DC at the center+1 position, equals 
% 	'[ns(end-1:-1:2) ns]'.
% 
%  Notes:
%  1.The basic insight: The stationary part of the signal -- "Noise" -- is an independent, 
% 	additive component of the signal and provides the floor to the expectation value of the 
% 	power in each spectrogram slice or frame.  Thus, the noise spectrum at each frequency is 
% 	approximately the smallest value of the power at that frequency, across all time-slices 
% 	of the spectrogram.  (This is not true in detail, however, and this function manages the
% 	complications.  Specifically, the minimum across time will usually have unrealistically 
% 	low values.  The use of rank filters prevents these unrealistic values from dominating 
% 	the result, 'nspec'.)
%  2.Any all-0 or constant segments at the beginning and end of SIGNAL are removed.  However, 
% 	from Note #1, any "non-signal" segments, such as completely silent intervals (e.g., 
% 	line-level DC or quantization noise) at the beginning or end of recorded data, should 
% 	be removed before processing.  The function 'estnoisesig_std' handles this case.  If 
% 	the signal is speech-like (and possibly if it is not), then the function 'nonquiet' 
% 	or 'deg_speechenv' may be helpful for this; for example, if no similarly silent 
% 	intervals occur during the recorded segment, then:
% 		>> dspe = deg_speechenv(SIGNAL, R);	-- where "R" is the sampling rate of SIGNAL.
% 		>> ests = estnoisesig( SIGNAL(find(dspe>0.1,1) : find(dspe>0.1,1,'last')), NFREQ);
% 	will compute the noise spectrum over the appropriate interval, provided that the remaining
% 	interval is long enough.
%  3.Freq's. in 'nspec' will be uniformly spaced from DC to 1/2 of the sampling rate.  Thus, 
% 	NFREQ is conventionally an odd number (in fact, 1 + 2^N for some "N"), although this is 
% 	not required.
%  4.The noise 'nspec' is measured in linear power (like SIGNAL.^2), NOT logarithmic.
%  5.The mean of 'nspec' is an estimate of the noise power in SIGNAL.  
%  6.The noise is estimated independently at each frequency.  If NFREQ is higher than
% 	needed, it may be helpful to "smooth" 'nspec'.  The function 'medfilt1e' (another
% 	rank filter) is likely to be most appropriate for this, unless detailed information 
% 	about the noise source and future uses of 'nspec' is available.
%  7.It often happens that, despite best efforts in this function, the result has unrealistic
% 	dips at isolated frequencies.  To remedy this, consider an expression that uses 
% 	estimates at adjacent frequencies, such as
% 		max(nspec, medfilt1(nspec,3))
% 	which (like this function) uses only order statistics: MAX and a rank filter.  
% 	-	This expression introduces an upward bias, which should be offset by reducing all
% 	of 'nspec' by an appropriate amount.  For a white-noise signal of unit power, this 
% 	expression raises the expectation value from 1 to 1.09, or to 1.10 if 'nspec([1 end])'
% 	are omitted [see Note 12], so all estimates should be reduced by this factor; using 
% 	9 instead of 3 adjacent samples raises it to 1.10 (1.12 if the ends are omitted).
% 	-	The expression reduces the expected standard deviation from 29% to 24% (3 samples)
% 	or 21% (9 samples), whether or not the ends are omitted.  
% 	-	However, it properly raises the (often more troublesome) MIN from 21% of the 
% 	mean to 34% for both 3 AND 9 samples; omitting the ends produces estimates of 34%, 
% 	raised to 48% (3 samples) or 72% (9 samples).  Thus, unrealistic dips tend to be 
% 	very well removed.  For comparison, the simpler expression
% 		medfilt1e(nspec,3)
% 	does not change the expectation value (to within 1% of the mean), and reduces the 
% 	expected S.D. from 29% of the signal power to 20%; using 9 instead of 3 adjacent 
% 	frequencies reduces the S.D. still further, to 12%.  These values are not changed (to 
% 	within 1%) by omitting the first and last values of the estimated spectrum.  However, 
% 	this expression will also remove narrow peaks, which it may be important to preserve 
% 	in the "noise" spectrum.  This expression raises the minimum exactly as much as 
% 	'max(nspec, medfilt1(nspec,3))'.
%  8.Mathematical analysis:
% 	For a given SIGNAL, the power in a noise estimate scales with NFREQ.  Thus,
% 		estnoisesig(SIG,NFREQ) / (2*NFREQ-2)
% 	is independent of NFREQ (on average, unless the noise has significant, narrow frequency 
% 	structure).  
% 		MEAN( SUM(abs2(sg),2) ) = SUM(abs2(SIGNAL)),
% 	or, for 
% 		"L" = LENGTH(SIGNAL), and 
% 		"k" = the number of time-slices, i.e., k = L /(2*(NFREQ-1)),
% 	the LHS becomes:
% 		MEAN( k * MEAN(abs2(sg),2) ), or k * MEAN( MEAN(abs2(sg),2) ), so that
% 		k * MEAN(abs2(sg(:))) = SUM(abs2(SIGNAL));
% 	i.e.,
% 		MEAN(abs2(sg(:))) /2 /(NFREQ-1) = SUM(abs2(SIGNAL)) / L = MEAN(abs2(SIGNAL)),
% 	which is a constant (with respect to NFREQ): Thus, the mean power spectrum (over 
% 	time-slices & freq's.) = 2*(NFREQ-1) times the mean squared signal.
% 	This should be compared to 'nspec' at each freq. index "f", which is (very approximately)
% 		MIN( abs2(sg(f,:)),[],2).
% 	To the extent that the noise power at each freq. is distributed as Chi-Squared[2], 
% 	independently in each time-slice, the minimum value (over time-slices), i.e., 'nspec(f)', 
% 	can be expected to be approx. (mean value) / k; that is,
% 		MIN( abs2(sg(f,:)),[],2) = MEAN(abs2(sg(f,:))) / k,
% 	and the mean value (over freq's.) of 'nspec' to be approx.
% 		MEAN( MIN(abs2(sg(f,:)),[],2)) = MEAN(abs2(sg(:))) / k = SUM(abs2(SIGNAL)) / k^2,
% 	or
% 		MEAN(nspec) = SUM(abs2(SIGNAL)) * (2*(NFREQ-1))^2 / L^2.
%  9.The technique in Notes 6 & 7 can be particularly effective if NFREQ is at
% 	least twice as large as the desired freq. resolution; after the rank filter, the extra
% 	freq. samples can be deleted.  For example:
% 		ns = estnoisesig(SIG, 2*NF);	% 2x over-sampling of frequencies.
% 		10*log10(medfilt1(ns, 3));		% As above, and converting to dB.
% 			result = ans(1:2:end);		% Discard the estimates at the extra freq's.
%  10.Signal quantization imposes an absolute lower limit on the "noise" (although it is 
% 	slightly signal-dependent, being created from the underlying continuous signal).  That 
% 	is, if the signal is of order unity or less and is quantized at 15 bits (plus 1 sign 
% 	bit), then it has a fundamental noise limit ~ 1/2^15 in amplitude, or 1/2^30 (= -90 dB)
% 	in power.  For such a signal, the following would virtually ALWAYS be appropriate:
% 		>> nspec = max( estnoisesig(SIGNAL,NFREQ), 1/(2^30*NFREQ)),
% 	if quantization = 15 bits; or, if SIGNAL has been scaled from order unity to some
% 	other value (and quantization therefore scaled likewise):
% 		>> nspec = max( estnoisesig(SIGNAL, NFREQ), max(SIGNAL.^2)/(2^30*NFREQ)) .
% 	(Be sure to multiply the quantization term by the mean squared window factor if 
% 	appropriate, per Note 5.)
%  11.If the signal/noise ratio is of interest, and not 'nspec' itself, then 'snrspeclin' or 
% 	'snrspeclog' may provide a simpler evaluation.
%  12.Each estimate in 'nspec' is appropriate to its frequency (row across the s/gram).  
% 	However, if the noise is expected to be smooth across frequencies, and if this
% 	expectation will be used in further computations -- as in Note 7, for example -- then 
% 	it is appropriate to double the power in the first (DC) and last (1/2-sampling rate) 
% 	elements of 'nspec' before using them in the further computation.  This occurs because
% 	of the s/gram computation's handling of these two frequencies.  (Only the cosine 
% 	components of the Complex exponential used in the underlying Fourier transform are 
% 	available for these two frequencies.)  This doubling of power applies ONLY to the 
% 	values to be used in the further computation, not the estimates themselves.  This is 
% 	because the further computation treats (e.g.) 'nspec(1:3)' together to produce an 
% 	improved estimate of the noise power at the 2nd freq.  But 
% 	'[nspec(1) nspec(2) nspec(3)]' does not produce AS improved an estimate as 
% 	'[2*nspec(1) nspec(2) nspec(3)]' does.
%  13.This function estimates 'nspec' from the spectrogram of SIGNAL (per Note 10).  If the
% 	s/gram is already available, then the function 'estnoisesgram' can compute 'nspec' 
% 	directly.  ('nspec' in that case will be NFREQ times higher than the estimate here.)
% 
%  See also: MEDFILT1, abs2, nonquiet, maxfilt1, deg_speech, snrspeclin, snrspeclog, sgram,
% 	estnoisesgram, SPECGRAM.
%
