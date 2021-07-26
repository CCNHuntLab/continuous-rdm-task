function col = crdm_set_colours
%CRDM_SET_COLOURS Sets RGB values for all colours used in the continuous
%random dot motion (crdm) paradigm.

col.grey = [0.5 0.5 0.5]; % screen background
col.black = [0 0 0]; % color of dots and targets and fix before task starts
col.blue = [0 1 1]; % missed coherent motion epoch
col.red = [0.8 0 0]; % incorrect response during coherent motion
col.green = [0 0.6 0]; % correct response during coherent motion
col.yellow = [1 1 0]; % response during incoherent motion (i.e. also incorrect)
col.white = [1 1 1]; % colour of fixdot during coherent motion in training mode
 
end

