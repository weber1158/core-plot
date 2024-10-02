function [plt,patches] = core_plot(Z,varargin)
%Core stratigraphy visualization
%
%SYNTAX
% CORE_PLOT(Z)
% CORE_PLOT(Z,Name="Value")
% plt = CORE_PLOT(Z)
% [plt,patches] = CORE_PLOT(Z)
%
%
%INPUT ARGUMENT
% Z :: Numeric vector specifying the thickness of each layer in
% the core from top to bottom.
%
%
%OUTPUT ARGUMENTS
% plt :: Returns handles to the graphics
%
% patches :: Individual layer objects as a Nx1 Patch where N represents the
% number of layers in the stratigraphic visualization. Access/modify the
% properties of a specific patch with indexing (e.g., patches(2).FaceColor).
%
%
%NAME-VALUE PAIRS
% Colors (Optional) :: Cell vector of hexidecimal colors OR a numeric
%  matrix of RGB color codes. If the number of colors is less than the
%  number of layers then the colors will repeat. If no colors are specified
%  then the layers will be visualized using alternating light and dark grays
%
% Radius (Optional) :: Numeric scalar specifying the radial width of the
%  cylindrical patch objects (default = 0.5)
%
% EdgeLines (Optional) :: Boolean specifying whether the edge lines of each
%  layer should be displayed (default = false)
%
% Light (Optional) :: Boolean to toggle a light object (default = true)
%
% FaceAlpha (Optional) :: Numeric scalar specifying face alpha property for
%  all layers (default = 1)
%
% EdgeAlpha (Optional) :: Numeric scalar specifying edge line alpha
%  property for all layers (default = 1)
%
% EdgeWidth (Optional) :: Numeric scalar specifying edge line width
%  property for all layers (default = 0.5)
%
% ViewAngle (Optional) :: Char vector specifying the viewing angle. Either
%  'oblique' (default) or 'right'
%
% ZDataType (Optional) :: Char vector specifying the type of Z data. By
%  default, ZDataType is set to 'thickness' meaning that each value in Z
%  represents the thickness of a stratigraphic layer. The other option for
%  ZDataType is 'depth' which clarifies that the values in Z represent the
%  depths bounding each each layer. This means that the number of elements
%  in Z must be equal to the number of layers +1 because each layer shares
%  a top boundary with another layer's bottom boundary, except for the
%  first layer which has a top boundary that it does not share. For
%  example, if there are four values in Z, such as Z=[0 2 4 6], then the
%  corresponding stratigraphic visualization when ZDataType='depth' will
%  contain exactly one fewer layer than the number of elements in Z:
%
%     |------------| -> Z(1) = 0
%     |  Layer #1  |
%     |------------| -> Z(2) = 2
%     |  Layer #2  |
%     |------------| -> Z(3) = 4
%     |  Layer #3  |
%     |------------| -> Z(4) = 6
%
%
%EXAMPLES
%--------------------------------------------------
% % Visualize a sediment core
% layer_thicknesses = [3 8 6 4 2 5];
% CORE_PLOT(layer_thicknesses);
% zlabel('Depth [cm]')
%--------------------------------------------------
% % Specify layer colors and the radial width
% layer_thicknesses = [3 8 6 4 2 5];
% C = {'#fea12c','#b147ce','#20d962'};
% r = 2;
% CORE_PLOT(layer_thicknesses, Colors=C, Radius=r);
% zlabel('Depth [cm]')
% legend('Clay','Siliceous ooze','Calcareous ooze')
%--------------------------------------------------
% % Visualize a rock core using annual layer boundary
% % data instead of layer thicknesses
% layer_depths = [0 12 46 100];
% C = [225 169 95; 51 0 0; 152 129 123];
% CORE_PLOT(layer_depths, Radius=5, Colors=C, ZDataType='depth');
% zlabel('Depth [m]')
% legend('Sandstone','Shale','Limestone')
%
%
%NOTES
% CORE_PLOT uses functions from the Partial Differential Equations Toolbox
% in order to make the visualization. Users without the PDE Toolbox can
% still use CORE_PLOT in MATLAB Online, or, if the PDE Toolbox is not
% detected, the function will prompt the user if they would like to
% continue with a more basic core plotting visualization.
%
% The "Colors" name-value pair has been written to accept colored lists
% specified as either a cell vector of hexidecimal codes or an Nx3 matrix
% of RGB triplets. RGB triplets are automatically divided by 255 if they
% are not already in the normalized range (0,1).
%
%
%See also
% core_colors

