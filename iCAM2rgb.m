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
%                 1) Scale IPT space such that P,T \in [-1, 1]
%                 2) Scale I \in [10^-3, 10^4] then [0, 1]
%                 3) Convert IPT to LMS to XYZ to RGB space  
%                 =======================================================================
%  Author: Ratnajit Mukherjee, ratnajitmukherjee@gmail.com
%  Date: Feb 2017
% 
%% Main body of the function
function [ hdr ] = iCAM2rgb( LPT, s, bitdepth )
%% function to convert ipt frame to rgb

    %% step 0: normalization, inverse tone curve and inverse scaling for chroma            
    LPT = double(LPT);
    L = LPT(:,:,1); P = LPT(:,:,2); T = LPT(:,:,3);
    Y = luminanceTransferCurve(L, 'backward');  
    I = Y./s.lum_max;
    
    % inverse scaling and reversal to PT such that P,T \in [-1, 1]
    P = P./(2^bitdepth - 1); T = T./(2^bitdepth - 1); 
    P = P.^(1/s.powP); T = T.^(1/s.powT);
    p = (P.* (s.maxp - s.minp)) + s.minp;
    t = (T .* (s.maxt - s.mint)) + s.mint;
    
    ipt = zeros(size(LPT));
    ipt(:,:,1) = I; ipt(:,:,2) = p; ipt(:,:,3) = t;    
    
    %% step 1: conversion from IPT to non-linear LMS
    lms_nl = ipt2lms(ipt);
    
    %% step 3: conversion from non-linear LMS to xyz
    xyz = lms2xyz(lms_nl);
    
    %% step 4: conversion from wide-gamut xyz to rgb
    rgb = xyzwide2rgb(xyz);
    
    %% step 5: expand the RGB frame
    hdr = rgb .* s.maxval;

end

function [lms_nl] = ipt2lms(ipt)
%% function to invert IPT to LMS colourspace
   inv_ipt = [1.0000, 0.0976, 0.2052;...
              1.0000, -0.1139, 0.1332;...
              1.0000, 0.0326, -0.6769];
      
      lms_nl = zeros(size(ipt));
      for i = 1 : 3
        lms_nl(:,:,i) = ipt(:,:,1) * inv_ipt(i, 1) + ...
                        ipt(:,:,2) * inv_ipt(i, 2) + ...
                        ipt(:,:,3) * inv_ipt(i, 3);
      end             
end 

function xyz = lms2xyz(lms_nl)
%% linearizing the LMS function
    LMS = abs(lms_nl).^(1/0.43);
    
%% conversion from LMS-linear to XYZ
    inv_lms = [1.8502,   -1.1383,    0.2384;
               0.3668,    0.6439,   -0.0107;
                0,         0,    1.0889];
            
    xyz = zeros(size(LMS));
    for i = 1 : 3
        xyz(:,:,i) = LMS(:,:,1) * inv_lms(i, 1) + ...
                     LMS(:,:,2) * inv_lms(i, 2) + ...
                     LMS(:,:,3) * inv_lms(i, 3);
    end     
    
end

function rgb = xyzwide2rgb(xyz)
%% conversion RGB to XYZ 

    inv_rec709 =    [3.2406,   -1.5372,   -0.4986;...
                    -0.9689,    1.8758,    0.0415;...
                     0.0557,   -0.2040,    1.0570];
   
    rgb = zeros(size(xyz));
    
    for i = 1 : size(xyz, 3)        
        rgb(:,:,i) = xyz(:,:,1) * inv_rec709(i, 1) + ...
                     xyz(:,:,2) * inv_rec709(i, 2) + ...
                     xyz(:,:,3) * inv_rec709(i, 3);
    end         
end 
