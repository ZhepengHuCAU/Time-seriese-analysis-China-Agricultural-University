% README.TXT

All code for this paper is written in MATLAB. All data are in ASCII column
format with extension .txt.

The files that generate Figure x in the paper have been labelled figurex.m
for x= 2,3,4,5. To replicate these figures, load the files, type figure5, 
for example, and press enter.

The data for the global oil market VAR are in data.txt. The data used in
constructing the second-stage estimates are in cpi.txt and beagdp.txt.

The following auxiliary functions and files are called up by the main 
files:

trivar.m        Loads data and computes LS estimates of VAR
olsvarc.m       Computes least-squares VAR parameters estimates
irfvar.m        Computes VAR impulse responses by Cholesky decomposition
stage2irf.m     Computes impulse responses from distributed lag model 
dif.m           First-difference operator
vec.m           Vectorization operator
