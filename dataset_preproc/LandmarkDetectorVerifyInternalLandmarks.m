%Eli Bowen
%2018
function [landmarks] = LandmarkDetectorVerifyInternalLandmarks (landmarks, gramNum)
    if isfield(landmarks{gramNum}, 'startPlosion')
        landmarks{gramNum}.startPlosion = min(landmarks{gramNum}.startPlosion, landmarks{gramNum}.stopPhon - 1);
        landmarks{gramNum}.stopPlosion = min(landmarks{gramNum}.stopPlosion, landmarks{gramNum}.stopPhon - 1);
        if gramNum > 1
            landmarks{gramNum}.startPlosion = max(landmarks{gramNum}.startPlosion, landmarks{gramNum-1}.stopPhon + 1);
            landmarks{gramNum}.stopPlosion = max(landmarks{gramNum}.stopPlosion, landmarks{gramNum-1}.stopPhon + 1);
        end
    elseif isfield(landmarks{gramNum}, 'startFriction')
        landmarks{gramNum}.startFriction = min(landmarks{gramNum}.startFriction, landmarks{gramNum}.stopPhon - 2);
        landmarks{gramNum}.stopFriction = min(landmarks{gramNum}.stopFriction, landmarks{gramNum}.stopPhon);
        if gramNum > 1
            landmarks{gramNum}.startFriction = max(landmarks{gramNum}.startFriction, landmarks{gramNum-1}.stopPhon + 1);
            landmarks{gramNum}.stopFriction = max(landmarks{gramNum}.stopFriction, landmarks{gramNum}.startFriction + 2);
        end
        
        %now make sure startFriction-->stopFriction range is at least 3 timepoints long
        if landmarks{gramNum}.stopFriction - landmarks{gramNum}.startFriction + 1 < 3
            if gramNum == 1
                earliestPt = 1;
            else
                earliestPt = landmarks{gramNum-1}.stopPhon + 1;
            end
            if landmarks{gramNum}.startFriction == landmarks{gramNum}.stopFriction || rand() >= 0.5
                landmarks{gramNum}.startFriction = max(earliestPt, landmarks{gramNum}.startFriction - 1);
            end
            if landmarks{gramNum}.stopFriction - landmarks{gramNum}.startFriction + 1 < 3 %if still no good
                landmarks{gramNum}.stopFriction = landmarks{gramNum}.startFriction + 2;
            end
        end
    elseif isfield(landmarks{gramNum}, 'stopOther')
        landmarks{gramNum}.stopOther = min(landmarks{gramNum}.stopOther, landmarks{gramNum}.stopPhon);
    elseif isfield(landmarks{gramNum}, 'startVowel')
        landmarks{gramNum}.startVowel = min(landmarks{gramNum}.startVowel, landmarks{gramNum}.stopPhon - 2);
    end
end