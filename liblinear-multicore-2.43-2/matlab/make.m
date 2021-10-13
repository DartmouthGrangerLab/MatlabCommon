% This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix
function make()
try
	% This part is for OCTAVE
	if(exist('OCTAVE_VERSION', 'builtin'))
		mex libsvmread.c
		mex libsvmwrite.c
		setenv('CFLAGS', strcat(getenv('CFLAGS'), ' -fopenmp'))
		setenv('CXXFLAGS', strcat(getenv('CXXFLAGS'), ' -fopenmp'))
		mex -I.. -lgomp train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
		mex -I.. -lgomp predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
	% This part is for MATLAB
	% Add -largeArrayDims on 64-bit machines of MATLAB
	else
		mex -largeArrayDims libsvmread.c
		mex -largeArrayDims libsvmwrite.c
        if ispc() % customization by Eli based on the liblinear author's instructions
%             mex COMPFLAGS="/openmp $COMPFLAGS" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex COMPFLAGS="/openmp $COMPFLAGS" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex CFLAGS="\$CFLAGS -std=c99" COMPFLAGS="/D CV_OMP /openmp $COMPFLAGS" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex CFLAGS="\$CFLAGS -std=c99" COMPFLAGS="/D CV_OMP /openmp $COMPFLAGS" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % below is from the website (obviously out of date, tron.cpp doesnt exist)
%             mex COMPFLAGS="/openmp $COMPFLAGS" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex COMPFLAGS="/openmp $COMPFLAGS" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../tron.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % below is like above, but replaced tron with newton
            %   error we get is: D:\MatlabCommon\liblinear-multicore-2.43-2\linear.cpp(244): error C3028: 'l2r_erm_fun::wTw': only a variable or static data member can be used in a data-sharing clause
%             mex COMPFLAGS="/openmp $COMPFLAGS" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex COMPFLAGS="/openmp $COMPFLAGS" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % below from chih-jen's email (compiler cant find gomp):
%             mex CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims -lgomp train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims -lgomp predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c 
            % below compiles, but seems to run single-threaded
            mex CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            mex CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % below same as above, but goes off hint online that you need to pass -fopenmp to linker too (doesn't help, still single threaded)
%             mex LDFLAGS="\$LDFLAGS -fopenmp" COPTIMFLAGS="$COPTIMFLAGS -fopenmp -O2" LDOPTIMFLAGS="$LDOPTIMFLAGS -fopenmp -O2" DEFINES="$DEFINES -fopenmp" CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex LDFLAGS="\$LDFLAGS -fopenmp" COPTIMFLAGS="$COPTIMFLAGS -fopenmp -O2" LDOPTIMFLAGS="$LDOPTIMFLAGS -fopenmp -O2" DEFINES="$DEFINES -fopenmp" CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % another idea
%             mex C:\ProgramData\MATLAB\SupportPackages\R2021a\3P.instrset\mingw_w64.instrset\lib\gcc\x86_64-w64-mingw32\6.3.0\libgomp.a LDFLAGS="\$LDFLAGS -fopenmp" COPTIMFLAGS="$COPTIMFLAGS -fopenmp -O2" LDOPTIMFLAGS="$LDOPTIMFLAGS -fopenmp -O2" DEFINES="$DEFINES -fopenmp" CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -lgomp -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % below compiles, fails to run due to 2 copies of openmp linked:
%             mex CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims -lomp train.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims -lomp predict.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c 
            % old 2.20 version
%             setenv('CFLAGS', strcat(getenv('CFLAGS'), ' -fopenmp'))
%             setenv('CXXFLAGS', strcat(getenv('CXXFLAGS'), ' -fopenmp'))
%             mex -I.. -largeArrayDims -lgomp train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex -I.. -largeArrayDims -lgomp predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            % next
%             mex COMPFLAGS="/openmp $COMPFLAGS" CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
%             mex COMPFLAGS="/openmp $COMPFLAGS" CFLAGS="\$CFLAGS -fopenmp -DCV_OMP" CXXFLAGS="\$CXXFLAGS -fopenmp -DCV_OMP" -I.. -largeArrayDims predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
        else
            mex CFLAGS="\$CFLAGS -fopenmp" CXXFLAGS='$CXXFLAGS -fopenmp' -I.. -largeArrayDims -lgomp train_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
            mex CFLAGS="\$CFLAGS -fopenmp" CXXFLAGS='$CXXFLAGS -fopenmp' -I.. -largeArrayDims -lgomp predict_liblinear_multicore.c linear_model_matlab.c ../linear.cpp ../newton.cpp ../blas/daxpy.c ../blas/ddot.c ../blas/dnrm2.c ../blas/dscal.c
        end
    end
catch err
	fprintf('Error: %s failed (line %d)\n', err.stack(1).file, err.stack(1).line);
	disp(err.message);
	fprintf('=> Please check README for detailed instructions.\n');
end

end