% Copyright 2024 Austin M. Weber

%% Input parsing
% Create an input parser object
parser = inputParser;

% Define default name-values
default_colors = {'#6e7f80','#c0c0c0'};
default_radius = 0.5;
default_edgeLines = false;
default_light = true;
default_faceAlpha = 1;
default_edgeAlpha = 1;
default_edgeWidth = 0.5;
default_viewAnlge = 'oblique';
default_zDataType = 'thickness';

% Define validation function
z_validation = @(x) isvector(x) & isnumeric(x);
colors_validation = @(x) iscell(x) | (ismatrix(x) & isnumeric(x));
radius_validation = @(x) isnumeric(x) & isscalar(x);
edgeLines_validation = @(x) islogical(x);
light_validation = @(x) islogical(x);
faceAlpha_validation = @(x) isnumeric(x) & isscalar(x);
edgeAlpha_validation = @(x) isnumeric(x) & isscalar(x);
edgeWidth_validation = @(x) isnumeric(x) & isscalar(x);
viewAnlge_validation = @(x) ischar(x);
zDataType_validation = @(x) ischar(x);

% Define input arguments
addRequired(parser, 'Z', z_validation);
addParameter(parser, 'Colors', default_colors, colors_validation);
addParameter(parser, 'Radius', default_radius, radius_validation);
addParameter(parser, 'EdgeLines', default_edgeLines, edgeLines_validation);
addParameter(parser, 'Light', default_light, light_validation);
addParameter(parser, 'FaceAlpha', default_faceAlpha, faceAlpha_validation);
addParameter(parser, 'EdgeAlpha', default_edgeAlpha, edgeAlpha_validation);
addParameter(parser, 'EdgeWidth', default_edgeWidth, edgeWidth_validation);
addParameter(parser, 'ViewAngle', default_viewAnlge, viewAnlge_validation);
addParameter(parser, 'ZDataType', default_zDataType, zDataType_validation);

% Parse the input arguments
parse(parser, Z, varargin{:});

% Access the values of the optional arguments
C = parser.Results.Colors;
r = parser.Results.Radius;
edgeLines = parser.Results.EdgeLines;
Light = parser.Results.Light;
faceAlpha = parser.Results.FaceAlpha;
edgeAlpha = parser.Results.EdgeAlpha;
edgeWidth = parser.Results.EdgeWidth;
viewAngle = parser.Results.ViewAngle;
zDataType = parser.Results.ZDataType;

%% Check whether the user has the proper toolbox
toolbox_idx = check_whether_PDEToolbox_is_installed();
if isequal(toolbox_idx,false)
  % User does not have PED Toolbox. Ask if they wish to continue.
    msg = 'The Partial Differential Equations (PED) Toolbox could not be found on the current search path. Would you like to continue anyway with the basic core plotting capabilities?';
    user_choice = questdlg(msg,...
        'Do you wish to continue?',...
        'Yes','No','No');
    if isempty(user_choice) | strcmp(user_choice,'No')
        disp('Operation canceled by user.')
        return
    elseif strcmp(user_choice,'Yes')
        % Continue with the basic core plotting capabilities
        [plt,patches] = basic_core_plot(Z,C,r,edgeLines,Light,faceAlpha, ...
                                        edgeAlpha,edgeWidth,viewAngle,zDataType);
        return
    end

end

%% Define the data type of the input Z
switch lower(zDataType)
    case 'thickness'
        zOffset = 0;
    case 'depth'
        % Convert Z from "depths" to "thicknesses"
        zOffset = Z(1);
        Z = diff(Z);
    otherwise
        error('Unrecognized ZDataType. Must be either ZDataType=''thickness'' or ZDataType=''depth''.')
