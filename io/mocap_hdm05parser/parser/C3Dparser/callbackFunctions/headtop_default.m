function trajectories = headtop_default( mot )

viconNames = {'RFHD', 'LFHD', 'RBHD', 'LBHD', 'C7'};

for i = 1:length(viconNames)
    idx(i) = strMatch(viconNames(i), mot.nameMap(:,1));
end
    
mid1 = 0.25 * mot.jointTrajectories{idx(1)} + 0.25 * mot.jointTrajectories{idx(2)}  + 0.25 * mot.jointTrajectories{idx(3)}  + 0.25 * mot.jointTrajectories{idx(4)};
mid2 = mot.jointTrajectories{idx(5)};

trajectories = mid1 + 0.3 * (mid1 - mid2);