local TARGET_SPRITE = "carpentry_01_16"

-------------------------------------------------------------
-- Helper: Check if a moveable timed action is our crate
-------------------------------------------------------------
local function isTargetObject(action)
    if not action or not action.moveProps then return false end
    if action.moveProps.spriteName == TARGET_SPRITE then
        return true
    end
    return false
end

local oldUpdate = ISMoveablesAction.update

ISMoveablesAction.update = function(self)
    if isTargetObject(self) then
        -- instantly complete the action
        if self.action then
            self.action:setCurrentTime(self.maxTime or 0)
        end
        return
    end

    oldUpdate(self)
end