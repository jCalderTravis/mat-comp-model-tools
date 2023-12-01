:: Script for calling python permutation test from matlab

set loadname=%1
set savename=%2
set condaActivatePath=%3
set condaEnvName=%4
set tooboxPath=%5

call %condaActivatePath%
call conda activate %condaEnvName%

python "%tooboxPath%\mT_runPermutationTest.py" %loadname% %savename%