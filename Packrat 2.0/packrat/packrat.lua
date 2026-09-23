addon.name = "packrat";
addon.author = "colorglut, (Amended by: Sithel)";
addon.version = "2.0.0";
addon.desc = "Tracks items in your inventory, Wardrobe and Wardrobe 2. Adding extra features to the original Packrat addon by colorglut.";
addon.link = "";

require('common');
local ffi = require('ffi');
local d3d = require('d3d8');
local settings = require('settings');
local imgui = require('imgui');
local d3d8dev = d3d.get_device();

-- Default settings
local default_settings = T{
    theme = 'gold',
    trackedItemIds = T{},
    horizontal_mode = false,
    show_icons = true,
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
    show_icons_ref = { packrat_settings.show_icons ~= false },
    is_initialized = false,
    ignoredItemTypes = T{
        1, -- Currency/Ninja tools
        2, -- Quest Items?
        4, -- Weapon
        5, -- Equipment
        6, -- Linkpearl
    },

    itemsPerColumn = 6,
    orderItemsPerColumn = 10 -- Set max items per column in Display Order section
}
packrat.trackerVisible = true

-- Themes
local function loadTheme(name)
    return require('data/theme_' .. name)
end

local current_loaded_theme_name = nil
local theme = nil

local function updateActiveTheme()
    local target_theme = packrat.settings.theme or 'gold'
    if current_loaded_theme_name ~= target_theme then
        theme = loadTheme(target_theme)
        current_loaded_theme_name = target_theme
    end
end

updateActiveTheme()

settings.register('settings', 'settings_update', function(s)
    if s then
        packrat.settings = s
        packrat.horizontal_mode_ref = { packrat.settings.horizontal_mode }
        packrat.show_icons_ref = { packrat.settings.show_icons ~= false }
        updateActiveTheme()
    end
end)