end

%% Create cylinder(s)
num_Z = numel(Z);
if num_Z == 1
    cyl = multicylinder(r,Z);
    plt = pdegplot(cyl);
elseif num_Z > 1
    cum_Zsum = cumsum(Z);
    cyl = multicylinder(r,Z(1),Zoffset=zOffset);
    plt = pdegplot(cyl);
    for cylinder_iterable = 2:num_Z
        hold on
        new_cyl = multicylinder(r,Z(cylinder_iterable),...
            Zoffset=cum_Zsum(cylinder_iterable-1)+zOffset);
        pdegplot(new_cyl);
    end
    hold off
end

%% Set the colors of the layers
patches = findobj(gca,'Type','patch');
if isequal(C,default_colors) 
    % No colors specified
    alternateColors(Z,C,patches); % Local function

elseif ischar(C) 
    % One char color specified (depreciated)
    [patches.FaceColor] = deal(C);

elseif iscell(C) & isscalar(C)
    % One hex color specified
    [patches.FaceColor] = deal(C{1});

elseif iscell(C) & (numel(C) < numel(Z))
    % Multiple hex colors specified but less than length(Z)
    repeatHexColors(Z,C,patches);

elseif iscell(C) & (numel(C) == numel(Z))
    % Each layer has an assigned hex color
    patches_flipped = flipud(patches);
    for color_idx = 1:numel(Z)
        [patches_flipped(color_idx).FaceColor] = deal(C{color_idx});
    end

elseif ismatrix(C) & isnumeric(C) & isequal(size(C),[1 3])
    % One RGB triplet specified
    C2 = check_RGB_triplet_normalized(C);
    [patches.FaceColor] = deal(C2);

elseif ismatrix(C) & isnumeric(C) & (size(C,2) == 3) & (size(C,1) < numel(Z))
    % Multiple RGB colors specified but less than length(Z)
    repeatTripletColors(Z,C,patches);

elseif ismatrix(C) & isnumeric(C) & (size(C,2) == 3) & (size(C,1) == numel(Z))
    % Each layer has an assigned RGB color
    C2 = check_RGB_triplet_normalized(C);
    patches_flipped = flipud(patches);
    for color_idx = 1:length(Z)
        [patches_flipped(color_idx).FaceColor] = ...
            deal(C2(color_idx,:));
    end

elseif size(C,1) > length(Z)
    % Too many colors specified
    f=gcf;
    close(f);
    error('Too many colors specified. The number of colors must be less than or equal to the number of layers.')
    
end

%% Change color of edge lines
if edgeLines == false
 lines = findall(gca,'Type','line');
 [lines.Color] = deal('none');
end

%% Change lighting object
light_object = findobj(gca,'Type','light');
light_object.Position = [1 -1 -1];
if Light == false
 light_object.Visible = 'off';
end

%% Change object transparencies
[patches.FaceAlpha] = deal(faceAlpha);
[patches.EdgeAlpha] = deal(edgeAlpha);

%% Change edge line width
lines = findall(gca,'Type','line');
[lines.LineWidth] = deal(edgeWidth);

%% Turn off handle visibility for text, line, and quiver objects
% This step is necessary for simplifying the syntax for creating
% legend objects. 
quivers = findobj(gca,'Type','quiver');
texts = findobj(gca,'Type','text');
[lines.HandleVisibility] = deal('off');
[quivers.HandleVisibility] = deal('off');
[quivers.Visible] = deal('off');
[texts.HandleVisibility] = deal('off');
[texts.Visible] = deal('off');

%% Set the handle visibility of the patch objects so that each unique color
%  appears only once as a legend entry.

