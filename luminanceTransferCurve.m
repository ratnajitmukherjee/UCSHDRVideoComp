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
%                 1) Convert I \in [10^-3, 10^4] cd/m2 to I \in [0, 1023]                 %                 
%                 =======================================================================
%  Author: Ratnajit Mukherjee, ratnajitmukherjee@gmail.com
%  Date: Feb 2017
% 
%% Main body of the function
function [ L ] = luminanceTransferCurve(Y, mode)
%% LUMINANCETRANSFERCURVE: function to implement luminance transfer curve
% REC. 709 extended proposal (analytical transfer function)

    switch mode
        case 'forward'
%% Forward Transfer Curve
            L_HDR = Y;
            Lout1 = zeros(size(L_HDR));
            Lout1( L_HDR<0.007) = 2285.712 * L_HDR(L_HDR<0.007);
            Lout1((L_HDR>=0.007)&(L_HDR<100)) = 224.174*(L_HDR((L_HDR>=0.007)&(L_HDR<100)).^(1/5))-67.100;
            Lout1( L_HDR>=100) = 263.5*log10(L_HDR(L_HDR>=100)) - 31; 
            L = round(Lout1);          
        case 'backward'
%% Backward Transfer Curve    
            Lout = Y;
            y = zeros(size(Lout));
            y(Lout<16) = Lout(Lout<16)/2285.712;
            y((Lout>=16)&(Lout<496)) = ((Lout((Lout>=16)&(Lout<496)) + 67.100)./224.174).^5;
            y(Lout>=496) = 10.^((Lout(Lout>=496) + 31)./263.500);
            L = y; 
    end 
end