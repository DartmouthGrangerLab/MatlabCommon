# MatlabCommon
Commonly used and shared library code or utilities written in Matlab, for lab-wide use.

## encode
functions for changing the encoding of a dataset (whiten, one-hot code, ...)

## fig
figure code to make rendering simpler

## frontend
code to preprocess specific datatypes (images, video, audio, ...)

## geom
geometry and trigonometry functions (mostly for 2D and 3D spaces, but not exclusively)

## graph
various ways to connect members of a set to one another

## grid
grid of points (rectangular, hex, ...)

## io
i/o functions, e.g. for loading datasets

## ml
supervised machine learning algs (regression, classification), clustering algs (k-means, GMM, ...)

## scripts
various standalone scripts

## stat
various statistics (e.g. correlation)

## structlib
basic struct manipulation functions

## thirdparty
third party code bases
many of these have wrappers in other MatlabCommon packages

## validation
code for validating that various conditions hold
must* functions throw errors when the conditions are not met
is* functions return logicals and never error