if isa(C,'double')
    unique_colors = unique(C,'rows','stable');
    [patches.HandleVisibility] = deal('off');
    for unique_color = 1:size(unique_colors,1)
        rgb = unique_colors(unique_color,:);
        rgb = check_RGB_triplet_normalized(rgb);
        patches_flipped = flipud(patches);
        for patch_obj = 1:length(patches)
            patch_color = patches_flipped(patch_obj).FaceColor;
            if isequal(rgb,patch_color)
                patches_flipped(patch_obj).HandleVisibility = 'on';
                break
            end
        end
    end

elseif iscell(C)
    unique_colors = unique(C,'stable');
    [patches.HandleVisibility] = deal('off');
    for unique_color = 1:length(unique_colors)
        hex = unique_colors{unique_color};
        hex(1) = [];
        rgb = (reshape(sscanf(hex,'%2x'),3,[])/255)';
        patches_flipped = flipud(patches);
        for patch_obj = 1:length(patches)
            patch_color = patches_flipped(patch_obj).FaceColor;
            if isequal(rgb,patch_color)
                patches_flipped(patch_obj).HandleVisibility = 'on';
                break
            end
        end
    end
end


%% Fix axes appearances
xlim(gca,[-r r])
ylim(gca,[-r r])
zlim(gca,[0+zOffset sum(Z)+zOffset])
set(gca,'XColor','w','YColor','w')
set(gca,'XTickLabel',[],'YTickLabel',[])
set(gca,'YGrid','off','XGrid','off','ZGrid','on')
set(gca,'ZDir','reverse')

switch lower(viewAngle)
    case 'oblique'
        view(45,30)
    case 'right'
        view(45,0)
    otherwise
        error('Invalid ViewAngle name-value pair. Must be either ViewAngle=''oblique'' or ViewAngle=''right''.')
end

%-------------------------------------------------------------------
% END MAIN FUNCTION
%-------------------------------------------------------------------
end

%-------------------------------------------------------------------
% LOCAL FUNCTIONS 
%-------------------------------------------------------------------
function isInstalled = check_whether_PDEToolbox_is_installed()
%Checks if Partial Differential Equation Toolbox is installed
    isInstalled = false;
    v = ver; % Get list of installed toolboxes
    for i = 1:length(v)
        if strcmp(v(i).Name, 'Partial Differential Equation Toolbox')
            isInstalled = true;
            break;
        end
    end
end
%-------------------------------------------------------------------
function alternateColors(Z,C,patches)
%Applies an alernating color pattern to the layers
    % Define alternating color scheme
    number_of_colors = length(Z);
    colors = repmat(C(1),[1 number_of_colors]);
    even_number_index = 2:2:number_of_colors;
    for color_index = 1:length(even_number_index)
        colors{even_number_index(color_index)} = C{2};
    end
    % Assign colors to layers
    colors_flipped = flip(colors);
    for ii = 1:length(colors_flipped)
      patches(ii).FaceColor = colors_flipped{ii};
    end
end
%-------------------------------------------------------------------
function repeatHexColors(Z,C,patches)
%Repeat the color order in C across each layer, repeating as necessary
    % Define alternating color scheme
    number_of_colors = length(Z);
    colors = repmat(C,1,number_of_colors);
    colors = colors(1:number_of_colors);
    % Assign colors to layers
    colors_flipped = flip(colors);
    for ii = 1:number_of_colors
      patches(ii).FaceColor = colors_flipped{ii};
    end
end
%-------------------------------------------------------------------
function c2 = check_RGB_triplet_normalized(C)
%Checks if the given RGB matrix is normalized from 0 to 1, if not, then it
%converts the matrix into a normalized matrix, assuming that the RGB matrix
%is 8-bit (0 to 255).
     if sum(sum(C < 0)) > 0 % if any negative numbers
        error('Color array cannot contain negative values!')
     elseif sum(sum(C > 255)) > 0 % if any values greater than 255
        error('Color array cannot contain values exceeding 255!')
     end
     if sum(sum(C > 1)) > 0 % if contains values greater than 1
        c2 = C ./ 255; % Normalize data from 0 to 1
     else
        c2 = C;
     end
