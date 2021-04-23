function trajectories = root_default( mot )

viconNames = {'RFWT', 'LFWT', 'LBWT', 'RBWT'};

for i = 1:length(viconNames)
    idx(i) = strMatch(viconNames(i), mot.nameMap(:,1));
end

trajectories = 0;
for i = 1:length(idx)
    trajectories = trajectories + 1/length(idx) * mot.jointTrajectories{idx(i)};
end
