Introduction
============

This extension of liblinear provides a matlab interface to multi-core parallel learning.  

Installation
============

If the code does not run properly, probably a compiler version not
supported yet by MATLAB was used. You can try to use an older
version. For example, if g++ X.Y is supported, replace

CXX ?= g++

in the Makefile with

CXX = g++-X.Y

Note that you should have = instead of ?= to ensure that the specified
compiler is used.

Usage
=====

The usage of train function is the same as liblinear except for the additional option:

-m nr_thread: use nr_thread threads for training (only for -s 0, -s 1, -s 2, -s 3 and -s 11)

Examples
========

matlab> [label, instance] = libsvmread('../heart_scale');
matlab> model = train(label, instance, '-s 0 -m 8');

will run L2-regularized logistic regression primal solver with 8 threads.
