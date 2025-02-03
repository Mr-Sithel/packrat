addon.name = "packrath";
addon.author = "colorglut, (Thorny: Added tracking Wardrobe 1 & 2)";
addon.version = "0.2.1";
addon.desc = "simple horizontal version that tracks items in your inventory, Wardrobe and Wardrobe 2.";
addon.link = "";

require('common');
local ffi = require('ffi');
local d3d = require('d3d8');
local settings = require('settings');
local imgui = require('imgui');
local d3d8dev = d3d.get_device();

local packrath = T{
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
        packrath.trackedItemIds = s;
    end

    settings.save();
end);

packrath.getItemById = function(itemId)
    return AshitaCore:GetResourceManager():GetItemById(itemId);
end

packrath.getItemTexture = function(item)
    if not packrath.itemTextures:containskey(item.Id) then
        local texturePointer = ffi.new('IDirect3DTexture8*[1]');

        if ffi.C.D3DXCreateTextureFromFileInMemory(d3d8dev, item.Bitmap, item.ImageSize, texturePointer) ~= ffi.C.S_OK then
            return nil;
        end

        packrath.itemTextures[item.Id] = d3d.gc_safe_release(ffi.cast('IDirect3DTexture8*', texturePointer[0]));
    end

    return tonumber(ffi.cast("uint32_t", packrath.itemTextures[item.Id]));
end

packrath.getInventoryStackableItems = function()
    local inventory = AshitaCore:GetMemoryManager():GetInventory();

    local stackableItems = T{};

    for i = 1, 81 do
        local containerItem = inventory:GetContainerItem(0, i);

        if containerItem and containerItem.Count > 0 then
            local item = packrath.getItemById(containerItem.Id);

            if not stackableItems:contains(item) then
                stackableItems:append(item);
            end
        end
    end

    return stackableItems;
end

packrath.getTrackableItems = function()
    local inventoryItems = packrath.getInventoryStackableItems();

    inventoryItems = inventoryItems:filter(function(item)
        return not packrath.isIgnoredItemType(item);
    end);
     
    local inventoryItemIds = inventoryItems:map(function(item)
        return item.Id;
    end);

    packrath.trackedItemIds:each(function(itemId)
        if not inventoryItemIds:contains(itemId) then
            inventoryItems:append(packrath.getItemById(itemId));
        end
    end);

    return inventoryItems;
end

packrath.getItemCount = function(item)
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
        containers:append(8); --Wardrobe
        containers:append(10); --Wardrobe 2
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

packrath.isItemTracked = function(item)
    return packrath.trackedItemIds:contains(item.Id);
end

packrath.setItemTracked = function(item, tracked)
    if tracked then
        packrath.trackedItemIds:append(item.Id);
    else
        packrath.trackedItemIds:delete(item.Id);
    end

    settings.save();
end

packrath.isIgnoredItemType = function(item)
    if item.StackSize > 1 then
        return false;
    else
        return packrath.ignoredItemTypes:contains(item.Type);
    end
end

packrath.drawConfigurationWindow = function()
    if packrath.showConfiguration[1] and imgui.Begin('packrath Configuration', packrath.showConfiguration, bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav)) then
        local trackableItems = packrath.getTrackableItems();
        local itemIterator = 1;

        trackableItems:each(function(item)
            if (itemIterator + packrath.itemsPerColumn - 1) % packrath. itemsPerColumn == 0 then
                imgui.BeginGroup();
            end

            if imgui.Checkbox(item.Name[1], {packrath.isItemTracked(item)}) then
                packrath.setItemTracked(item, not packrath.isItemTracked(item));
            end 

            if itemIterator == trackableItems:length() or itemIterator % packrath.itemsPerColumn == 0 then
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

packrath.drawTrackerWindow = function()
    if imgui.Begin('packrath', true, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav)) then
        if imgui.Button("configure") then
            packrath.showConfiguration[1] = not packrath.showConfiguration[1];
        end
        if packrath.trackedItemIds:length() > 0 then
            packrath.trackedItemIds:each(function(itemId)
                local item = packrath.getItemById(itemId);

                local itemTexture = packrath.getItemTexture(item);
                local itemCount = packrath.getItemCount(item);
                local itemStackSize = item.StackSize;                

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
                        '%s: %d |',
                        item.Name[1],
                        itemCount
                    )
                );

                if popColor then
                    imgui.PopStyleColor(1);
                end
            end);
            
        else
            imgui.SameLine();
            imgui.Text("No items currently tracked.");
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
        packrath.drawConfigurationWindow();

        packrath.drawTrackerWindow();
    end
end);
