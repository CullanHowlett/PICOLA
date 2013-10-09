/* ==========================================================================*/
/*   Copyright (c) 2013       Cullan Howlett & Marc Manera,                  */
/*                            Institute of Cosmology and Gravitation,        */
/*                            University of Portsmouth.                      */
/*                                                                           */
/*   This file is part of PICOLA.                                            */
/*                                                                           */
/*   PICOLA is free software: you can redistribute it and/or modify          */
/*   it under the terms of the GNU General Public License as published by    */
/*   the Free Software Foundation, either version 3 of the License, or       */
/*   (at your option) any later version.                                     */
/*                                                                           */
/*   PICOLA is distributed in the hope that it will be useful,               */
/*   but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           */
/*   GNU General Public License for more details.                            */
/*                                                                           */
/*   You should have received a copy of the GNU General Public License       */
/*   along with PICOLA.  If not, see <http://www.gnu.org/licenses/>.         */
/* ==========================================================================*/

/* ==============================================================================================*/
/* v1.0: This file contains the initialistion of all the external variables in the header file.  */
/* v2.0: Included extra parameters for non-gaussianity and transfer function in line with vars.h.*/
/* ==============================================================================================*/

#include "vars.h"

#ifdef SINGLE_PRECISION
typedef float         float_kind;    // Single precision floating types
typedef fftwf_complex complex_kind;  // Single precision complex type
typedef fftwf_plan    plan_kind;     // Single precision FFTW plan
#else
typedef double       float_kind;     // Double precision floating types
typedef fftw_complex complex_kind;   // Double precision complex type
typedef fftw_plan    plan_kind;      // Double precision FFTW plan
#endif

// MPI variables
int ierr;             // The return value for mpi routines
int NTask;            // The total number of tasks
int ThisTask;         // The rank of each task
int LeftTask;         // The first neighbouring task on the left containing particles
int RightTask;        // The first neighbouring task on the right containing particles
MPI_Status status;    // The MPI error status
MPI_Request request;  // The continue directive for non-blocking sends

// Global variables for the grids
int NTaskWithN;           // The number of tasks that actually have particles
int last_slice;           // The last slice of the density/force grids (maybe equal to alloc_local)
int * Slab_to_task;       // The task to which each slice is assigned
int * Part_to_task;       // The task to which each particle position is assigned
int * Local_nx_table;     // The number of slices on each of the tasks
int * Local_np_table;     // The number of particle grid slices on each of the tasks
float_kind * N11;         // The force grid in the X direction
float_kind * N12;         // The force grid in the Y direction
float_kind * N13;         // The force grid in the Z direction
float_kind * density;     // The density grid
ptrdiff_t Local_nx;       // The number of slices on the task
ptrdiff_t Local_np;       // The number of particle grid slices on the task
ptrdiff_t Total_size;     // The total byte-size of the grids on each processor
ptrdiff_t alloc_local;    // The byte-size returned by FFTW required to allocate the density/force grids
ptrdiff_t alloc_slice;    // The byte-size of a slice of the density/force grids
ptrdiff_t Local_x_start;  // The global start of the slices on the task
ptrdiff_t Local_p_start;  // The global start of the particle grid slices on the task
complex_kind * P3D;       // Pointer to the complex, FFT'ed density grid (use in-place FFT)
complex_kind * FN11;      // Pointer to the complex, FFT'ed N11 force grid (use in-place FFT)
complex_kind * FN12;      // Pointer to the complex, FFT'ed N12 force grid (use in-place FFT)
complex_kind * FN13;      // Pointer to the complex, FFT'ed N13 force grid (use in-place FFT)
plan_kind plan;           // The plan for the in-place FFT of the density grid
plan_kind p11,p12,p13;    // Plans for the in-place FFT's of the forces grids 

