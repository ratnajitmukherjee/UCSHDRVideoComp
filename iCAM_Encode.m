% Copyright (c) 2017 Ratnajit Mukherjee
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%  -----------------------------------------------------------------------------
%  
%  Description: Core Module: Process
%                 =======================================================================
%                 Module Description:
%                 1) frame_path: path where reference frames are stored 
%                       start_frame : frame_step (typically 1) : last_frame 
%                 2) Write path: path to save 10 bit YUV files
%                 3) Bitdepth (10/12 bits) - as of now use 10
%                 =======================================================================
%  Author: Ratnajit Mukherjee, ratnajitmukherjee@gmail.com
%  Date: Feb 2017
% 
%% Main body of the function
function iCAM_Encode( frame_path, start_frame, frame_step, last_frame, write_path, bitdepth )
%% Main function for Encoding linear RGB frames to Uniform Chromaticiticity 
% color space using iCAM appearance model

    %% header information
    frames = start_frame:frame_step:last_frame;
    ldr_fid = fopen(fullfile(write_path, 'ldr.yuv'), 'w');       
        
    for i = 1 : length(frames)
        hdr = exrread(fullfile(frame_path, sprintf('%05d.exr', frames(i))));        
        [ipt, s] = rgb2iCAM(hdr, bitdepth);  
        % store metadata
        aux_data(i) = s;   
        ldr_p = permute(ipt, [2 1 3]);        
        fwrite(ldr_fid, ldr_p, 'uint16');        
        % Step 4: Status Message
        fprintf('\n Frame %d done', (i-1));        
    end  
    fclose(ldr_fid); clear ldr_fid;    
    
    save(fullfile(write_path, 'ucs_aux.mat'), 'aux_data');  
    fprintf('\n\n COMPRESSION COMPLETE...\n');
end