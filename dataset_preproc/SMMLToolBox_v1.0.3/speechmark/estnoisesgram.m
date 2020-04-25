%  Spectrogram's estimated stationary background or "noise" spectrum, using only rank filters.
%  Syntax:	nspec = estnoisesgram(SGM,<NBDLEN>)
%  where:
% 	SGM		= power spectrogram to be analyzed; SIZE(SGM,2) must be >>1 (roughly > 15); 
% 			if SGM has a non-zero Imaginary part, abs2(SGM) will be used instead, and a 
% 			warning given (with 'warnmsg'); the use of rank filters, i.e., order statistics,
% 			permits SGM to be logarithmic, or absolute amplitude (ABS(short-time Fourier 
% 			transform)); however, see Note 1;
% 	NBDLEN	= "neighborhood length" = an odd number [dflt. = 9] of s/gram slices (columns 
% 			of SGM) over which to filter the SGM values, to avoid the frequent, extremely 
% 			low values; SGM's width must be at least 2*NBDLEN for any noise estimates, and 
% 			should be several times this for reliable estimates;
% 	nspec	= ROW-vector of the estimated power spectrum of the "noise", that is, of the 
% 			stationary part of the signal (present at all times across SGM); evaluated at  
% 			each of the SIZE(SGM,1) frequencies independently; an estimate of overall 
% 			noise power is given by MEAN(nspec), or, more carefully, by 
% 				( SUM(nspec([1 end])) + 2*SUM(nspec(2:end-1)) ) / (SIZE(SGM,1)-1).
% 
%  Notes:
%  1.The basic insight: The stationary part of the waveform -- "Noise" -- is an independent, 
% 	additive component of the waveform and provides the floor to the expectation value of 
% 	the power in each spectrogram slice or frame.  Thus, the noise spectrum at each 
% 	frequency is approximately the smallest value of the power at that frequency, across 
% 	all time-slices of the spectrogram.
% 	- This is not true in detail, however, and this function manages the complications, 
% 	using rank filters over NBDLEN slices.  
% 	- It is important that the noise background be apparent for some interval (i.e., not 
% 	overlaid with a strong signal), at each frequency.  These intervals do not need to be
% 	coincident across frequencies, but each must last long enough for a few independent 
% 	estimates of the noise.  
% 	- Specifically, the intervals should last at least NBDLEN slices.  (For typical 
% 	speech s/grams, this interval might be ~ 10 msec.)  Larger values of NBDLEN will 
% 	produce more stable estimates; NBDLEN = 1 is likely to produce unusable estimates 
% 	dominated by 0 values (or -Inf logarithmic values).  The default value produces 
% 	relatively stable estimates [see Note 9].  
% 	- Very roughly, the histogram of estimates, i.e., HIST(nspec), may be expected to 
% 	approximate a distribution shaped like Chi-Squared with NBDLEN degrees of freedom or
% 	somewhat more (but scaled to the correct mean).  This is less true if SGM consists of
% 	logarithmic or absolute-signal values, instead of squared signal values.  Therefore, 
% 	results are likely to be more reliable if SGM = linear power.
% 	- This histogram result will be closely true if the noise is white across the signal
% 	samples that were used for the SGM values of the interval, AND if SGM is a s/gram of
% 	power, not of absolute amplitude or log-power.  However, it is a good approximation 
% 	even if these are not true, provided that each element of SGM covers many samples 
% 	over which the noise decorrelates, and provided that NBDLEN >> 1 (e.g., 9).  Using
% 	log-power is likely to require a higher value of NBDLEN than absolute amplitude does,
% 	for equally reliable estimates.
%  2.From Note #1, any "non-signal" segments, such as completely silent intervals at the
% 	beginning or end of recorded data, should be removed before processing.  See 
% 	'estnoisesig' for details.  Note that the results of 'estnoisesig(...,SIZE(SGM,1))' 
% 	will be 2*(SIZE(SGM,1)-1) times lower than 'nspec'.
%  3.The noise spectrum will be measured in whatever units SGM uses: linear power, linear
% 	power spectral density, logarithmic power, linear amplitude, or otherwise.  This is 
% 	valid because of the use of rank filters: For any monotonic scalar function F 
% 	(especially, F = LOG10 or SQRT, or multiplication by SIZE(SGM,1)), the ratio
% 		F(nspec) ./ estnoisesgram(F(sg))
% 	is constant (and of order unity).  Thus, using LOG10 or SQRT afterward is equivalent 
% 	to using it in the s/gram (but much faster).  In particular, if SGM has a non-0 
% 	Imaginary part, then 'nspec' will be estimated from 'abs2(SGM)', but the square-root 
% 	of these estimates will be returned; thus, the returned values will have the same 
% 	units [e.g., voltage or voltage per Hz per sec] as SGM has.
%  4.The mean value (not sum!) of 'nspec' is proportional to the noise power in the signal 
% 	used to compute SGM; this usually scales with SIZE(SGM,1).  Thus, if two 
% 	spectrograms are compared from the same signal but using different window lengths, 
% 	their noise-power estimates will vary in proportion to the window lengths.  (It is 
% 	possible to have s/grams of different freq. resolution WITHOUT using different window
% 	lengths, but that is not the typical usage.)
%  5.The values returned in 'nspec' will depend on the SHAPE of the window used in the 
% 	s/gram.  The expected value of 'nspec' will equal the mean noise power multiplied by 
% 	the number of samples used in the s/gram window (per Note 4), multiplied by the mean 
% 	squared value of the window shape itself (which is unity for ONES(1,NFREQ), but 3/8 
% 	for the more typical HANNING(.,"periodic")).
%  6.If slices in a s/gram are overlapped in time (as usual), it is important to use 
% 	NON-overlapped slices, as with:
% 		>> nspec = estnoisesgram(SGM(:,1:K:end)),
% 	where K is the overlap factor.  (This defaults to 2 for SPECGRAM but 4 for 'sgram'.)
% 	Otherwise, this function will assume that all slices are independent, leading to a 
% 	systematic mis-scaling of 'nspec'.  (This mis-scaling depends on a complicated 
% 	expression using GAMMAINC.)
%  7.The noise background is estimated independently at each frequency.  If SIZE(SGM,1) is 
% 	higher than needed, it may be helpful to "smooth" 'nspec'.  The function 'medfilt1e' 
% 	(another rank filter) is likely to be most appropriate for this, unless detailed 
% 	information about the noise source and future uses of 'nspec' is available.
%  9.It often happens that, despite best efforts in this function, the result has 
% 	unrealistic dips at isolated frequencies.  To remedy this, consider an expression that 
% 	uses estimates at adjacent frequencies, such as
% 		max(nspec, medfilt1(nspec,3))
% 	which uses only order statistics (MAX and a rank filter), and therefore does not 
% 	depend on when or whether to use LOG or SQRT.  
% 	- MAX in this expression introduces a small upward bias, which should be offset by 
% 	reducing all of 'nspec' by an appropriate amount.  For a white-noise signal of unit 
% 	power, this expression raises the expectation value from 1 to 1.09, or to 1.10 if 
% 	'nspec([1 end])' are omitted [see Note 14].  Using 9 instead of 3 adjacent samples
% 	raises it to 1.10 (1.12 if the ends are omitted).
% 	- Also, this expression helpfully reduces the expected standard deviation from
% 	29% to 24% (3 samples) or 21% (9 samples), whether or not the ends are omitted.  
% 	- However, it particularly usefully raises the (often much more troublesome) MIN 
% 	from 21% of the mean to 34% for both 3 AND 9 samples.  Omitting the ends raises
% 	the estimates of the minimum from 34% to 48% (3 samples) or 72% (9 samples).
% 	- For comparison, the simple expression
% 		medfilt1e(nspec,3)
% 	does not change the expectation value (to within 1% of the mean), and reduces the 
% 	expected S.D. from 29% of the signal power to 20%; using 9 instead of 3 adjacent 
% 	frequencies reduces the S.D. still further, to 12%.  These values are not changed (to
% 	within 1%) by omitting the first and last values of the estimated spectrum.  This 
% 	expression raises the minimum exactly as much as 'max(nspec, medfilt1(nspec,3))'.
% 	- However, this expression will also remove narrow peaks, which may be important to 
% 	preserve in the "noise" spectrum.
%  10.Mathematical analysis:
% 	For an underlying signal SIG (producing spectrogram SGM), the power in a noise 
% 	estimate scales with NFREQ.  Thus,
% 		estnoisesig(SIG,NFREQ) / (2*NFREQ-2)
% 	is independent of NFREQ (on average, unless the noise has significant, narrow frequency 
% 	structure).  
% 		MEAN( SUM(abs2(SGM),2) ) = SUM(abs2(SIG)),
% 	or, for 
% 		"L" = LENGTH(SIG), and 
% 		"k" = the number of time-slices (SIZE(SGM,2), i.e., k = L /(2*(NFREQ-1)),
% 	the LHS becomes:
% 		MEAN( k * MEAN(abs2(SGM),2) ), or k * MEAN( MEAN(abs2(SGM),2) ), so that
% 		k * MEAN(abs2(SGM(:))) = SUM(abs2(SIG));
% 	i.e.,
% 		MEAN(abs2(SGM(:))) /2 /(NFREQ-1) = SUM(abs2(SIG)) / L = MEAN(abs2(SIG)),
% 	which is a constant (with respect to NFREQ): Thus, the mean power spectrum (over 
% 	time-slices & freq's.) = 2*(NFREQ-1) times the mean squared signal.
% 	This should be compared to 'nspec' at each freq. index "f", which is (very approximately)
% 		MIN( abs2(SGM(f,:)),[],2).
% 	To the extent that the noise power at each freq. is distributed as Chi-Squared[2], 
% 	independently in each time-slice, the minimum value (over time-slices), i.e., 'nspec(f)', 
% 	can be expected to be approx. (mean value) / k; that is,
% 		MIN( abs2(SGM(f,:)),[],2) = MEAN(abs2(SGM(f,:))) / k,
% 	and the mean value (over freq's.) of 'nspec' to be approx.
% 		MEAN( MIN(abs2(SGM(f,:)),[],2)) = MEAN(abs2(SGM(:))) / k = SUM(abs2(SIG)) / k^2,
% 	or
% 		MEAN(nspec) = SUM(abs2(SIG)) * (2*(NFREQ-1))^2 / L^2.
% 	A refinement: For Real-valued underlying signals, the lowest and highest frequencies 
% 	(rows) of SGM effectively have 1/2 the degrees of freedom of the others.  (For example,
% 	the variance across columns is likely to be twice as large for these 2 rows as for
% 	the others.)  This is effect is assumed here.
%  11.The technique in Notes 8 & 9 can be particularly effective if NFREQ (or SIZE(SGM,1)) 
% 	is at least twice as large as the desired freq. resolution.  After the rank filter, 
% 	the extra freq. samples can be deleted.  However, be sure to multiply the result by the 
% 	oversampling factor (or add its logarithm, as appropriate), per Note 4.  
% 	For example:
% 		ns2x = estnoisesgram(SGM, 2*NFREQ);	% 2x over-sampling of frequencies.
% 		10*log10(medfilt1(ns2x, 3));		% As in Note 9, and converting to dB.
% 			ns = 10*log10(2) + ans(1:2:end);	% Discard the estimates at the extra freq's.
%  12.Signal quantization imposes an absolute lower limit on the "noise" (although it is 
% 	slightly signal-dependent, being created from the underlying continuous signal).  That 
% 	is, if the signal is of order unity or less and is quantized at 15 bits (plus 1 sign 
% 	bit), then it has a fundamental noise limit ~ 1/2^15 of its maximum in amplitude, or 
% 	1/2^30 (= -90 dB) in power.  For such a signal, the following would virtually ALWAYS 
% 	be appropriate if SGM = amplitude:
% 		nspec = max( estnoisesgram(SGM,NFREQ), max(SGM(:))*NFREQ/2^15);
% 	or
% 		nspec = max( estnoisesgram(SGM,NFREQ), max(SGM(:))*NFREQ/2^30);
% 	for power (spectral density).
% 	(Recall that 'nspec' has a factor of SIZE(SGM,1) due to the s/gram computation, per 
% 	Note 4.  Also be sure to multiply the quantization term by the mean squared window 
% 	factor if appropriate, per Note 5.)
%  13.If the signal/noise is of interest, and not 'nspec' itself, then 'snrspeclin', 
% 	'snrspeclog', or 'sgram_snr' may provide a simpler evaluation.  If SGM is not already 
% 	available, it may be more efficient and simpler to use 'estnoisesig', instead of 
% 	'estnoisesgram(sgram(...))', which can require carefully chosen 'sgram' arguments.
%  14.Each estimate in 'nspec' is appropriate to its frequency (row across the s/gram).  
% 	However, if the noise is expected to be smooth across frequencies, and if this 
% 	expectation will be used in further computations -- as in Note 9, for example -- then
% 	it is appropriate to double the power in the first (DC) and last (1/2-sampling rate) 
% 	elements of 'nspec'.  This occurs because of the s/gram computation's handling of 
% 	these two frequencies.  (Only the cosine components of the Complex exponential used 
% 	in the underlying Fourier transform are available for these two frequencies.)  
% 	- This doubling of power, or addition of 6 dB, applies ONLY to the values to be used 
% 	in the further computation, not the estimates of the noise themselves.  This is 
% 	because the further computation treats (e.g.) 'nspec(1:3)' together to produce an 
% 	improved estimate of the noise power in the 2nd freq.  '[nspec(1) nspec(2) nspec(3)]' 
% 	does not produce such an improved estimate as well as '[2*nspec(1) nspec(2) nspec(3)]' 
% 	does (assuming 'nspec' is linear in power, or that further processing uses only
% 	order statistics).
% 
%  See also: MEDFILT1, abs2, nonquiet, maxfilt1, deg_speech, snrspeclin, snrspeclog, sgram,
% 	SPECGRAM, estnoisesig, warnmsg, sgram_snr.
%