-- Login Event
ashita.events.register('login', 'login_cb', function()
    local loaded = settings.load(default_settings)
    if loaded then
        packrat.settings = loaded
    end
    updateActiveTheme()
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

packrat.moveTrackedItemUp = function(itemId)
    local index = packrat.settings.trackedItemIds:find(itemId)
    if index and index > 1 then
        local temp = packrat.settings.trackedItemIds[index]
        packrat.settings.trackedItemIds[index] = packrat.settings.trackedItemIds[index - 1]
        packrat.settings.trackedItemIds[index - 1] = temp
        settings.save()
    end
end

packrat.moveTrackedItemDown = function(itemId)
    local index = packrat.settings.trackedItemIds:find(itemId)
    if index and index < packrat.settings.trackedItemIds:length() then
        local temp = packrat.settings.trackedItemIds[index]
        packrat.settings.trackedItemIds[index] = packrat.settings.trackedItemIds[index + 1]
        packrat.settings.trackedItemIds[index + 1] = temp
        settings.save()
    end
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

    if theme then theme.push() end

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

        -- Toggles
        if imgui.Checkbox("Horizontal Display Mode", packrat.horizontal_mode_ref) then
            packrat.settings.horizontal_mode = packrat.horizontal_mode_ref[1]
            settings.save()
        end
        imgui.SameLine()
        imgui.TextDisabled('(?)')
        if imgui.IsItemHovered() then
            imgui.SetTooltip(' Displays tracked items in a single horizontal line instead of vertically stacked.\n\nBest for tracking a small number of items.\n\nThis mode does not display icons');
        end

        if imgui.Checkbox("Show Item Icons", packrat.show_icons_ref) then
            packrat.settings.show_icons = packrat.show_icons_ref[1]
            settings.save()
        end
        imgui.SameLine()
        imgui.TextDisabled('(?)')
        if imgui.IsItemHovered() then
            imgui.SetTooltip(' Displays the item icon next to the item count in the tracker window.\n\nThis option is only available in vertical display mode.');
        end

        -- Opacity slider
        local opacity_ref = { packrat.settings.opacity }
        if imgui.SliderFloat("Opacity", opacity_ref, 0.0, 1.0, "%.2f") then
            packrat.settings.opacity = opacity_ref[1]
            settings.save()
        end

        -- Theme selection
        imgui.Text("Theme")
        imgui.SameLine()
        imgui.TextDisabled("(?)")
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Choose a color theme for Packrat.")
        end

        local themes  = { 'gold', 'blue', 'red', 'green', 'purple', 'ice', 'gray'}
        local current = packrat.settings.theme or 'gold'

        imgui.PushItemWidth(140)
        if imgui.BeginCombo("##packrat_theme_select", current) then
            for _, t in ipairs(themes) do
                local selected = (t == current)
                if imgui.Selectable(t, selected) then
                    packrat.settings.theme = t
                    settings.save()
                    updateActiveTheme()
                end
                if selected then imgui.SetItemDefaultFocus() end
            end
            imgui.EndCombo()
        end
        imgui.PopItemWidth()

        imgui.Separator()

        -- Checkboxes
        packrat.tracked_refs = packrat.tracked_refs or T{}
        local trackableItems = packrat.getTrackableItems()
        local itemIterator = 1

        trackableItems:each(function(item)
            if not packrat.tracked_refs[item.Id] then
                packrat.tracked_refs[item.Id] = { packrat.isItemTracked(item) }
            else
                packrat.tracked_refs[item.Id][1] = packrat.isItemTracked(item)
            end

            if (itemIterator + packrat.itemsPerColumn - 1) % packrat.itemsPerColumn == 0 then
                imgui.BeginGroup()
            end

            if imgui.Checkbox(item.Name[1], packrat.tracked_refs[item.Id]) then
                packrat.setItemTracked(item, packrat.tracked_refs[item.Id][1])
            end

            if itemIterator == trackableItems:length() or itemIterator % packrat.itemsPerColumn == 0 then
                imgui.EndGroup()
                if itemIterator ~= trackableItems:length() then
                    imgui.SameLine()
                end
            end

            itemIterator = itemIterator + 1
        end)

        -- Display Order Column Layout 
        if packrat.settings.trackedItemIds:length() > 0 then
            imgui.Separator()
            
            if imgui.CollapsingHeader("Display Order Configuration") then
                local totalItems = packrat.settings.trackedItemIds:length()
                local orderIterator = 1
                local toMoveUp, toMoveDown = nil, nil

                packrat.settings.trackedItemIds:each(function(itemId, idx)
                    local item = packrat.getItemById(itemId)
                    if item then
                        if (orderIterator - 1) % packrat.orderItemsPerColumn == 0 then
                            imgui.BeginGroup()
                        end

                        imgui.PushID(itemId)

                        if imgui.ArrowButton("##up", ImGuiDir_Up) then toMoveUp = itemId end
                        imgui.SameLine()
                        if imgui.ArrowButton("##down", ImGuiDir_Down) then toMoveDown = itemId end
                        imgui.SameLine()
                        imgui.Text(string.format("%d. %s", idx, item.Name[1]))

                        imgui.PopID()

                        if orderIterator == totalItems or orderIterator % packrat.orderItemsPerColumn == 0 then
                            imgui.EndGroup()
                            if orderIterator ~= totalItems then
                                imgui.SameLine()
                            end
                        end

                        orderIterator = orderIterator + 1
                    end
                end)

                if toMoveUp then packrat.moveTrackedItemUp(toMoveUp) end
                if toMoveDown then packrat.moveTrackedItemDown(toMoveDown) end
            end
        end
    end

    imgui.End()
    if theme then theme.pop() end
end

packrat.drawTrackerWindow = function()
    local opacity = packrat.settings.opacity or 0.8

    imgui.SetNextWindowBgAlpha(opacity)
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 0)
    imgui.PushStyleColor(ImGuiCol_WindowBg, {0.0, 0.0, 0.0, opacity})

    local char = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0) or 'Default';
    local windowName = string.format('Packrat###PackratTracker_%s', char);

    if not packrat.is_initialized then
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
            local function drawItemEntry(item, count, stack)
                local curX = imgui.GetCursorPosX()
                local curY = imgui.GetCursorPosY()

                -- Draw standard item name
                imgui.Text(string.format('%s: ', item.Name[1]))

                local nameWidth = imgui.CalcTextSize(string.format('%s: ', item.Name[1]))

                imgui.SetCursorPos({ curX + nameWidth, curY })

                local ratio = count / stack

                if count == 0 then
                    -- Red when out of stock
                    imgui.TextColored({1, 0, 0, 1}, tostring(count))
                elseif stack > 1 and ratio <= (1/3) then
                    -- Orange for the lowest 1/3 stack (33% or less)
                    imgui.TextColored({1, 0.5, 0, 1}, tostring(count))
                elseif stack > 1 and ratio <= (2/3) then
                    -- Yellow for the middle 1/3 stack (between 34% and 66%)
                    imgui.TextColored({1, 1, 0, 1}, tostring(count))
                else
                    -- Green for the top 1/3 stack (above 66%)
                    imgui.TextColored({0, 1, 0, 1}, tostring(count))
                end
            end

            if packrat.settings.horizontal_mode then
                packrat.settings.trackedItemIds:each(function(itemId)
                    local item = packrat.getItemById(itemId)
                    local count = packrat.getItemCount(item)
                    local stack = item.StackSize

                    imgui.SameLine()
                    drawItemEntry(item, count, stack)

                    imgui.SameLine()
                    imgui.PushStyleColor(ImGuiCol_Text, {0.3, 0.3, 0.3, 1})
                    imgui.Text('|')
                    imgui.PopStyleColor()
                end)
            else
                packrat.settings.trackedItemIds:each(function(itemId)
                    local item = packrat.getItemById(itemId)
                    local count = packrat.getItemCount(item)
                    local stack = item.StackSize
                    local showIcons = packrat.settings.show_icons ~= false

                    if showIcons then
                        local startY = imgui.GetCursorPosY()
                        local tex = packrat.getItemTexture(item)
                        if tex then
                            imgui.Image(tex, {24, 24})
                        end

                        imgui.SameLine()
                        imgui.SetCursorPosY(startY + 3)

                        drawItemEntry(item, count, stack)

                        imgui.SetCursorPosY(startY)
                        imgui.Dummy({0, 27})
                    else
                        drawItemEntry(item, count, stack)
                    end
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
        updateActiveTheme()
        packrat.drawConfigurationWindow()
        if packrat.trackerVisible then
            packrat.drawTrackerWindow()
        end
    end
end)

ashita.events.register('command', 'packrat_command', function(e)
    local args = e.command:args()
    if #args == 0 then return end

    if args[1] == '/pr' or args[1] == '/packrat' then
        if args[2] == 'h' then
            packrat.trackerVisible = not packrat.trackerVisible
            return true
        end

        packrat.showConfiguration[1] = not packrat.showConfiguration[1]
        return true
    end
end)