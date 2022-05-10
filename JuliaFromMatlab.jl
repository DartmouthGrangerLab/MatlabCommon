using HDF5

# arg = parse(Float64, ARGS[1])
# keys(g)
# varargin[i] = h5read(inFile, "/group/ds" * string(i))

jlFile  = ARGS[1] # dir to add to path before execution
func    = ARGS[2]
inFile  = ARGS[3]
outFile = ARGS[4]

push!(LOAD_PATH, "D:\\Projects\\JuliaCommon")
push!(LOAD_PATH, jlFile)
include(jlFile)
# using ComputerProfile
func = eval(Symbol(func)) # convert func from string to actual function handle

if isfile(inFile) # if we have any input params
	fid = h5open(inFile, "r")
	g = read(fid)
	g = g["group"]
	close(fid)
	varargin = Array{Any,1}(undef,length(g))
	for i in 1 : length(g)
		varargin[i] = g["ds"*string(i)]
	end
	varargout = func(varargin...) # varargout should be a tuple
else
	varargout = func() # varargout should be a tuple
end

if length(varargout) > 0
	fid = h5open(outFile, "w")
	if length(varargout) > 1 && typeof(varargout).name == "Tuple"
		for i in 1 : length(varargout)
			write(fid, "/group/ds"*string(i), varargout[i])
		end
	else
		write(fid, "/group/ds1", varargout)
	end
	close(fid)
end