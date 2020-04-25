%  Array-set of the abrupt landmark codes that are voiced or have certain other features.
%  Syntax:	lmset = lm_features(<FEAT1>,<FEAT2>,...),
% 			lmset = lm_features({<FEAT1>,<FEAT2>,...}),
% 	where (using the conventional labels of 'lm_label' for specific landmark types here):
% 	FEATn	= (case-insensitive) string to specify the feature whose codes are 
% 			to be returned -- one of:
% 			"VOICED", "UNVOICED" -- the "syllabic" (sonorant-cons. release), voiced-fric., 
% 				AND voicing onset "+g" (all in the VOICED set), or their complements; 
% 				periodic voicing onset and offset (+-p) and jumps (+-j) in F0 are all in
% 				the VOICED set;
% 			"GLOTTAL"	-- the voicing (+-g) codes;
% 			"PERIODIC"	-- for periodic voicing (+-p codes);
% 			"F0JUMP"	-- for abrupt upward (+j) and downward (-j) F0-change codes;
% 			"LARYNGEAL"	-- for GLOTTAL, PERIODIC, and F0JUMP codes;
% 			"ONSET", "OFFSET"	-- the + or - group of codes, respectively; note that
% 				+s is an onset of "syllabicity" (not of sonorant cons.); similarly for -s;
% 			"STOP", "FRIC"		-- the (nearly) all-band (STOP) or high-vs-low 
% 				contrary-band (FRIC) codes, both ONSET and OFFSET; see Notes; 
% 			"CLOSING", "OPENING" -- the codes for initiation or release of an 
% 				oral-cavity constriction, i.e., STOP+FRIC, either start (CLOSING) or
% 				release (OPENING); note that closing events are -s, -b, +f, and +v(!);
% 			"ORAL"		-- for oral-cavity constrictions, both closing and opening.
% 		->	If no FEAT is specified, or if FEAT = '', all individual codes will be 
% 				returned (but not groups such as "STOP").
% 		->	If several FEATn are listed, the set of codes returned will 
% 			be the intersection of the sets for each string.  This set may be empty,
% 			if the features are self-contradictory.
% 
%  Notes:
%  1.The type (index) values are assigned as in 'landmarks'.  The individual type values 
% 	have been as follows (but could change, consistent with changes in 'landmarks'):
% 		1,2	~ -+glottal [i.e., voicing], respectively
% 		3,4 ~ -+burst
% 		5,6 ~ -+syllabicity (sonorant cons. release)
% 		7,8	~ -+unvoiced fric.
% 		9,10 ~ -+voiced fric.
% 		11,12 ~ -+periodic voicing.
% 		13,14 ~ -+F0 jumps.
% 		NaN	~ other code.
%  2.Some features (e.g., ONSET, OFFSET) partition the set of all codes, but
% 	others (e.g., STOP, FRIC) do not.  For any feature or set FEAT, the complementary set 
% 	of codes may be obtained by:
% 		setdiff(lm_features(''),lm_features(FEAT)) .
%  3.Observe that the list of features may be given in consecutive arguments OR in a single
% 	argument consisting of a cell array of the strings.
%  4.In some cases, special-purpose functions tailored to particular features or LM types
% 	may be more convenient.  Example: 'lm_isvoiced'.
%  5.Voicing offset "-g" is considered UNVOICED.  However, all of the other laryngeal 
% 	events, +-p and +-j, are considered VOICED.
% 
%  See also: landmarks, UNION, INTERSECT, SETDIFF, lm_isvoiced, lm_labels.
%
