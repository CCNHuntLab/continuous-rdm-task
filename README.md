This repository contains the task code for running the continuous random dot motion (CRDM) 
paradigm with an optional auditory paradigm in the background. The CRDM task will be first 
presented in:

Ruesseler M, Weber LA, Marshall T, O'Reilly J, Hunt L (_in prep_). Adaptive integration
kernels in the human brain during a novel continuous dot-motion task.
======================================================================================

# Contributors
Maria Ruesseler, Laurence Hunt: wrote the initial version and core functions

Layla Stahr: adapted the code to run an auditory paradigm in the background

Lilian Weber: refactored the code into its current form

## Summary
In the continuous random dot motion (CRDM) task, participants are presented with a 
continuous (several minutes long) stream of moving dots. Their task is to press a button
whenever they think they are currently in a period with average motion coherence to the
left or to the right. The task code saves their responses (hits = correct detection of
average coherent motion; error = detection of average coherent motion, but to the wrong
side (right vs left); miss = no button press during average coherent motion; false alarm
= button press during average incoherent motion), reaction times, and the points and money
they win. Participants receive feedback for every response (the fixation dot changes colour
according to the four different response types).

The repository contains all necessary functions, but needs Psychtoolbox (PTB-3) to be installed.
The code was developed using MATLAB R2019b and tested in the OHBA EEG lab in Oxford.

## Getting started
0. Clone this repository and add it to your Matlab path (including subfolders).
1. Modify the function `crdm_set_task_options` to change general task parameters - including any 
local settings such as keyboard indices.
2. Modify the function `crdm_define_conditions` to implement your own experimental design.
3. Set the variable `basePath` in `crdm_run_experiment` to where you want to save stimuli and 
participants' behaviour.
4. Run `crdm_run_experiment`.

## Main functions
The main script performs all steps necessary to run an experimental session of the continuous 
dot-motion task:
```
crdm_run_experiment
```
The script will send prompts to the Matlab command window where you can enter the ID of the 
participant, session number, whether you want to record EEG data (and thus send triggers)
etc. It will automatically save all stimuli and participants' behaviour for this session in
a separate folder for each participant ID.

For every experimental session, you first need to generate the visual (and auditory, if desired) stimuli.
The function `crdm_create_session` creates all stimuli based on the settings in the task options and your
experimental design. Note that currently, you need to add your predefined auditory sequences to each
block after creating the session, but you could easily add a function that creates the tone sequences
automatically (depending on your auditory design).

**Important**: The stimuli should be generated on the computer on which the task will run (i.e., in the
lab where you will test participants). This is because some stimulus parameters depend on local screen
parameters. 

However, you don't need to generate stimuli just before running the experiment - you can also do this 
ahead of time and only "play" the session later. Generated sessions are automatically saved in the 
participant's folder and can be loaded later to run the task.

The main function that runs the task is `crdm_play_session`. It takes a session and the general task
options as inputs, as well as a base path pointing to where interim results should be saved (in case
a session doesn't run through). The function implements several features that can be switched on and
off using flags, e.g. `options.doTones` (whether to play an auditory sequence or not), `options.doTraining`
(whether we want to signal response periods to participants by changing the colour of the fixation dot
during training sessions), etc. All these flags are defined in `crdm_set_task_options`, except
`doEEG` (which you will be prompted for) and `doDebug` (which determines whether the task will be run
in full screen or in a small window for debugging). Note that the visual display only works properly
if you created the stimuli in the same debugMode as you run the task later. 

## Data saved
The code saves the variables `session` and `options` with a session- and participant-specific name in
the participant's folder, ending in "stimuli.mat", whenever you create a new session. After running an 
experimental session, it saves the variables `respMat` (which contains all responses and reaction times
of the participant) and `S` (which contains all relevant session information including timings and 
trigger values) as a mat file ending in "results.mat". 

Additionally, the code saves `respMat` and `S` after every block within a session (with a block-specific
names, also ending in "results.mat") so that single blocks can be analysed in case the session cannot be 
completed successfully.

## Auditory paradigm
The current task code will loop over a sequence of tones (defined in terms of their pitch) per block
and for every tone, it will also create a silence which serves as the ITI. The parameters of the tones
and ITI (the durations) are defined in the main task options. All that the code needs is a vector with
pitch values for every block that has to be saved in a subfield of the session struct:
```
session.blocks(iBlock).audSequence
```
This allows, for example, to play an auditory mismatch negativity paradigm with deviants defined by 
unexpected changes in pitch. If you want to implement a duration MMN instead, you need to change the
section of the function `crdm_play_session` where the tones are created via the loop over the entries
of `session.blocks(iBlock).audSequence` (e.g., you can loop over a vector with durations instead).

## Requirements
- You need MATLAB and Psychtoolbox to run this code. Everything else is included. The code was developed using **MATLAB R2019b**.


