function exportfigure(figureObj, filename, varargin)
	global EXPORT_FIGURES
	global FIGURES_FOLDER
	if ~EXPORT_FIGURES
		fprintf('Exporting of figures is disabled. Set EXPORT_FIGURES to true to enable it.\n');
		return;
	end

	p = inputParser;
	p.addRequired('figureObj', @(x) isa(x, 'matlab.ui.Figure'));
	p.addRequired('filename', @ischar);
	p.addOptional('sizes', [], @isnumeric);
	p.parse(figureObj, filename, varargin{:});
	figureObj = p.Results.figureObj;
	filename = p.Results.filename;
	sizes = p.Results.sizes;

	projectRoot = currentProject().RootFolder;
	figureDir = fullfile(projectRoot, FIGURES_FOLDER);
	if ~exist(figureDir, 'dir')
		mkdir(figureDir);
	end
	if ~isempty(sizes)
		prevUnits = figureObj.Units;
		prevOuterPos = figureObj.OuterPosition;
		figureObj.Units = 'points';
		figureObj.OuterPosition = sizes;
	end
	exportgraphics(figureObj, fullfile(figureDir, [filename '.pdf']),...
		'ContentType', 'vector',...
		'BackgroundColor', 'none');
	if ~isempty(sizes)
		figureObj.Units = prevUnits;
		figureObj.OuterPosition = prevOuterPos;
	end
end
