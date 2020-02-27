Downloaded by Eli Bowen 1/22/2020 from: https://maxlab.neuro.georgetown.edu/hmax
%Eli says: use HMAX.m as your wrapper around this library

This is the 2007 version of HMAX

HMAX: Hierarchical Model And X
==============================

HMAX is a hierarchical, shape-based, computational model of visual object recognition in cortex. It summarizes the basic facts of the ventral visual stream, thought to mediate object recognition in cortex.

For more on the theoretical basis of HMAX, please visit <http://maxlab.neuro.georgetown.edu>.

Files
-----

Included are the following files and directories:

- AUTHORS: a list of the project's authors and maintainers.

- LICENSE: the project's license.

- README: this document.

- C1.m: Given an image, this function returns S1 & C1 unit responses.

- C2.m: Given an image, this function returns S1, C1, S2, & C2 unit responses.

- example.m: an example code implementing the full HMAX hierarchy, using the provided universal patch set and the provided example image set. This function will call all the relevant subfunctions of the HMAX-MATLAB implementation.

- initGabor.m: Given orientations and receptive field sizes, this function returns a set of Gabor filters.

- maxFilter.m: Given an image and pooling range, this function returns a matrix of the image's maximum values in each neighborhood defined by the pooling range

- padImage.m: Given an image, padding amount, and padding method, this function returns a padded image. Think of it as padarray operating on only the first 2 dimensions of a 3 dimensional array.

- extractC2forCell.m: Extract all responses for a set of images.

- sumFilter.m: Given an image and pooling range, this function returns an image where each "pixel" represents the sums of the pixel values within the pooling range of the original pixel.

- unpadImage.m: undoes padimage - given an image and padding amount, this function strips padding off an image

- windowedPatchDistance.m: given an image and patch, this function computes the euclidean distance between the patch and all crops of the image of similar size.

- universal_patch_set.mat: a file containing a set of universal patches of 8 different sizes extracted from random natural images. The file also includes the parameters used during the patch-extraction.

- exampleImages directory - a folder containing 10 images from the Labeled Faces in the Wild database (http://vis-www.cs.umass.edu/lfw/).

- exampleImages.mat: a cell array, each cell contains the path to one image located in the exampleImages folder.

- exampleActivations.mat: a file containing c2, bestBands, and bestLocations variables (see C2.m). This is the output of the example.m code. 

Maintainers
===========

- Josh Rule <rsj28 [at] georgetown [dot] edu>

Authors
=======

- Maximilian Riesenhuber
- Thomas R. Serre (initGabor.m, C1.m)
- Stanley Bileschi (C1.m) 
- Jacob G. Martin
- Josh Rule

License
-------

% PROPRIETARY INFORMATION
% PROPRIETARY INFORMATION
% PROPRIETARY INFORMATION
% PROPRIETARY INFORMATION
%
% Copyright (c) 2011 by Maximilian Riesenhuber, Thomas R. Serre (initGabor.m, C1.m), Stanley Bileschi 
(C1.m), Jacob G. Martin, Josh Rule 
% All Rights Reserved
%
% Redistribution and use in source and binary forms, with or without
% modification, are strictly prohibited.
%
% The name of the authors and maintainers may not be used to endorse or promote
% products derived from or associated with this software without specific prior
% written permission.
%
% No products may be derived from or associated with this software without
% specific permission.
%
% THIS SOFTWARE IS PROVIDED "AS IS," WITHOUT A WARRANTY OF ANY KIND. ALL
% EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING ANY
% IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR
% NON-INFRINGEMENT, ARE HEREBY EXCLUDED. The authors and maintainers SHALL NOT
% BE LIABLE FOR ANY DAMAGES OR LIABILITIES SUFFERED BY ANY ORGANIZATION OR ITS
% LICENSEES AS A RESULT OF OR RELATING TO USE, MODIFICATION OR DISTRIBUTION OF
% THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL the authors and
% maintainers BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR FOR DIRECT,
% INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER
% CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, ARISING OUT OF THE USE OF
% OR INABILITY TO USE THIS SOFTWARE, EVEN IF the authors and maintainers HAS
% BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND THE USER OF THIS CODE
% AGREES TO HOLD the authors and maintainers HARMLESS THEREFROM.
%
% PROPRIETARY INFORMATION
% PROPRIETARY INFORMATION
% PROPRIETARY INFORMATION
% PROPRIETARY INFORMATION
