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
%                 1) Convert RGB to XYZ to LMS to IPT
%                 2) Scale IPT space such that P,T \in [0, 1]
%                 3) Scale that my bitdepth to turn into an 10/12 bit int
%                 =======================================================================
%  Author: Ratnajit Mukherjee, ratnajitmukherjee@gmail.com
%  Date: Feb 2017
% 
%% Main body of the function
function [LPT, s] = rgb2iCAM(hdr, bitdepth)
%% Function to convert linear RGB to IPT colorspace  

    % step 0: normalize the input hdr
    s.maxval = max(hdr(:));
    s.lum_max = 10^4;
    rgb_normal = hdr ./ s.maxval;       

    % step 1: convert rgb2xyz using Wide Gamut
    xyz = rgb2xyz(rgb_normal);
    
    % step 2: convert xyz to LMS
    lms_p = xyz2lms(xyz);
    
    % step 3: convert LMS to IPT colour Space
    ipt = lms2ipt(lms_p);               
    
    % step 5: non-linear transformation to luma and scaling of chroma 
    %with MSE check  
    Y = ipt(:,:,1).*s.lum_max;
    [L] = luminanceTransferCurve(Y, 'forward');
    % chroma operation
    p = ipt(:,:,2); t = ipt(:,:,3); 
    s.minp = min(p(:)); s.maxp = max(p(:));
    s.mint = min(t(:)); s.maxt = max(t(:));  
    % scaling of P and T channels
    P = (p - min(p(:)))./(max(p(:)) - min(p(:)));
    T = (t - min(t(:)))./(max(t(:)) - min(t(:)));    
    s.powP = mseCheck(P, 10); 
    s.powT = mseCheck(T, 10);
    % scale to 10-bits
    P = round((P.^s.powP).*(2^bitdepth - 1)); 
    T = round((T.^s.powT).*(2^bitdepth - 1));           
    LPT = zeros(size(ipt));
    LPT(:,:,1) = L; LPT(:,:,2) = P; LPT(:,:,3) = T;
    LPT = uint16(LPT);                        
end

function xyz = rgb2xyz(rgb)
%% function to convert RGB to XYZ using the REC 709 gamut
    rec709 = [  0.4124, 0.3576, 0.1805;...
                0.2126, 0.7152, 0.0722;...
                0.0193, 0.1192, 0.9505  ];
   
    xyz = zeros(size(rgb));
    
    for i = 1 : size(rgb, 3)        
        xyz(:,:,i) = rgb(:,:,1) * rec709(i, 1) + ...
                     rgb(:,:,2) * rec709(i, 2) + ...
                     rgb(:,:,3) * rec709(i, 3);
    end         
end 

function lms_p = xyz2lms(xyz)
%% function to convert from XYZ to LMS (without transformation)

    lms_conv = [0.4002, 0.7075, -0.0807;...
                -0.2280, 1.1500, 0.0612;...
                 0.0000, 0.0000, 0.9184];
    
     LMS = zeros(size(xyz));
     
     for i = 1 : size(xyz, 3)        
        LMS(:,:,i) = xyz(:,:,1) * lms_conv(i, 1) + ...
                     xyz(:,:,2) * lms_conv(i, 2) + ...
                     xyz(:,:,3) * lms_conv(i, 3);
     end 
     
     %% non-linear transform
     lms_p = abs(LMS).^0.43;     
end 

function ipt = lms2ipt(lms)
    %% conversion from LMS to IPT colourspace
    ipt_conv = [0.4000, 0.4000, 0.2000;...
                4.4550, -4.8510, 0.3960;...
                0.8056, 0.3572, -1.1628];
            
    ipt = zeros(size(lms));
    
    for i = 1 : size(lms, 3)
        ipt(:,:,i) = lms(:,:,1) * ipt_conv(i, 1) + ...
                     lms(:,:,2) * ipt_conv(i, 2) + ...
                     lms(:,:,3) * ipt_conv(i, 3);
    end         
end 

function [powerval] = mseCheck(frame, bitdepth)
% multiple reiterative check  to test MSE (brute-force so slow)
    pe = @(x)sum(sum(sum(abs(((round(frame.^x.*(2^bitdepth-1))./(2^bitdepth-1)).^(1/x)) - frame))));
    powerval = fminbnd(pe, 0.0, 1.0);
end 