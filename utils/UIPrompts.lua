U = U or {}
U.Prompts = {}

---Creates a new prompt group
---@return table
function U.Prompts:SetupPromptGroup()
    local UIPromptGroup = {}
    UIPromptGroup.PromptGroup = GetRandomIntInRange(0, 0xffffff)


    ---Shows the prompt group with the specified text (Def: 'Interact')
    ---@param label any
    ---@param tabAmount number
    ---@param tabDefaultIndex number
    function UIPromptGroup:ShowGroup(label, tabAmount, tabDefaultIndex)
        PromptSetActiveGroupThisFrame(self.PromptGroup, CreateVarString(10, 'LITERAL_STRING', label or 'Interact'), tabAmount or 1, tabDefaultIndex or 0, 0, 0)
    end

    ---Registers a prompt to the prompt group
    ---@param title string
    ---@param button number
    ---@param enabled boolean
    ---@param visible boolean
    ---@param pulsing boolean
    ---@param mode string
    ---@param options table
    ---@return table
    function UIPromptGroup:RegisterPrompt(title, button, enabled, visible, pulsing, mode, options)
        local UIPrompt = {}
        UIPrompt.Prompt = PromptRegisterBegin()
        UIPrompt.Mode = mode
        UIPrompt.title = title

        PromptSetControlAction(UIPrompt.Prompt, button or 0x4CC0E2FE)
        PromptSetText(UIPrompt.Prompt, CreateVarString(10, 'LITERAL_STRING', title or 'Option'))
        PromptSetEnabled(UIPrompt.Prompt, (enabled == nil and true) or enabled)
        PromptSetVisible(UIPrompt.Prompt, (visible == nil and true) or visible)

        -- Set the mode of the prompt (click, hold, mash, timed)
        -- If the mode is hold, you can set the hold time
        -- If the mode is mash, you can set the mash amount
        -- If the mode is timed, you can set the depletion time

        if UIPrompt.Mode == 'click' then
            PromptSetStandardMode(UIPrompt.Prompt, 1)
        end

        if UIPrompt.Mode == 'hold' then
            if options?.holdtime then
                PromptSetHoldMode(UIPrompt.Prompt, options.holdtime)
            else
                -- SHORT_TIMED_EVENT_MP
                -- SHORT_TIMED_EVENT
                -- MEDIUM_TIMED_EVENT
                -- LONG_TIMED_EVENT
                -- RUSTLING_CALM_TIMING
                -- PLAYER_FOCUS_TIMING
                -- PLAYER_REACTION_TIMING
                PromptSetStandardizedHoldMode(UIPrompt.Prompt, options?.timedeventhash or 'MEDIUM_TIMED_EVENT')
            end
        end

        if UIPrompt.Mode == 'mash' then
            PromptSetMashMode(UIPrompt.Prompt, options?.mashamount or 10)
        end

        if UIPrompt.Mode == 'timed' then
            PromptSetPressedTimedMode(UIPrompt.Prompt, options?.depletiontime or 5000)
        end

        -- Set the prompt group and pulsing (if exists)
        PromptSetGroup(UIPrompt.Prompt, self.PromptGroup, options?.tab or 0)
        PromptSetUrgentPulsingEnabled(UIPrompt.Prompt, (pulsing == nil and true) or pulsing)
        PromptRegisterEnd(UIPrompt.Prompt)
        
        -- Class functions to extend the prompt

        --- Change prompt text
        --- @param title string
        function UIPrompt:PromptText(title)
            if self.title ~= title then
                self.title = title
                PromptSetText(self.Prompt, CreateVarString(10, 'LITERAL_STRING', title or self.title))
            end
        end

        --- Change prompt visibility
        --- @param toggle boolean
        function UIPrompt:TogglePrompt(toggle)
            PromptSetVisible(self.Prompt, toggle)
        end

        --- Change prompt enabled state
        --- @param toggle boolean
        function UIPrompt:EnabledPrompt(toggle)
            PromptSetEnabled(self.Prompt, toggle)
        end

        --- Delete the prompt
        function UIPrompt:DeletePrompt()
            PromptDelete(self.Prompt)
        end

        ---Checks if the prompt has been completed
        ---@param hide any -- If true, hides the prompt when failed (Used for timed mode)
        function UIPrompt:HasCompleted(hide)
            if self.Mode == 'click' then
                return PromptHasStandardModeCompleted(self.Prompt)
            end
    
            if self.Mode == 'hold' then
                local result = PromptHasHoldModeCompleted(self.Prompt)
                if result then Wait(500) end
                return result
            end
    
            if self.Mode == 'mash' then
                local result = PromptHasMashModeCompleted(self.Prompt)
                if result then Wait(500) end
                return result
            end
    
            if self.Mode == 'timed' then
                local result = PromptHasPressedTimedModeCompleted(self.Prompt)

                if result and (hide == nil and true or hide) then
                    self:TogglePrompt(false)
                    Wait(200)
                end

                return result
            end
        end

        ---Checks if the prompt has failed 
        ---@param hide any -- If true, hides the prompt when failed (Used for timed mode)
        function UIPrompt:HasFailed(hide)
            if self.Mode == 'mash' then
                local result = PromptHasMashModeFailed(self.Prompt)

                if result then
                    self:TogglePrompt(false)
                end
    
                return result
            elseif self.Mode == 'timed' then
                local result = PromptHasPressedTimedModeFailed(self.Prompt)

                if result and (hide == nil and true or hide) then
                    self:TogglePrompt(false)
                    Wait(200)
                end

                return result
            end

            return false
        end

        return UIPrompt
    end

    return UIPromptGroup
end