// Units
double G;              // The unit-less Gravitational constant
double Hubble;         // The unit-less Hubble constant
double UnitMass_in_g;  // The unit mass (in g/cm) used in the code, read in from run parameters
double UnitTime_in_s;                   // The unit time (in s) used for the code, calculated from unit length and velocity
double UnitLength_in_cm;                // The unit length (in cm/h) used in the code, read in from run parameters file
double UnitVelocity_in_cm_per_s;        // The unit velocity (in cm/s) used in the code, read in from run parameters file
double InputSpectrum_UnitLength_in_cm;  // The unit length (in cm/h) of the tabulated input spectrum, read in from run parameters

// Cosmological parameters (at z=0)
double Fnl;          // The primordial non-gaussianity parameter for local, equilateral or orthogonal
double Anorm;        // The normalisation of the power spectrum/ transfer function
double Omega;        // The total matter density, CDM+Baryon
double Dplus;        // The growth factor
double Sigma8;       // The normalisation of the power spectrum 
double FnlTime;      // The scale factor at which fnl kicks in
double InitTime;     // The scale factor at the final redshift
double DstartFnl;    // The growth factor for the initial potential 
double ShapeGamma;   // The paramerisation of the Efstathiou power spectrum
double OmegaBaryon;  // The baryonic matter density
double HubbleParam;  // The normalised Hubble parameter, h=H/100
double OmegaLambda;         // The Cosmological Constant
double Fnl_Redshift;        // The redshift at which the nongaussian f_nl potential is computed
double Init_Redshift;       // The redshift at which to begin timestepping
double Final_Redshift;      // The final redshift of the simulation
double PrimordialIndex;     // The spectral index, n_s

#ifdef GENERIC_FNL
// Kernels to include general non-gaussian models
int NKernelTable;                 // The length of the kernel lookup table
struct kern_table * KernelTable;  // The kernel lookup table
#endif

// Particle data and pointers
#ifdef MEMORY_MODE
float * Disp[3];    // Vectors to hold the particle displacements each timestep
float * ZA[3];      // Vectors to hold the Zeldovich displacements before particle initialisation
float * LPT[3];     // Vectors to hold the 2LPT displacements before particle initialisation
#else
float_kind * Disp[3];    // Vectors to hold the particle displacements each timestep
float_kind * ZA[3];      // Vectors to hold the Zeldovich displacements before particle initialisation
float_kind * LPT[3];     // Vectors to hold the 2LPT displacements before particle initialisation
#endif
struct part_data * P;

// 'GADGET-Style' header
struct io_header_1 header, header1;

// Simulation variables
// ====================
char FileBase[100];   // The base output filename
char OutputDir[100];  // The output directory
int Nmesh;            // The size of the displacement, density and force grids (in 1-D) 
int Nsample;          // The number of particles (in 1-D)
int UseCOLA;          // Whether or not to use the COLA modifications
int NumFilesWrittenInParallel;  // The maximum number of files to be written out in parallel
unsigned int NumPart;           // The number of particles on each processor
unsigned long long TotNumPart;  // The total number of particles in the simulation
double Box;                     // The edge length of the simulation
double Buffer;                  // The amount of extra memory of each processor to compensate for moving particles

// 2LPT specific
char FileWithInputSpectrum[500];  // The file containing the input power spectrum
char FileWithInputTransfer[500];  // The file containing the input transfer function
char FileWithInputKernel[500];    // The file containing the input nongaussian kernel
int Seed;                         // The random seed to generate to realisation
int SphereMode;       // Whether to use a sphere or a cube in k-space
int WhichSpectrum;    // Which power spectrum to use
int WhichTransfer;    // Which transfer function to use

// COLA specific
int fullT;    // The time dependence of the velocity, hardcoded (see README)
int StdDA;    // The time dependence of the displacement, hardcoded (see README)
int filter;   // Whether or not to apply a smoothing filter to the forces, hardcoded
int nsteps;   // The number of timesteps to perform
double nLPT;   // Parameterisation of the time dependence of the velocity, hardcoded (see README)
double Scale;  // The smoothing scale for the smoothing filter, hardcoded
