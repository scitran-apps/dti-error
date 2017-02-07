# scitran/dti-error
[![Docker Pulls](https://img.shields.io/docker/pulls/scitran/dti-error.svg)](https://hub.docker.com/r/scitran/dti-error/)
[![Docker Stars](https://img.shields.io/docker/stars/scitran/dti-error.svg)](https://hub.docker.com/r/scitran/dti-error/)

Calculate RMSE between the measured signal and the ADC (or dSIG) based on tensor model fit provided by [dtiInit](https://github.com/scitran-apps/dtiinit).

This gear calculates the histogram of differences between DTI based predictions (ADC or dSig) with the actual ADC or dSig data. Larger deviations suggest noisier data. This is one of a series of methods we are developing to assess the reliability of diffusion weighted image data.

### Build the Gear
```#bash
git clone https://github.com/scitran-apps/dti-error
cd dti-error
./build.sh
```

### Example Usage
First download a [dtiInit](https://github.com/scitran-apps/dtiinit) output archive and save to disk (e.g., dtiInit_27-Jan-2017_18-51-24.zip used below). Then run the commands below:

```bash
# Directory and file handling
DTIINIT_OUTPUT=dtiInit_27-Jan-2017_18-51-24.zip # Use the name of your dtiInit output
INPUT_DIR=`pwd`/input/dtiInit_Archive
OUTPUT_DIR=`pwd`/output
mkdir -p $INPUT_DIR
mkdir -p $OUTPUT_DIR

# Run the Gear
docker run --rm -ti -v $INPUT_DIR:/flywheel/v0/input -v $OUTPUT_DIR:/flywheel/v0/output scitran/dti-error:v0.1.0
```

### Compile the Matlab Executable
Clone required code and prepare for compilation:
```bash
git clone https://github.com/scitran-apps/dti-error
git clone https://github.com/vistalab/vistasoft
```
In Matlab (e.g., r2015b):
```Matlab
mcc -m dti-error/src/gear_dtiError.m -I vistasoft -I dti-error/src
```
