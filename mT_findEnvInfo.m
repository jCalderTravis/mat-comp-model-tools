function envInfo = mT_findEnvInfo()
% Return information on where to find various things in the current 
% environment

% OUTPUT
% evnInfo: struct. Has the following fields...
%   CondaActivate: str. The full filepath to the script for activating 
%       conda, before using python based functions.
%   CondaEnv: str. The name of the conda environment to activate when using
%       python based functions.

envInfo.CondaActivate = 'C:\Users\Calder\miniconda3\Scripts\activate';
envInfo.CondaEnv = 'mne-standard';