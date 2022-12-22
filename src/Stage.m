classdef Stage < handle
	properties (Access = private)
		Function(1,1) function_handle = @NOP
		AdditionalParams(1,:) cell = {}
	end
	properties (Access = public)
		InputStages(1,:) Stage
		Output(1,1) struct = struct()
		OutputFile {mustBeTextScalar} = ''
		RunPolicy(1,1) RunPolicy = RunPolicy.DEFAULT
		RunQuestionAnswer(1,2) logical = [false false]
		ClearMemoryAfterExecution(1,1) logical = false
	end
	properties (Dependent)
		Name
		OutputAvailable
	end

	methods
		function obj = Stage(stageFunction, outputFile, runPolicy, varargin)
			global DATA_FOLDER
			projectRoot = currentProject().RootFolder;
			dataDir = fullfile(projectRoot, DATA_FOLDER);
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
			outdated = false;
		end

		function output = loadOutput(obj)
			if ~obj.OutputAvailable
				obj.Output = load(obj.OutputFile);
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
				error('IS:Stage:missingInput', 'Error: Missing input for stage ''%s''.', obj.Name);
			end
			if isempty(obj.InputStages)
				inputData = [];
				return;
			end
			if numel(obj.InputStages) == 1
				stage = obj.InputStages(1);
				inputData = stage.getOutput();
				return;
			end
			for stage = obj.InputStages
				inputData.(stage.Name) = stage.getOutput();
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

			output = obj.getOutput();
		end

		function output = getOutput(obj, varargin)
			p = inputParser;
			p.addOptional('load', true, @(x) isscalar(x) && islogical(x));
			p.parse(varargin{:});
			if ~obj.OutputAvailable
				if ~p.Results.load
					error('IS:Stage:missingOutputMem', 'Error: No output available in memory for stage ''%s''.', obj.Name);
				end
				if ~exist(obj.OutputFile, 'file')
					error('IS:Stage:missingOutputDisk', 'Error: No output available on disk for stage ''%s''.', obj.Name);
				end
				obj.loadOutput();
			end

			fields = fieldnames(obj.Output);
			if numel(fields) == 1 && strcmp(fields{1}, obj.Name)
				output = obj.Output.(obj.Name);
			else
				output = obj.Output;
			end
		end

		function clearMemory(obj)
			obj.Output = struct();
			for stage = obj.InputStages
				stage.clearMemory();
			end
		end
	end
end

function NOP(varargin)
	% does nothing
end
