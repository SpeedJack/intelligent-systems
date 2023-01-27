sequenceInputLayer(8, 'Normalization', 'rescale-symmetric')
lstmLayer(50, 'OutputMode', 'last')
fullyConnectedLayer(1)
regressionLayer
