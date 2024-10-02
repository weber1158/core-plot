function colorPalette = core_colors(varargin)
%Core color palettes
%
%Description
% Generate a cell array of hexidecimal colors useful for
% core_plot() visualizations
%
%
%Syntax
% CORE_COLORS()
% CORE_COLORS(palette)
% CORE_COLORS(palette,n)
% colorPalette = CORE_COLORS(...)
%
%
%Inputs
% [no input] - if no inputs are specified, a dialogue box will open showing
% the three possible core color palettes.
%
% palette [string] - name of color palette || 'ice' OR 'sediment' OR 'rock'
%
% n [integer 1 ≤ n ≤ 7] - number of colors
%
%
%Outputs
% colorPalette [cell array] - list of hexidecimal color codes
%
%
%Examples
%   % Get list of four hexidecimal codes from the 'ice' color palette
%   CORE_COLORS('ice',4)
%      1x4 cell array
%         {'#5D88A8'} {'#ACE5EE'} {'#9F8170'} {'#003366'}
%
%   % Make a 3-layer core plot using the 'rock' color palette
%   Z = [0.000 2.500 7.710 10.000];
%   rock = CORE_COLORS('rock',3);
%   figure
%   core_plot(Z,Colors=rock);
%   zlabel('Depth [m]')
%   title('Rock Core')
%   legend('Mudstone','Dolomite','Limestone',...
%     'Location','east')
%   
%See also
% core_plot

% Copyright 2024 Austin M. Weber

% To do: Add some more distinguishable colors palettes
%   In progress: {'#f54232','#5329f5','#b6fc9c'}

% To do: Fix path issue that prevents users from viewing the 
% color palette image when they are working in a different dir-
% ectory. Currently, the `core_colors()` syntax with no inputs
% does not work unless the user is working in the default folder
% that contains the function file.

if nargin==0
   figure('menubar','none',...
       'numbertitle','off')
   axes('Position',[0 0 1 1])
      current_directory = cd;
      img_path = [current_directory '/images/'];
      img = [img_path 'core-color-palettes.jpg'];
      image(imread(img),"MaxRenderedResolution",1200); 
      axis image off
   return
end

if nargin==1
    palette = check_palette(varargin{1});
    colorPalette = palette;
    return
end

if nargin==2
    palette = check_palette(varargin{1});
    number_of_colors = checkN(varargin{2});
    colorPalette = palette(1:number_of_colors);
end

if nargin>2
    error('Too many input arguments.')
end

end % Ends main function ----------------

% Local functions -----------------------
function palette = check_palette(x)
%This function checks whether the user properly assigned a string/char
%value to the first input. If yes, it checks whether the user specified
%a string that is recognized by the CORE_COLORS() function. If yes, the
%corresponding color palette is returned as a cell array.
 if ~isstring(x)
   if ~ischar(x)
     error('Input must be a string or character vector. Try ''ice'', ''sediment'', or ''rock''.')
   end
 end
 if isstring(x) || ischar(x)
   x = lower(string(x)); % Ensure that x is a string and all lowercase
   switch x
       case 'ice'
            palette = {'#5D88A8','#ACE5EE','#9F8170','#003366','#0059B3','#FFE4C4','#A2A2D0'};
       case 'sediment'
            palette = {'#F36F5E','#FFE4C4','#848482','#C23B22','#79443B','#D2691E','#F64A8A'};
       case 'rock'
            palette = {'#79443B','#C1916B','#98817B','#E4D00A','#2F4F4F','#E1A95F','#330000'};
       case 'dracula'
            % Easter egg | not documented
            palette = {'#8BE9FD','#FFB86C','#BD93F9','#50FA7B','#FF79C6','#F1FA8C','#FF5555'}; % cyan,orange,purple,green,pink,yellow,red
       otherwise
           error('Palette not recognized. Try ''ice'', ''sediment'', or ''rock''.')
   end
 end
end

function N = checkN(y)
%This function checks whether the user properly assigned an integer
%value to the second input of the CORE_COLORS() function. If yes, this
%function returns the input.
 if ~isnumeric(y)
     error('The second input must be an integer.')
 end
 if numel(y) > 1
     error('The second input must be single integer and not an array.')
 end
 if y < 1 || y > 7
     error('The second input must be an integer 1 ≤ n ≤ 7.')
 end
 if y - floor(y) > 0
     y = floor(y);
     warning('The second input has been rounded down to the nearest whole number.')
 end
 N = y;
end