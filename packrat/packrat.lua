addon.name = "packrat";
addon.author = "colorglut, (Thorny: Added tracking Wardrobe 1 & 2)";
addon.version = "0.2";
addon.desc = "Tracks items in your inventory, Wardrobe and Wardrobe 2.";
addon.link = "";

require('common');
local ffi = require('ffi');
local d3d = require('d3d8');
local settings = require('settings');
local imgui = require('imgui');
local d3d8dev = d3d.get_device();

local packrat = T{
    trackedItemIds = settings.load(T{}),
    itemTextures = T{},
    showConfiguration = {false},
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
};

--[[
* Registers a callback for the settings to monitor for character switches.
--]]
settings.register('settings', 'settings_update', function(s)
    if s then
        packrat.trackedItemIds = s;
    end

    settings.save();
end);

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

    local stackableItems = T{};

    for i = 1, 81 do
        local containerItem = inventory:GetContainerItem(0, i);

        if containerItem and containerItem.Count > 0 then
            local item = packrat.getItemById(containerItem.Id);

            if not stackableItems:contains(item) then
                stackableItems:append(item);
            end
        end
    end

    return stackableItems;
end

packrat.getTrackableItems = function()
    local inventoryItems = packrat.getInventoryStackableItems();

    inventoryItems = inventoryItems:filter(function(item)
        return not packrat.isIgnoredItemType(item);
    end);
     
    local inventoryItemIds = inventoryItems:map(function(item)
        return item.Id;
    end);

    packrat.trackedItemIds:each(function(itemId)
        if not inventoryItemIds:contains(itemId) then
            inventoryItems:append(packrat.getItemById(itemId));
        end
    end);

    return inventoryItems;
end

packrat.getItemCount = function(item)
    local inventory = AshitaCore:GetMemoryManager():GetInventory();

    local itemCount = 0;

    --[[for i = 1, 81 do
        local containerItem = inventory:GetContainerItem(0, i);

        if containerItem and containerItem.Id == item.Id then
            itemCount = itemCount + containerItem.Count;
        end
    end--]]

    --[[local containers = T { 0, 8, 10 }; --Inventory, wardrobe, wardrobe2
    for _,container in ipairs(containers) do
        for i = 1, 81 do
            local containerItem = inventory:GetContainerItem(container, i);

            if containerItem and containerItem.Id == item.Id then
                itemCount = itemCount + containerItem.Count;
            end
        end
    end--]]

    local containers = T { 0 }; --Inventory
    if (bit.band(item.Flags, 0x800) == 0x800) then
        containers:append(8);   -- Wardrobe
        containers:append(10);  -- WArdrobe 2
    end
    for _,container in ipairs(containers) do
        for i = 1, 81 do
            local containerItem = inventory:GetContainerItem(container, i);

            if containerItem and containerItem.Id == item.Id then
                itemCount = itemCount + containerItem.Count;
            end
        end
    end

    return itemCount;
end

packrat.isItemTracked = function(item)
    return packrat.trackedItemIds:contains(item.Id);
end

packrat.setItemTracked = function(item, tracked)
    if tracked then
        packrat.trackedItemIds:append(item.Id);
    else
        packrat.trackedItemIds:delete(item.Id);
    end

    settings.save();
end

packrat.isIgnoredItemType = function(item)
    if item.StackSize > 1 then
        return false;
    else
        return packrat.ignoredItemTypes:contains(item.Type);
    end
end

packrat.drawConfigurationWindow = function()
    if packrat.showConfiguration[1] and imgui.Begin('Packrat Configuration', packrat.showConfiguration, bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav)) then
        local trackableItems = packrat.getTrackableItems();
        local itemIterator = 1;

        trackableItems:each(function(item)
            if (itemIterator + packrat.itemsPerColumn - 1) % packrat. itemsPerColumn == 0 then
                imgui.BeginGroup();
            end

            if imgui.Checkbox(item.Name[1], {packrat.isItemTracked(item)}) then
                packrat.setItemTracked(item, not packrat.isItemTracked(item));
            end 

            if itemIterator == trackableItems:length() or itemIterator % packrat.itemsPerColumn == 0 then
                imgui.EndGroup();

                if itemIterator ~= trackableItems:length() then
                    imgui.SameLine();
                end
            end

            itemIterator = itemIterator + 1;
        end);
    end

    imgui.End();
end

packrat.drawTrackerWindow = function()
    if imgui.Begin('Packrat', true, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav)) then
        if packrat.trackedItemIds:length() > 0 then
            packrat.trackedItemIds:each(function(itemId)
                local item = packrat.getItemById(itemId);

                local itemTexture = packrat.getItemTexture(item);
                local itemCount = packrat.getItemCount(item);
                local itemStackSize = item.StackSize;

                if itemTexture then
                    imgui.Image(itemTexture, {24, 24});
                end

                imgui.SameLine();

                local popColor = false;

                if itemCount == 0 then
                    imgui.PushStyleColor(ImGuiCol_Text, {1, 0, 0, 1});
                    popColor = true;
                elseif itemStackSize > 1 and (itemCount / item.StackSize) <= (1 / 3) then
                    imgui.PushStyleColor(ImGuiCol_Text, {1, 1, 0, 1});
                    popColor = true;
                end

                imgui.Text(
                    string.format(
                        '%s: %d',
                        item.Name[1],
                        itemCount
                    )
                );

                if popColor then
                    imgui.PopStyleColor(1);
                end
            end);
        else
            imgui.Text("No items currently tracked.");
        end

        if imgui.Button("Configure") then
            packrat.showConfiguration[1] = not packrat.showConfiguration[1];
        end
    end

    imgui.End();
end

--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()
    local player = AshitaCore:GetMemoryManager():GetPlayer();

    if player ~= nil and player:GetMainJob() > 0 and player:GetIsZoning() == 0 then
        packrat.drawConfigurationWindow();

        packrat.drawTrackerWindow();
    end
end);
