# The executable name
# ===================
EXEC = PICOLA

# Choose the machine you are running on. Currently versions for SCIAMA and DARWIN are implemented
# ===============================================================================================
#MACHINE = SCIAMA
MACHINE = SCIAMA2
#MACHINE = DARWIN

# Options for optimization
# ========================
OPTIMIZE  = -O3 -Wall

# Various C preprocessor directives that change the way PICOLA is made
# ====================================================================

#SINGLE_PRECISION = -DSINGLE_PRECISION	 # Single precision floats and FFTW (else use double precision)
#OPTIONS += $(SINGLE_PRECISION)

MEMORY_MODE = -DMEMORY_MODE		# Save memory by making sure to allocate and deallocate arrays only when we need them
OPTIONS += $(MEMORY_MODE)		# and by making the particle data single precision

#PARTICLE_ID = -DPARTICLE_ID             # Assigns unsigned long long ID's to each particle and outputs them. This adds
#OPTIONS += $(PARTICLE_ID)               # an extra 8 bytes to the storage required for each particle

LIGHTCONE = -DLIGHTCONE                 # Builds a lightcone based on the run parameters and only outputs particles
OPTIONS += $(LIGHTCONE)                 # at a given timestep if they have entered the lightcone 

GAUSSIAN = -DGAUSSIAN                   # Switch this if you want gaussian initial conditions (fnl otherwise)
OPTIONS += $(GAUSSIAN) 

#LOCAL_FNL = -DLOCAL_FNL                 # Switch this if you want only local non-gaussianities
#OPTIONS += $(LOCAL_FNL)                 # NOTE this option is only for invariant inital power spectrum
                                         # for local with ns != 1 use DGENERIC_FNL and input_kernel_local.txt

#EQUIL_FNL = -DEQUIL_FNL                 # Switch this if you want equilateral Fnl
#OPTIONS += $(EQUIL_FNL)                 # NOTE this option is only for invariant inital power spectrum
                                         # for local with ns != 1 use DGENERIC_FNL and input_kernel_equil.txt

#ORTHO_FNL = -DORTHO_FNL                 # Switch this if you want ortogonal Fnl
#OPTIONS += $(ORTHO_FNL)                 # NOTE this option is only for invariant inital power spectrum
                                         # for local with ns != 1 use DGENERIC_FNL and input_kernel_ortog.txt

#GENERIC_FNL += -DGENERIC_FNL            # Switch this if you want generic Fnl implementation
#OPTIONS += $(GENERIC_FNL)               # This option allows for ns != 1 and should include an input_kernel_file.txt 
                                         # containing the coefficients for the generic kernel 
                                         # see README and Manera et al astroph/NNNN.NNNN
                                         # For local, equilateral and orthogonal models you can use the provided files
                                         # input_kernel_local.txt, input_kernel_equil.txt, input_kernel_orthog.txt 

#GADGET_STYLE = -DGADGET_STYLE           # If we are running snapshots this writes all the output in Gadget's '1' style format, with the corresponding header
#OPTIONS += $(GADGET_STYLE)              # This option is incompatible with LIGHTCONE simulations. For binary outputs with LIGHTCONE simulations use the UNFORMATTED option.
																				
#UNFORMATTED = -DUNFORMATTED             # If we are running lightcones this writes all the output in binary. All the particles are output in chunks with each 
#OPTIONS += $(UNFORMATTED)               # chunk preceded by the number of particles in the chunk. With the chunks we output all the data (id, position and velocity)
                                         # for a given particle contiguously

#TIMING = -DTIMING                      # Turns on timing loops throughout the whole code and outputs the CPU times for each major part of the code 
#OPTIONS += $(TIMING)                   # and for each timestep, for both processor 0 and the sum of all processors


# Nothing below here should need changing unless you are adding in/modifying libraries for existing or new machines
# =================================================================================================================

# Run some checks on option compatability
# =======================================
ifdef GAUSSIAN
ifdef LOCAL_FNL
  $(error ERROR: GAUSSIAN AND LOCAL_FNL are not compatible, change Makefile)
endif
ifdef EQUIL_FNL
  $(error ERROR: GAUSSIAN AND EQUIL_FNL are not compatible, change Makefile)
endif
ifdef ORTHO_FNL
  $(error ERROR: GAUSSIAN AND ORTHO_FNL are not compatible, change Makefile)
endif
else
ifndef LOCAL_FNL 
ifndef EQUIL_FNL
ifndef ORTHO_FNL 
ifndef GENERIC_FNL
  $(error ERROR: if not using GAUSSIAN then must select some type of non-gaussianity (LOCAL_FNL, EQUIL_FNL, ORTHO_FNL, GENERIC_FNL), change Makefile)
endif
endif
endif
endif
endif

ifdef GENERIC_FNL 
ifdef LOCAL_FNL 
   $(error ERROR: GENERIC_FNL AND LOCAL_FNL are not compatible, choose one in Makefile) 
endif 
ifdef EQUIL_FNL 
   $(error ERROR: GENERIC_FNL AND EQUIL_FNL are not compatible, choose one in Makefile) 
endif 
ifdef ORTHO_FNL 
   $(error ERROR: GENERIC_FNL AND ORTHO_FNL are not compatible, choose one in Makefile) 
endif 
endif 

ifdef LOCAL_FNL
ifdef EQUIL_FNL
   $(error ERROR: LOCAL_FNL AND EQUIL_FNL are not compatible, choose one or the other in Makefile) 
endif
ifdef ORTHO_FNL
   $(error ERROR: LOCAL_FNL AND ORTHO_FNL are not compatible, choose one or the other in Makefile) 
