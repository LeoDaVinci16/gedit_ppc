function matlab_logo
%MATLAB_LOGO  Draw a simple version of the MATLAB logo.
%
%   Run this file:  >> matlab_logo
%   It opens a figure that contains the orange “M” shape and the
%   word “MATLAB” below it.

%% 1. Define the vertices of the two “bars” that make the M
%   The shape is built from two overlapping triangles.
%   Coordinates are given in a normalized 0‑1 space.
%
%   left‑bar
Lx = [0   0.25 0.15 0.05];
Ly = [0   0    1    1];
%   right‑bar (mirrored)
Rx = 1 - Lx;    % mirror horizontally
Ry = Ly;        % same y‑coordinates

%% 2. Create the figure
figure('Color',[1 1 1]);   % white background
hold on
axis equal off
xlim([0 1]); ylim([0 1.2]);

%% 3. Draw the two bars with a smooth orange‑yellow colormap
%   We'll use a linear gradient by drawing many thin vertical strips.
nStrips = 200;                     % resolution of the gradient
cmap    = flipud(parula(2));       % start orange → end yellow
cmap    = [1 0.55 0;   % orange
    1 0.85 0];  % yellow

% Helper to draw a vertical strip between two polygon edges
    function drawStrip(x0,x1,yL,yR,col)
        X = [x0 x1 x1 x0];
        Y = [yL(1) yR(1) yR(2) yL(2)];
        patch(X,Y,col,'EdgeColor','none');
    end

% Left bar gradient
for k = 1:nStrips
    t   = (k-1)/(nStrips-1);
    col = (1-t)*cmap(1,:) + t*cmap(2,:);
    x0 = interp1([0 0.25],[Lx(1) Lx(2)],t);
    x1 = interp1([0 0.25],[Lx(4) Lx(3)],t);
    yL = [Ly(1) Ly(4)];   % bottom edge (y=0)
    yR = [Ly(2) Ly(3)];   % top edge (y=1)
    drawStrip(x0,x1,yL,yR,col);
end

% Right bar gradient (mirrored)
for k = 1:nStrips
    t   = (k-1)/(nStrips-1);
    col = (1-t)*cmap(1,:) + t*cmap(2,:);
    x0 = interp1([0 0.25],[Rx(1) Rx(2)],t);
    x1 = interp1([0 0.25],[Rx(4) Rx(3)],t);
    yL = [Ry(1) Ry(4)];
    yR = [Ry(2) Ry(3)];
    drawStrip(x0,x1,yL,yR,col);
end

%% 4. Add the word “MATLAB”
txt = text(0.5, -0.05, 'MATLAB', ...
    'HorizontalAlignment','center', ...
    'FontName','Helvetica', ...
    'FontWeight','bold', ...
    'FontSize',30, ...
    'Color',[0 0 0]);
% Slight vertical offset to align with the original logo
txt.Position(2) = txt.Position(2) - 0.02;

hold off
end