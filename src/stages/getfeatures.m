function featureList = getfeatures
	featureFuncs = {
		'mean';
		'median';
		'range';
		'min';
		'max';
		'var'; % variance
		'meanfreq';
		'medfreq';
		'obw'; % occupied bandwidth
		'lofreq'; % lowest frequency
		'hifreq'; % highest frequency
		'iqr'; % interquartile range
		'meandiff'; % mean of difference between consecutive samples
		'kurtosis'; % measure of tailedness of a distribution
		'skewness'; % measure of symmetry of a distribution
		'powerfreq'; % power within occupied bandwidth
		'powerbw'; % 3-dB (half-power) bandwidth
		'rms'; % root mean square
		'peak2rms'; % ratio of largest abs to rms
		'harmmean'; % harmonic mean
		'mad'; % mean absolute deviation: mean(abs(x - mean(x)))
		'cumsumrange'; % range of cumulative sum
		'mode';
		'trapz'; % trapezoidal integration (approximation of integral)
	}';
	varNames = {
		'pleth_1'; % red PPG distal phalanx left index (500Hz)
		'pleth_2'; % infrared PPG distal phalanx left index (500Hz)
		'pleth_3'; % green PPG distal phalanx left index (500Hz)
		'lc_1'; % PPG sensor attachment pressure load cell distal phalanx left index (80Hz)
		'temp_1'; % temperature distal phalanx left index (10Hz)
		'pleth_4'; % red PPG proximal phalanx left index (500Hz)
		'pleth_5'; % infrared PPG proximal phalanx left index (500Hz)
		'pleth_6'; % green PPG proximal phalanx left index (500Hz)
		'lc_2'; % PPG sensor attachment pressure load cell proximal phalanx left index (80Hz)
		'temp_2'; % temperature proximal phalanx left index (10Hz)
		'temp_3' % ambient temperature (500Hz)
	}';

	featureList = {};
	for v = varNames
		for f = featureFuncs
			featureList{end+1} = [v{1} ':' f{1}];
		end
	end
end
