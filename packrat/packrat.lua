addon.name = "packrat";
addon.author = "colorglut, (Thorny: Added tracking Wardrobe 1 & 2)";
addon.version = "1.0";
addon.desc = "Tracks items in your inventory, Wardrobe and Wardrobe 2.";
addon.link = "";

require('common');
local ffi = require('ffi');
local d3d = require('d3d8');
local settings = require('settings');
local imgui = require('imgui');
local d3d8dev = d3d.get_device();

-- Default settings
local default_settings = T{
    trackedItemIds = T{},
    horizontal_mode = false,
    opacity = 0.8,
    tracker_pos = { 160, 440 },
    config_pos = { 100, 175 },
}

-- Load settings
local packrat_settings = settings.load(default_settings)
local packrat = T{
    settings = packrat_settings,
    itemTextures = T{},
    showConfiguration = {false},
    horizontal_mode_ref = { packrat_settings.horizontal_mode },
    is_initialized = false,
    ignoredItemTypes = T{
        1, -- Currency/Ninja tools
        2, -- Quest Items?
        4, -- Weapon
        5, -- Equipment
        6, -- Linkpearl
        -- 7, -- Consumable
        -- 8, -- Crystal
    },

    itemsPerColumn = 6
}

settings.register('settings', 'settings_update', function(s)
    if s then
        packrat.settings = s
        packrat.horizontal_mode_ref = { packrat.settings.horizontal_mode }
    end
end)
packrat.getItemById = function(itemId)
    return AshitaCore:GetResourceManager():GetItemById(itemId);
end

packrat.getItemTexture = function(item)
    if not packrat.itemTextures:containskey(item.Id) then
        local texturePointer = ffi.new('IDirect3DTexture8*[1]');
        if ffi.C.D3DXCreateTextureFromFileInMemory(d3d8dev, item.Bitmap, item.ImageSize, texturePointer) ~= ffi.C.S_OK then
            return nil;
        end
        packrat.itemTextures[item.Id] = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texturePointer[0]));
    end
    return tonumber(ffi.cast("uint32_t", packrat.itemTextures[item.Id]));
end

packrat.getInventoryStackableItems = function()
    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local stackableItems = T{}

    for i = 1, 81 do
        local containerItem = inventory:GetContainerItem(0, i)
        if containerItem and containerItem.Count > 0 then
            local item = packrat.getItemById(containerItem.Id)
            if not stackableItems:contains(item) then
                stackableItems:append(item)
            end
        end
    end

    return stackableItems
end

packrat.getTrackableItems = function()
    local inventoryItems = packrat.getInventoryStackableItems()

    inventoryItems = inventoryItems:filter(function(item)
        return not packrat.isIgnoredItemType(item)
    end)

    local inventoryItemIds = inventoryItems:map(function(item)
        return item.Id
    end)

    packrat.settings.trackedItemIds:each(function(itemId)
        if not inventoryItemIds:contains(itemId) then
            inventoryItems:append(packrat.getItemById(itemId))
        end
    end)

    return inventoryItems
end

packrat.getItemCount = function(item)
    local inventory = AshitaCore:GetMemoryManager():GetInventory()
    local itemCount = 0

    local containers = T{0}     --Inventory
    if (bit.band(item.Flags, 0x800) == 0x800) then
        containers:append(8)    -- Wardrobe
        containers:append(10)   -- Wardrobe 2
    end

    for _, container in ipairs(containers) do
        for i = 1, 81 do
            local containerItem = inventory:GetContainerItem(container, i)
            if containerItem and containerItem.Id == item.Id then
                itemCount = itemCount + containerItem.Count
            end
        end
    end

    return itemCount
end

packrat.isItemTracked = function(item)
    return packrat.settings.trackedItemIds:contains(item.Id)
end

packrat.setItemTracked = function(item, tracked)
    if tracked then
        packrat.settings.trackedItemIds:append(item.Id)
    else
        packrat.settings.trackedItemIds:delete(item.Id)
    end
    settings.save()
end

packrat.isIgnoredItemType = function(item)
    if item.StackSize > 1 then
        return false
    end
    return packrat.ignoredItemTypes:contains(item.Type)
end

packrat.drawConfigurationWindow = function()
    if not packrat.showConfiguration[1] then
        return
    end

    local char = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0) or 'Default';
    local windowName = string.format('Packrat Configuration###PackratConfig_%s', char);

    if not packrat.config_initialized then
        imgui.SetNextWindowPos({ packrat.settings.config_pos[1], packrat.settings.config_pos[2] }, ImGuiCond_Always)
    else
        imgui.SetNextWindowPos({ packrat.settings.config_pos[1], packrat.settings.config_pos[2] }, ImGuiCond_FirstUseEver)
    end

    if imgui.Begin(windowName, packrat.showConfiguration,
        bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav)) then
        
        local pos = { imgui.GetWindowPos() }

        if packrat.config_initialized then
            if pos[1] ~= packrat.settings.config_pos[1] or pos[2] ~= packrat.settings.config_pos[2] then
                packrat.settings.config_pos = { pos[1], pos[2] }
                settings.save()
            end
        else
            packrat.config_initialized = true
        end

        -- Horizontal mode toggle
        local changed = imgui.Checkbox("Horizontal Display Mode", packrat.horizontal_mode_ref)
        if changed then
            packrat.settings.horizontal_mode = packrat.horizontal_mode_ref[1]
            settings.save()
        end

        -- Opacity slider
        local opacity_ref = { packrat.settings.opacity }
        if imgui.SliderFloat("Opacity", opacity_ref, 0.0, 1.0, "%.2f") then
            packrat.settings.opacity = opacity_ref[1]
            settings.save()
        end

        imgui.Separator()

        -- Persistent reference table for item checkboxes
        packrat.tracked_refs = packrat.tracked_refs or T{}

        -- Trackable items
        local trackableItems = packrat.getTrackableItems()
        local itemIterator = 1

        trackableItems:each(function(item)
            -- Create or update the persistent reference table for this item
            if not packrat.tracked_refs[item.Id] then
                packrat.tracked_refs[item.Id] = { packrat.isItemTracked(item) }
            else
                packrat.tracked_refs[item.Id][1] = packrat.isItemTracked(item)
            end

            if (itemIterator + packrat.itemsPerColumn - 1) % packrat.itemsPerColumn == 0 then
                imgui.BeginGroup()
            end

            -- Checkbox
            if imgui.Checkbox(item.Name[1], packrat.tracked_refs[item.Id]) then
                packrat.setItemTracked(item, packrat.tracked_refs[item.Id][1])
            end

            -- End column group
            if itemIterator == trackableItems:length() or itemIterator % packrat.itemsPerColumn == 0 then
                imgui.EndGroup()
                if itemIterator ~= trackableItems:length() then
                    imgui.SameLine()
                end
            end

            itemIterator = itemIterator + 1
        end)
    end

    imgui.End()
