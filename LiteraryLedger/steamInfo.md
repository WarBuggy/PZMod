Double click to mark/unmark a corpse and sorting the corpses for easier looting
[list]
[*]Double-click a corpse icon in the loot window to mark or unmark it with a yellow tint.
[*]Automatically reorder loot window icons for clarity:
[olist]
[*]Unmarked corpses (tinted yellow) appear at the top, sorted by ID (last killed on top, usually).
[*]Non-corpse items remain in the middle, preserving their natural order.
[*]Marked corpses (normal, untinted) move to the bottom, sorted by ID (last killed on top, usually).
[/olist]
[*]Marked state for each corpse persists across game sessions.
[/list]

It would be great to receive feedbacks, suggestions or pointers on how to improve.

Version history

[b]v0.0.2[/b]
[list]
[*]Reverse the color of unmarked/marked corpse. Unmarked corpses are now tinted yellow (seek attention). Marked corpse are de-tinted (attention not required).
[/list]

[b]v0.0.1[/b]
[list]
[*]Initial release.
[/list]


local ISInventoryPage_pre_refreshBackpacks = ISInventoryPage.refreshBackpacks

function ISInventoryPage:refreshBackpacks()
    ISInventoryPage_pre_refreshBackpacks(self)

    if self.onCharacter then return end  -- skip player inventory
    
    for _, button in ipairs(self.backpacks) do
        -- Create overlay once if not exist
        -- Set overlay invisible (handled by refreshAndReorderButtons later)
        
        -- Hook double-click once
        if not button._dblClickMarkCorpseHooked then
            local origOnMouseDoubleClick = button.onMouseDoubleClick
            button.onMouseDoubleClick = function(selfBtn, x, y)
                -- if it is a corpse and a double click, toggle tinted flag
            end
            button._dblClickMarkCorpseHooked = true
        end
    end
    
    -- Reorder and refresh overlays on every refresh
    refreshAndReorderButtons(self)
end

function refreshAndReorderButtons() {
    for each button:
        -- Set visibility according to tinted flag
        -- add button to a group

    -- sort the group in order of unmarked / non-corpse / mark
    -- stack buttons vertically in this order
}
