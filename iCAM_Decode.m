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
%                 1) Read path: where decompressed YUV is saved
%                 2) width and height of the frames to be decompressed
%                 3) nframes: the total number of frames to be decompressed
%                 3) dest_path: path to save decompressed EXR files
%                 4) Bitdepth: 10/12 (as of now use 10)
%                 =======================================================================
%  Author: Ratnajit Mukherjee, ratnajitmukherjee@gmail.com
%  Date: Feb 2017
% 
%% Main body of the function
function iCAM_Decode(read_path, width, height, nFrames, dest_path, bitdepth)
%% Main function for Decoding IPT frames to linear RGB using Uniform Chromaticiticity colour space using iCAM appearance model

    ldr_fid = fopen(fullfile(read_path, 'ldr.yuv'), 'r');
    load(fullfile(read_path, 'ucs_aux.mat'));
    
    for i = 1 : nFrames
        ldr_frame = fread(ldr_fid, (width * height * 3), 'uint16');
        ldr_frame = reshape(ldr_frame, [width, height, 3]);
        LCH = uint16(permute(ldr_frame, [2 1 3]));        
        s = aux_data(i);        
        hdr = iCAM2rgb(LCH, s, bitdepth);                
        exrwrite(hdr, fullfile(dest_path, sprintf('frame_%05d.exr', (i-1))));
        fprintf('\n Frame %d decompressed..', (i-1));        
    end
    fclose(ldr_fid);
    fprintf('\n\n DECOMPRESSION COMPLETE...\n');
end

