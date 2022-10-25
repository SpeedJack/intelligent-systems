function features = computefeatures(dataMatrix, featureList)
	features = [];
	needObw = false;
	for index = 1:numel(featureList)
		feature = featureList{index};
		if isstring(feature) || ischar(feature)
			switch string(feature)
			case {"flo", "fhi", "bw", "power"}
				needObw = true;
			otherwise
				featureList{index} = str2func(feature);
			end
		end
	end

	if needObw
		[bw, flo, fhi, power] = obw(dataMatrix);
	end

	for index = 1:numel(featureList)
		feature = featureList{index};
		if isa(feature, 'function_handle')
			features = [features; feature(dataMatrix)'];
		else
			switch string(feature)
			case "flo"
				features = [features; flo'];
			case "fhi"
				features = [features; fhi'];
			case "bw"
				features = [features; bw'];
			case "power"
				features = [features; power'];
			end
		end
	end
end
