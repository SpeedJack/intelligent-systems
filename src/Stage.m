classdef Stage < handle
	properties (Access = private)
		Function(1,1) function_handle = @NOP
		AdditionalParams(1,:) cell = {}
	end
	properties (Access = public)
		InputStages(1,:) Stage
		Output(1,1) struct = struct()
		OutputFile {mustBeTextScalar} = ''
		RunPolicy(1,1) RunPolicy = RunPolicy.OLD
	end
	properties (Dependent)
		Name
		OutputAvailable
	end

	methods
		function obj = Stage(stageFunction, outputFile, runPolicy, varargin)
			global DEFAULT_RUNPOLICY
			projectRoot = currentProject().RootFolder;
			dataDir = fullfile(projectRoot, 'data');
			if nargin > 0
				if isa(stageFunction, 'function_handle')
					obj.Function = stageFunction;
				else
					obj.Function = str2func(stageFunction);
				end
			end
			if nargin > 1
				obj.OutputFile = fullfile(dataDir, outputFile);
			else
				obj.OutputFile = fullfile(dataDir, func2str(obj.Function) + ".mat");
			end
			if nargin > 2
				obj.RunPolicy = runPolicy;
			elseif ~isempty(DEFAULT_RUNPOLICY)
				obj.RunPolicy = DEFAULT_RUNPOLICY;
			end
			if nargin > 3
				obj.AdditionalParams = varargin;
			end
		end

		function addParams(obj, varargin)
			obj.AdditionalParams = [obj.AdditionalParams varargin];
		end

		function addDatasetParam(obj)
			projectRoot = currentProject().RootFolder;
			obj.AdditionalParams = [obj.AdditionalParams {fullfile(projectRoot, 'dataset.zip')}];
		end

		function name = get.Name(obj)
			name = func2str(obj.Function);
		end

		function available = get.OutputAvailable(obj)
			available = ~isempty(fieldnames(obj.Output));
		end

		function available = allInputsAvailable(obj)
			for stage = obj.InputStages
				if ~stage.OutputAvailable
					available = false;
					return;
				end
			end
			available = true;
		end

		function outdated = isOutdated(obj)
			if ~obj.OutputAvailable && ~exist(obj.OutputFile, 'file')
				outdated = true;
				return;
			end
			for stage = obj.InputStages
				if ~exist(stage.OutputFile, 'file') || ...
						dir(stage.OutputFile).datenum > dir(obj.OutputFile).datenum
					outdated = true;
					return;
				end
				if stage.isOutdated()
					outdated = true;
					return;
				end
			end
			load(obj.OutputFile, 'usedParams');
			if numel(obj.AdditionalParams) ~= numel(usedParams)
				outdated = true;
				return;
			end
			for i = 1:numel(obj.AdditionalParams)
				if ~isequal(usedParams{i}, obj.AdditionalParams{i})
					outdated = true;
					return;
				end
			end
			outdated = false;
		end

		function output = loadOutput(obj)
			if ~obj.OutputAvailable
				obj.Output = load(obj.OutputFile, '-regexp', '^(?!usedParams$).+$');
			end
			output = obj.Output;
		end

		function addInputStages(obj, varargin)
			for stageCell = varargin
				obj.InputStages(end+1) = stageCell{1};
			end
		end

		function inputData = getInputData(obj)
			if ~obj.allInputsAvailable
				error('Error. Missing input for stage ''%s''.', obj.Name);
			end
			if isempty(obj.InputStages)
				inputData = [];
				return;
			end
			if numel(obj.InputStages) == 1
				stage = obj.InputStages(1);
				fields = fieldnames(stage.Output);
				if numel(fields) == 1 && strcmp(fields{1}, stage.Name)
					inputData = stage.Output.(stage.Name);
				else
					inputData = stage.Output;
				end
				return;
			end
			for stage = obj.InputStages
				fields = fieldnames(stage.Output);
				if numel(fields) == 1 && strcmp(fields{1}, stage.Name)
					inputData.(stage.Name) = stage.Output.(stage.Name);
				else
					inputData.(stage.Name) = stage.Output;
				end
			end
		end

		function output = run(obj)
			inputData = obj.getInputData();
			if isempty(inputData)
				outputData = obj.Function(obj.AdditionalParams{:});
			else
				outputData = obj.Function(inputData, obj.AdditionalParams{:});
			end
			if isstruct(outputData)
				output = outputData;
			else
				output.(obj.Name) = outputData;
			end
			obj.Output = output;

			folder = fileparts(obj.OutputFile);
			if ~exist(folder, 'dir')
				mkdir(folder);
			end
			save(obj.OutputFile, '-struct', 'output');
			usedParams = obj.AdditionalParams;
			save(obj.OutputFile, 'usedParams', '-append');
		end
	end
end

function NOP(varargin)
	% does nothing
end
