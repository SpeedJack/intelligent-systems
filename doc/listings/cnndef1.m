sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

convolution1dLayer(5, 16, 'Stride', 2, 'Padding', 'same')
batchNormalizationLayer
leakyReluLayer
maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

globalAveragePooling1dLayer

fullyConnectedLayer(30)
fullyConnectedLayer(5)

fullyConnectedLayer(1)

regressionLayer