end

packrat.drawTrackerWindow = function()
    -- Removes ImGui's thin black border outline
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0)
    local bg = { imgui.GetStyleColorVec4(ImGuiCol_WindowBg) }
    bg[4] = packrat.settings.opacity
    imgui.PushStyleColor(ImGuiCol_WindowBg, bg)

    -- Get character name for a unique internal ID
    local char = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0) or 'Default';
    local windowName = string.format('Packrat###PackratTracker_%s', char);

    -- Position Handling
    if not packrat.is_initialized then
        -- Force the window to the character-specific saved position on first load
        imgui.SetNextWindowPos({ packrat.settings.tracker_pos[1], packrat.settings.tracker_pos[2] }, ImGuiCond_Always)
    else
        imgui.SetNextWindowPos({ packrat.settings.tracker_pos[1], packrat.settings.tracker_pos[2] }, ImGuiCond_FirstUseEver)
    end

    if imgui.Begin(windowName, true,
        bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize,
                ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav)) then
        
        local pos = { imgui.GetWindowPos() }

        if packrat.is_initialized then
            if pos[1] ~= packrat.settings.tracker_pos[1] or pos[2] ~= packrat.settings.tracker_pos[2] then
                packrat.settings.tracker_pos = { pos[1], pos[2] }
                settings.save()
            end
        else
            packrat.is_initialized = true
        end

        if packrat.settings.trackedItemIds:length() > 0 then
            if packrat.settings.horizontal_mode then
                -- Horizontal mode
                packrat.settings.trackedItemIds:each(function(itemId)
                    local item = packrat.getItemById(itemId)
                    local count = packrat.getItemCount(item)
                    local stack = item.StackSize

                    imgui.SameLine()

                    local pop = false
                    if count == 0 then
                        imgui.PushStyleColor(ImGuiCol_Text, {1, 0, 0, 1})
                        pop = true
                    elseif stack > 1 and (count / stack) <= (1/3) then
                        imgui.PushStyleColor(ImGuiCol_Text, {1, 1, 0, 1})
                        pop = true
                    end

                    imgui.Text(string.format('%s: %d', item.Name[1], count))

                    imgui.SameLine()
                    imgui.PushStyleColor(ImGuiCol_Text, {0.3, 0.3, 0.3, 1})
                    imgui.Text('|')
                    imgui.PopStyleColor()

                    if pop then imgui.PopStyleColor() end
                end)
            else
                -- Vertical mode
                packrat.settings.trackedItemIds:each(function(itemId)
                    local item = packrat.getItemById(itemId)
                    local count = packrat.getItemCount(item)
                    local stack = item.StackSize
                    local startY = imgui.GetCursorPosY()

                    local tex = packrat.getItemTexture(item)
                    if tex then
                        imgui.Image(tex, {24, 24})
                    end

                    imgui.SameLine()
                    imgui.SetCursorPosY(startY + 6)

                    local pop = false
                    if count == 0 then
                        imgui.PushStyleColor(ImGuiCol_Text, {1, 0, 0, 1})
                        pop = true
                    elseif stack > 1 and (count / stack) <= (1/3) then
                        imgui.PushStyleColor(ImGuiCol_Text, {1, 1, 0, 1})
                        pop = true
                    end

                    imgui.Text(string.format('%s: %d', item.Name[1], count))
                    if pop then imgui.PopStyleColor() end

                    imgui.SetCursorPosY(startY)
                    imgui.Dummy({0, 27})
                end)
            end
        else
            imgui.TextDisabled("No items currently tracked.\n/packrat or /pr to config.")
        end
    end

    imgui.End()
    imgui.PopStyleColor()
    imgui.PopStyleVar()
end

ashita.events.register('d3d_present', 'present_cb', function ()
    local player = AshitaCore:GetMemoryManager():GetPlayer()

    if player ~= nil and player:GetMainJob() > 0 and player:GetIsZoning() == 0 then
        packrat.drawConfigurationWindow()
        packrat.drawTrackerWindow()
    end
end)

ashita.events.register('command', 'packrat_command', function(e)
    local args = e.command:args()
    if #args == 0 then return end

    if args[1] == '/pr' or args[1] == '/packrat' then
        packrat.showConfiguration[1] = not packrat.showConfiguration[1]
        return true
    end
end)