end
%-------------------------------------------------------------------
function repeatTripletColors(Z,C,patches)
%Repeat the color order in C across each layer, repeating as necessary
    % Ensure that matrix is RGB normalized
    C = check_RGB_triplet_normalized(C);

    % Define alternating color scheme
    number_of_colors = length(Z);
    colors = repmat(C,number_of_colors,1);
    colors = colors(1:number_of_colors,:);

    % Assign colors to layers
    colors_flipped = flipud(colors);
    for ii = 1:number_of_colors
      patches(ii).FaceColor = colors_flipped(ii,:);
    end
end
%-------------------------------------------------------------------
function newC = basicRepeatHexColors(numLayers,C)
    newC = repmat(C,1,numLayers);
    newC = newC(1:numLayers);
end
%-------------------------------------------------------------------
function newC = basicRepeatRGBColors(numLayers,C)
    newC = check_RGB_triplet_normalized(C);
    newC = repmat(newC,numLayers,1);
    newC = newC(1:numLayers,:);
end
%-------------------------------------------------------------------
function [h,patches] = basic_core_plot(Z,C,radius,edgelines,light,facealpha,edgealpha,edgewidth,viewangle,zdatatype)
%Basic core stratigraphy visualization
%
%Limitations
%
% The result of the basic_core_plot() function is a collection of patch objects
% and therefore is not reducible to a simple chart handle. To modify
% individual patch objects, use the findall() function like so:
%   >> basic_core_plot(Z)
%   >> patches = findall(gcf,'Type','patch');
%
% You can then manually adjust the properties of each patch object. E.g.:
%   >> patches(1).FaceColor = '#23bb6e';
%
% The command above will change the face color of the first patch object.
%
% If your basic_core_plot has a legend, then the patch objects in "patches" that
% correspond to the legend will be multiples of 3. For example, if the
% legend has 4 items, the index positions for the corresponding patch
% objects will be [3 6 9 12]. 
%
% If you want to change the face color of multiple patches at the same time
% you can use the deal() function. For example:
%   >> [patches([2 5 8 11]).FaceColor] = deal('r');
%
% The command above will change the face color of patches #2,5,8,11 to red.
%
% In addition to the patch objects, the basic_core_plot() function uses rectangle
% objects to "cap" the cylinders in order to better hide any edge lines. To
% change the color of the rectangle object at the top of the basic_core_plot()
% visualization, type the following command:
%   >> rect = findall(gcf,'Type','rectangle');
%   >> rect(1).FaceColor = 'r';
%
%
%Acknowledgements
%
% This function uses code from:
%
%  Ayad Al-Rumaithi (2024). Generate Cylinder Mesh Version 1.0.3
%  (https://www.mathworks.com/matlabcentral/fileexchange/92288),
%  MATLAB Central File Exchange. Retrieved September 10, 2024.
%
% ...in order to create the cylindrical patches used in the core
% visualization. Please also cite Al-Rumaithi (2024) if you use the
% basic_core_plot() function in publications.
%
% Special thanks are also extended to MATLAB user Voss for helping to
% clarify the procedure for changing the colors of the patch objects as
% detailed in the Limitations section above.
%

% Copyright 2024 Austin M. Weber

    switch lower(zdatatype)
        case 'thickness'
            % Convert from "thickness" to "depth", 
            % assuming the layer thicknesses start at
            % the top of the core (i.e., Z=0)
            Z_cumulative = cumsum(Z);
            Z = [0 Z_cumulative];
        case 'depth'
            % Do nothing
        otherwise
            error('Unrecognized ZDataType. Must be either ZDataType=''thickness'' or ZDataType=''depth''.')
    end

    % Predefine cylinder parameters
    number_of_layers = length(Z) - 1;
    number_of_concentric_rings = 1;
    number_of_faces = 64;
    % Radius size (i.e., the thickness of the cylinders)
    rect_position = [-radius -radius radius*2 radius*2];

    for i = 1:number_of_layers
    % Create cylindrical layers and stack them in a loop
    cylinder_plot(radius,...
        number_of_concentric_rings,...
        number_of_faces,...
        [Z(i) Z(i+1)]);
    end

    % Divide the figure into a series of patch objects
    patches = findobj(gca,'Type','patch');
    
    [patches.EdgeColor] = deal('none');
    if isa(C,'cell')
        Csize=numel(C);
    elseif isa(C,'double')
        Csize=size(C,1);
    end
    if edgelines == true
        % Outline the core
        for v = 3:3:length(patches) % (every third patch object)
         patches(v).EdgeColor = 'k';
         patches(v).LineWidth = 0.25;
        end
        [patches.EdgeAlpha] = deal(edgealpha);
        [patches.LineWidth] = deal(edgewidth);
    end
    % Create a circular patch object for the top of the core
    if isa(C,'cell')
        hold on
        rectangle('Position', rect_position, 'Curvature', [1 1],...
            'FaceColor',C{1},'EdgeColor','none');
        hold off
    elseif isa(C,'double')
        C = check_RGB_triplet_normalized(C);
        hold on
        rectangle('Position', rect_position, 'Curvature', [1 1],...
            'FaceColor',C(1,:),'EdgeColor','none');
        hold off
    end

    % Assign colors to layers
    if (isa(C,'cell') & (numel(C)==numel(Z)-1)) | (isa(C,'double') & (size(C,1)==numel(Z)-1))
        % EACH LAYER HAS A SPECIFIED COLOR
        colors_flipped = flip(C);
        if isa(C,'cell')
            for ii = 1:length(colors_flipped)
              patches(ii.*3).FaceColor = colors_flipped{ii};
              patches(ii.*3-1).FaceColor = colors_flipped{ii};
            end
        elseif isa(C,'double')
            for ii = 1:size(colors_flipped,1)
              patches(ii.*3).FaceColor = colors_flipped(ii,:);
              patches(ii.*3-1).FaceColor = colors_flipped(ii,:);
            end
        end
    elseif isequal(C,{'#6e7f80','#c0c0c0'})
        % NO COLORS WERE SPECIFIED BY THE USER::ALTERNATE BETWEEN GRAYS
        oddRects = (1:2:number_of_layers).*3;
        oddTriangles = (1:2:number_of_layers).*3-1;
        evenRects = (2:2:number_of_layers).*3;
        evenTriangles = (2:2:number_of_layers).*3-1;

        [patches(oddRects).FaceColor] = deal(C{1});
        [patches(oddTriangles).FaceColor] = deal(C{1});
        [patches(evenRects).FaceColor] = deal(C{2});
        [patches(evenTriangles).FaceColor] = deal(C{2});
    elseif number_of_layers > Csize
        % A SINGLE COLOR OR SEVERAL COLORS SPECIFIED, BUT FEWER THAN THE
        % TOTAL NUMBER OF LAYERS. REPEAT COLOR ORDER.
        rectangle_index = 3:3:numel(patches);
        triangle_index = rectangle_index - 1;
        if isa(C,'cell')
            colors_flipped = flip(C);
            repC = basicRepeatHexColors(number_of_layers,colors_flipped);
            for i = 1:length(rectangle_index)
                [patches(rectangle_index(i)).FaceColor] = repC{i};
                [patches(triangle_index(i)).FaceColor] = repC{i};
            end
        elseif isa(C,'double')
            colors_flipped = flipud(C);
            colors_flipped = check_RGB_triplet_normalized(colors_flipped);
            repC = basicRepeatRGBColors(number_of_layers,colors_flipped);
            for i = 1:length(rectangle_index)
                [patches(rectangle_index(i)).FaceColor] = repC(i,:);
                [patches(triangle_index(i)).FaceColor] = repC(i,:);
            end
        end
    else
        % Too many colors specified
        f=gcf;
        close(f);
        error('Too many colors specified. The number of colors must be less than or equal to the number of layers.')
    end
    % Assign transparency
    [patches.FaceAlpha] = deal(facealpha);

    % Remove the X,Y,Z axes and tick marks
    set(gca,'XColor','none','YColor','none','ZColor','k')
    set(gca,'ZGrid','on','XGrid','off','YGrid','off')
    set(gca,'ZDir','reverse')
    zlim([min(Z) max(Z)])

    % Reduce the number of visible patch objects to equal
    % the number of unique colors so that users can make a
    % legend for the figure.

    % Make all patch objects invisible to the legend
    [patches.HandleVisibility] = deal('off');

    % Get list of all unique colors
    if isa(C,'double')
        unique_colors = unique(C,'rows','stable');
        for unique_color = 1:size(unique_colors,1)
            %Get unique color
            rgb = unique_colors(unique_color,:);
            rgb = check_RGB_triplet_normalized(rgb);
            patches_flipped = flipud(patches);
            % Loop through patches and colors and re-assign handle
            % visibility to the first unique match for each
            for patch_obj = 1:length(patches)
                patch_color = patches_flipped(patch_obj).FaceColor;
                if isequal(rgb,patch_color)
                    patches_flipped(patch_obj).HandleVisibility = 'on';
                    break
                end
            end
        end

    elseif isa(C,'cell')
        unique_colors = unique(C,'stable');
        for unique_color = 1:length(unique_colors)
        % Get unique color and remove # from hex code
        hex = unique_colors{unique_color};
        hex(1) = [];
        % Convert color from hexidecimal to normalized rgb
        rgb = (reshape(sscanf(hex,'%2x'),3,[])/255)';
        % Flip the patch objects to match the core orientation
        patches_flipped = flipud(patches);
        % Loop through patches and colors and re-assign handle
        % visibility to the first unique match for each.
        for patch_obj = 1:length(patches)
            % Get color of patch object
            patch_color = patches_flipped(patch_obj).FaceColor;
            % Assess for equality
            if isequal(rgb,patch_color)
                patches_flipped(patch_obj).HandleVisibility = 'on';
            break
            end
        end
        end
    end

    if light == true
        lightangle(-45,0)
        lighting gouraud
    end

    switch viewangle
      case 'oblique'
        view(-45.0395,32.3296)
      case 'right'
        view(-45.0395,0)
      otherwise
        error('Invalid ViewAngle name-value pair. Must be either ViewAngle=''oblique'' or ViewAngle=''right''.')
    end

    h=patches;

end
%-----------------------------------------------------------------------
function cylinder_plot(R,Nr,Nt,zz)
 % Uses functions from Ayad Al-Rumaithi (2024; https://www.mathworks.com/matlabcentral/fileexchange/92288)
 % These functions are used to produce a cylinder visualization
 [Nodes, Triangles, Quads]=Circle_Mesh(R,Nr,Nt);
 [Nodes3D,Prisms,Bricks] = Mesh2D_to_Mesh3D(Nodes,Triangles,Quads,zz);
 Plot_Mesh3D(Nodes3D,Prisms,Bricks);
end
%-----------------------------------------------------------------------
function [Nodes, Triangles, Quads]=Circle_Mesh(R,Nr,Nt)
% Copyright (c) 2021, Ayad Al-Rumaithi
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution
% 
% * Neither the name of University of Baghdad nor the names of its
%   contributors may be used to endorse or promote products derived from this
%   software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 %Nodes
 %------------
 c=0;
 for j=1:1:Nr %Number of Circles
  for i=1:1:Nt %Number of Angles
   c=Nt*(j-1)+i;    
   Nodes(c,1)=R*j/Nr*cosd(360*(i-1)/Nt);
   Nodes(c,2)=R*j/Nr*sind(360*(i-1)/Nt);    
  end
 end
 Nodes(c+1,1)=0;
 Nodes(c+1,2)=0;  
%Triangles
%------------
 Triangles=[];
 for i=1:1:Nt-1
  Triangles(i,1)=i; 
  Triangles(i,2)=i+1;
  Triangles(i,3)=c+1;    
 end
 Triangles(i+1,1)=i+1; 
 Triangles(i+1,2)=1;
 Triangles(i+1,3)=c+1;   
 %Quads
 %------------
 Quads=[];
 for j=1:1:Nr-1
  for i=1:1:Nt-1
   d=Nt*(j-1)+i;  
   Quads(d,1)=Nt*j+i;
   Quads(d,2)=Nt*j+i+1;
   Quads(d,3)=Nt*(j-1)+i+1;
   Quads(d,4)=Nt*(j-1)+i;
  end
  Quads(d+1,1)=Nt*j+i+1;
  Quads(d+1,2)=Nt*j+1;
  Quads(d+1,3)=Nt*(j-1)+1;
  Quads(d+1,4)=Nt*(j-1)+i+1;
 end
end
%-----------------------------------------------------------------------
function [Nodes3D,Prisms,Bricks] = Mesh2D_to_Mesh3D(Nodes,Triangles,Quads,zz)
% Copyright (c) 2021, Ayad Al-Rumaithi
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution
% 
% * Neither the name of University of Baghdad nor the names of its
%   contributors may be used to endorse or promote products derived from this
%   software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 Triangles(:,4)=-10e10;
 Mesh2D=[Triangles; Quads];
 n=size(Nodes,1);
 Nz=length(zz); 
 Nodes3D=[];
 Bricks=[];

 for i=1:1:Nz-1 
  Nodes3D=[Nodes3D; [Nodes zz(i)*ones(n,1)]];   
  Bricks=[Bricks; [Mesh2D+(i-1)*n Mesh2D+i*n]];
 end

 Nodes3D=[Nodes3D; [Nodes zz(Nz)*ones(n,1)]];   
 A=find(sum(Bricks,2)<0);
 Prisms=Bricks(A,[1 2 3 5 6 7]);
 Bricks(A,:)=[];
end

function Plot_Mesh3D(Nodes3D,Prisms,Bricks)
% Copyright (c) 2021, Ayad Al-Rumaithi
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution
% 
% * Neither the name of University of Baghdad nor the names of its
%   contributors may be used to endorse or promote products derived from this
%   software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 Triangles=[];
 Rectangles=[];
 Triangles=[Triangles ; [Prisms(:,1) Prisms(:,2) Prisms(:,3)]];
 Triangles=[Triangles ; [Prisms(:,4) Prisms(:,5) Prisms(:,6)]];
 Rectangles=[Rectangles ; [Prisms(:,1) Prisms(:,2) Prisms(:,5)  Prisms(:,4)]];
 Rectangles=[Rectangles ; [Prisms(:,2) Prisms(:,3) Prisms(:,6)  Prisms(:,5)]];
 Rectangles=[Rectangles ; [Prisms(:,1) Prisms(:,3) Prisms(:,6)  Prisms(:,4)]];

 patch('Faces',Triangles,'Vertices',Nodes3D,'FaceColor','green','EdgeAlpha',1);   
 patch('Faces',Rectangles,'Vertices',Nodes3D,'FaceColor','green','EdgeAlpha',1);

 Rectangles=[];
 Rectangles=[Rectangles ; [Bricks(:,1) Bricks(:,2) Bricks(:,3)  Bricks(:,4)]];
 Rectangles=[Rectangles ; [Bricks(:,5) Bricks(:,6) Bricks(:,7)  Bricks(:,8)]];
 Rectangles=[Rectangles ; [Bricks(:,1) Bricks(:,2) Bricks(:,6)  Bricks(:,5)]];
 Rectangles=[Rectangles ; [Bricks(:,2) Bricks(:,3) Bricks(:,7)  Bricks(:,6)]];
 Rectangles=[Rectangles ; [Bricks(:,3) Bricks(:,4) Bricks(:,8)  Bricks(:,7)]];
 Rectangles=[Rectangles ; [Bricks(:,4) Bricks(:,1) Bricks(:,5)  Bricks(:,8)]];

 patch('Faces',Rectangles,'Vertices',Nodes3D,'FaceColor','green','EdgeAlpha',1); 

 daspect([1 1 1]);
 view(3);
end
%-----------------------------------------------------------------------