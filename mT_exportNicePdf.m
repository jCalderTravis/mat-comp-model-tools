function mT_exportNicePdf(height, width, directory, saveName, varargin)
% Explorts a PDF of the currently active matlab figure and also saves a 
% matlab version. Note the behaviour of the code
% depends on the property defaulttextinterpreter of the MATLAB object groot. If
% the default text interepreter is 'latex', figures are made with an extra
% boarder around them to stop text being chopped off.

% INPUT 
% height: double. In cm
% width: double. In cm
% directory: String. Directory to use for saving
% saveName: String. Filename to use
% varargin: Boolean. Overide default behaviour regarding whether to plot with a
% border

% HISTORY
% Reviewed 2020

if isempty(varargin)
    borderRequest = [];
else
    borderRequest = varargin{1};
end

% NOTES
% Printable space on A4 is 17, or 15.9 with 1 inch margins
% 14, 15.9 can be nice

thisFig = gcf;
thisFig.Renderer='Painters';
thisFig.InvertHardcopy = 'off';
thisFig.Color = [1, 1, 1];

set(findall(gcf, '-property', 'Font'),' Font', 'Arial')
fontsize(10, 'points')

% Do we need a border to ensure all text not chopped off the page?
interpreter = get(groot,'defaultAxesTickLabelInterpreter');
if ~isempty(borderRequest)
    border = borderRequest;
elseif strcmp(interpreter, 'latex')
    border = true;
else
    border = false;
end

set(gcf, 'PaperUnits', 'centimeters')
if border
    set(gcf, 'PaperSize', [width, height+0.1])
else
    set(gcf, 'PaperSize', [width, height])
end
set(gcf, 'PaperPositionMode', 'manual')
set(gcf, 'PaperUnits', 'normalized')
if border
    set(gcf, 'PaperPosition', [0.05, 0.05, 0.9, 0.9])
else
    set(gcf, 'PaperPosition', [0, 0, 1, 1])
end

savefig([directory '/' saveName])
print(gcf, '-dpdf', [directory '/' saveName])
