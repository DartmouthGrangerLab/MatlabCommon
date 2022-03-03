% deprecated - call StructRenameField
function [s] = RenameField(s, oldName, newName)
    s = StructRenameField(s, oldName, newName);
end