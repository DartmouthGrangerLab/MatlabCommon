% deprecated - call LiblinearTrain()
function [model] = TrainLiblinear (solverType, label, data, doAdjust4UnequalN, regularizationLvl)
    model = LiblinearTrain(solverType, label, data, doAdjust4UnequalN, regularizationLvl);
end