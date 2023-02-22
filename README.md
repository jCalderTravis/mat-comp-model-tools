# mat-comp-model-tools

This repository contains a set of tools written in Matlab that are helpful for computational model fitting, and plotting. An [older version](https://github.com/jCalderTravis/mat-comp-model-tools/releases/tag/v1.0) of this code was used for the analysis in the paper [_Explaining the effects of distractor statistics in visual search_](https://doi.org/10.1101/2020.01.03.893057).

Author: Joshua Calder-Travis, j.calder.travis@gmail.com

_Those sections of the code used in associated papers and preprints have been carefully checked. Nevertheless, no guarantee or warranty is provided for any part of the code._

## Key variables
Certain variables are used in many different functions, and are documented below.

### Standard dataset format
Throughout, the code relies on a standard representation of datasets referred to using `DSet`. `DSet` is a Matlab structure with the following fields:

- `P` \[num participant\] long struct array with fields...
  - `Data`    Contains a field for every measured/manipulated variable, and
            derived variables. All fields must either contain a vector as 
            long as the number of trials, or be a scalar. 
  - `Sim`     If data was simulated, this is a structure that describes the parameters used. 
            It has the fields...
    - `Params`
            Structure with a field for every model parameter. Should be in the same form as the unpacked 'ParamStruct'. See notes on parameter storage below.
  - `Models`  \[Num models\] long struct array which stores modelling results. 
            Contains fields...
    - `Fits`        \[num attempted fits\] long struct array
    - `BestFit`     The best fit out of the attempted fits
- `Spec`        Structure of dateset-wide settings. At a minimum must contain the field...
  - `TimeUnit`    'none' or time unit used in dataset in seconds
- `FitSpec`     General model fitting procedure settings, stored for reference
- `SimSpec` Structure array describing the true properties of the data if 
        the data was simulated. Note that any simulation details that vary
        from participant to participant should be stored in `DSet.P(iP).Sim`,
        not here. SimSpec should at least have a field...
   - `Name`    String. (Model naming system should match that used for any modelling.)


### Notes on parameter storage
Parameters are stored and passed in two forms, packed and unpacked. When 'unpacked'
they are stored in a structure referred to as `ParamStruct`. `ParamStruct`
contains fields named after sets of parameters. These fields store sets of 
parameters as numeric arrays. When 'packed' all
parameters from every parameter set are stored in a single parameter vector.


### Settings structure
Model fitting is performed using settings that are specified in a particular Matlab structure. This structure is referred to as `Settings` and has the following fields:

- `Algorithm`       Which minimisation algorithm to use ('bads' or
                'fmincon')
- `ModelName`
- `NumParams`       Number of free parameters to be fitted
- `ComputeTrialLL`  Structure with fields...
  - `FunName`   Function name specified as a string. (Ensure corresponding function is on    Matlab path during fitting.) Function accepts the arguments below, and should return a vector of log-likelihoods,
                one for every trial.
   - `Args`      Cell array, specifying arguments to pass to FunName. For an 
                n long cell array, the cell array specifies the first n
                arguments passed to the function 'FunName'. 'FunName'
                function is passed three additional arguments... (in order)
     - `ParamStruct`     A structure with a field for every
                    parameter (or set of parameters) as
                    specified in ParamSets. (See 
                    section 'Note on parameter storage'
                    above.)
     - `DSet.P(i).Data`  I.e. the data for one participant in the standard format.
                    ComputeTrialLL should not act on this
                    input if possible, in order to
                    prevent Matlab from having to make a
                    copy in memory of it.
     - `DSet.Spec`       See 'Standard data format' in above.
- `Params`       \[Num param sets\] long struct array. With fields,
  - `Name`
  - `FitLog`          (optional) Fit the logarithm of the 
                    parameter? If set to true, every time
                    the parameters are packed, the
                    logarithm of this parameter is taken,
                    and every time they are unpacked, the
                    exponential taken. Therefore, the
                    function Settings.ComputeTrialLL.FunName 
                    will still be passed 
                    ***the plain values***, it is just
                    that the fitting algorithm will see
                    the logarithm. 
  - `FitSqrt`         (optional) Similar to FitLog, except
                    for the square root.
  - `FitOffset`       (optional) Similar to FitLog, except
                    the value of this offset is added 
                    when the parameters are packed.
  - `FitScale`        (optional) Similar to FitLog, except
                    a multiple that is taken at packing.
  - `UnpackedShape`   What shape array should we use to store the
                    params in respective field of 'ParamStruct'.
  - `PackedOrder`     Row vector.
                    Represents the index of each parameter
                    when packed as a single vector. (See 
                    'Notes on parameter storage'.)
  - `UnpackedOrder`   Row vector.
                    Represents the linear index of each 
                    parameter when unpacked and stored in
                    an array in the relevant field of 
                    'ParamStruct'. (See 'Notes on parameter 
                    storage'.)
  - `InitialVals`     See 'UpperBound'
  - `LowerBound`      See 'UpperBound'
  - `UpperBound`      These three fields should contain a
                    function handle. The function
                    takes no arguments and returns an array
                    of the same shape specified in 
                    UnpackedShape.
  - `PLB`             Optional
  - `PUB`             Optional. PLB and PUB specify 
                    plausible upper and lower bounds, and
                    should be of the same format as
                    UpperBound. Only used when
                    Settings.Algorithm is 'bads'.
  - `Regulariser`     Function handle or string which can be
                    converted to a function handle. The
                    entire param set will be passed to the
                    regulariser function (as it is stored
                    when unpacked). Function should return
                    a value which will be added to the LL.
                    Note that while unpacked, the options to
                    fit square root, log, and offset do
                    not affect the parameter values.
- `NumStartPoints`  How many times to run the maximisation for each participant.
- `PresetStartPoints`
                true or false. Used in a very specific case. If have
                already fit say 4 models, can ask the code to fit the same
                four models again. If set to true, the start points for
                these new fits will use the end points from the first four
                fitted models. Note that must request the same four models
                again in the same order because the n'th new model will use the
                n'th old model's fitted start points. Note also, that cannot
                request more start points than did before, as obviously
                there wont be enough fit end points from last time to use.
                If set to true, NumStartCand is ignored.
- `NumStartCand`    How many candidate points should we draw to determine the
                start point. The point with the greatest log-likelihood 
                will be used as the start point.
- `TrialChunkSize`  No longer used. Set to 'off' to avoid an error message.
- `FindSampleSize`  Function which accepts 'DSet.P(i).Data' and returns the
                number of trials for the participant. Note the result will
                be used in the calculation of AIC and BIC scores.
- `FindIncludedTrials`
                Function which accepts 'DSet.P(i).Data' and returns a
                *logcial* vector of trials to be included in the LL 
                calculation.
- `FindIfOutOfBounds`
                No longer used. Set to 'none' to avoid an error message.
- `SupressOutput`   If set to true, information of progress is suppressed. 
- `DebugMode`       If set to true and fmincon is the algorithm, only a very small
                number of search iterations are run in each fit. 
- `JobsPerContainer`
                Only used by mT_scheduleFits to decide how many jobs to
                put in each container. This in turn determines how many
                jobs are sent to the cluster at a time.