endif
endif

ifdef EQUIL_FNL
ifdef ORTHO_FNL
   $(error ERROR: EQUIL_FNL AND ORTHO_FNL are not compatible, choose one or the other in Makefile) 
endif
endif

ifdef PARTICLE_ID
ifdef LIGHTCONE
   $(warning WARNING: LIGHTCONE output does not output particle IDs)
endif
endif

ifdef GADGET_STYLE
ifdef LIGHTCONE
   $(error ERROR: LIGHTCONE AND GADGET_STYLE are not compatible, for binary output with LIGHTCONE simulations please choose the UNFORMATTED option.)
endif
endif

ifdef UNFORMATTED
ifndef LIGHTCONE 
   $(error ERROR: UNFORMATTED option is incompatible with snapshot simulations, for binary output with snapshot simulations please choose the GADGET_STYLE option.)
endif
endif

# Setup libraries and compile the code
# ====================================
ifeq ($(MACHINE),SCIAMA)
  CC = mpicc
ifdef SINGLE_PRECISION
  FFTW_INCL = -I/opt/gridware/libs/gcc/fftw3/3_3_2/include/
  FFTW_LIBS = -L/opt/gridware/libs/gcc/fftw3/3_3_2/lib/ -lfftw3f_mpi -lfftw3f
else
  FFTW_INCL = -I/opt/gridware/libs/gcc/fftw3/3.3.3/include/
  FFTW_LIBS = -L/opt/gridware/libs/gcc/fftw3/3.3.3/lib/ -lfftw3_mpi -lfftw3
endif
  GSL_INCL  = -I/opt/gridware/libs/gcc/gsl/1.14/include/
  GSL_LIBS  = -L/opt/gridware/libs/gcc/gsl/1.14/lib/  -lgsl -lgslcblas
  MPI_INCL  = -I/opt/gridware/mpi/gcc/openmpi/1_4_3/include
  MPI_LIBS  = -L/opt/gridware/mpi/gcc/openmpi/1_4_3/lib/ -lmpi
endif

ifeq ($(MACHINE),DARWIN)
  CC = mpiicc	
ifdef SINGLE_PRECISION
  FFTW_INCL = -I/usr/local/Cluster-Apps.sandybridge/fftw/intel/3.3.3/include
  FFTW_LIBS = -L/usr/local/Cluster-Apps.sandybridge/fftw/intel/3.3.3/lib -lfftw3f_mpi -lfftw3f
else
  FFTW_INCL = -I/usr/local/Cluster-Apps.sandybridge/fftw/intel/3.3.3/include
  FFTW_LIBS = -L/usr/local/Cluster-Apps.sandybridge/fftw/intel/3.3.3/lib -lfftw3_mpi -lfftw3
endif
  GSL_INCL  = -I/usr/local/Cluster-Apps/gsl/1.9/include/
  GSL_LIBS  = -L/usr/local/Cluster-Apps/gsl/1.9/lib/  -lgsl -lgslcblas
  MPI_INCL  = -L/usr/local/Cluster-Apps/intel/impi/3.1/include
  MPI_LIBS  = -L/usr/local/Cluster-Apps/intel/impi/3.1/lib -lmpi
endif

ifeq ($(MACHINE),SCIAMA2)
  CC = mpicc
ifdef SINGLE_PRECISION
  FFTW_INCL = -I/opt/gridware/pkg/libs/fftw3_float/3.3.3/gcc-4.4.7+openmpi-1.8.1/include/
  FFTW_LIBS = -L/opt/gridware/pkg/libs/fftw3_float/3.3.3/gcc-4.4.7+openmpi-1.8.1/lib/ -lfftw3f_mpi -lfftw3f
else
  FFTW_INCL = -I/opt/gridware/pkg/libs/fftw3_double/3.3.3/gcc-4.4.7+openmpi-1.8.1/include/
  FFTW_LIBS = -L/opt/gridware/pkg/libs/fftw3_double/3.3.3/gcc-4.4.7+openmpi-1.8.1/lib/ -lfftw3_mpi -lfftw3
endif
  GSL_INCL  = -I/opt/apps/libs/gsl/1.16/gcc-4.4.7/include/
  GSL_LIBS  = -L/opt/apps/libs/gsl/1.16/gcc-4.4.7/lib/  -lgsl -lgslcblas
  MPI_INCL  = -I/opt/gridware/pkg/mpi/openmpi/1.8.1/gcc-4.4.7/include
  MPI_LIBS  = -L/opt/gridware/pkg/mpi/openmpi/1.8.1/gcc-4.4.7/lib/ -lmpi
endif

LIBS   =   -lm $(MPI_LIBs) $(FFTW_LIBS) $(GSL_LIBS)

CFLAGS =   $(OPTIMIZE) $(FFTW_INCL) $(GSL_INCL) $(MPI_INCL) $(OPTIONS)

OBJS   = src_v3/main.o src_v3/cosmo.o src_v3/auxPM.o src_v3/2LPT.o src_v3/power.o src_v3/vars.o src_v3/read_param.o
ifdef GENERIC_FNL
OBJS += src_v3/kernel.o
endif
ifdef LIGHTCONE
OBJS += src_v3/lightcone.o
endif

INCL   = src_v3/vars.h src_v3/proto.h  Makefile

all: $(OBJS) 
	$(CC) $(CFLAGS) $(OBJS) $(LIBS) -o $(EXEC)

$(OBJS): $(INCL) 

clean:
	rm -f src_v3/*.o src_v3/*~ *~ $(EXEC)
