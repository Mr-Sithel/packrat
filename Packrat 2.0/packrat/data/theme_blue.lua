-- XIUI Blue Theme
-- https://github.com/tirem/XIUI
local imgui = require('imgui')

------------------------------------------------------------
-- MAIN COLOR PALETTE (WINDOWS, FRAMES, TEXT, ETC.)
------------------------------------------------------------
local THEME_COLORS = {
    -- Backgrounds
    { ImGuiCol_WindowBg,             { 0.02, 0.02, 0.03, 0.95 } },
    { ImGuiCol_ChildBg,              { 0.00, 0.00, 0.00, 1.00 } },
    { ImGuiCol_PopupBg,              { 0.05, 0.05, 0.07, 0.95 } },

    -- Title bar
    { ImGuiCol_TitleBg,              { 0.05, 0.05, 0.10, 1.00 } },
    { ImGuiCol_TitleBgActive,        { 0.10, 0.10, 0.20, 1.00 } },
    { ImGuiCol_TitleBgCollapsed,     { 0.03, 0.03, 0.06, 0.95 } },

    -- Frames (input boxes, dropdowns, etc.)
    { ImGuiCol_FrameBg,              { 0.08, 0.08, 0.12, 0.90 } },
    { ImGuiCol_FrameBgHovered,       { 0.12, 0.12, 0.20, 0.90 } },
    { ImGuiCol_FrameBgActive,        { 0.18, 0.18, 0.30, 0.90 } },

    -- Headers
    { ImGuiCol_Header,               { 0.10, 0.10, 0.18, 1.00 } },
    { ImGuiCol_HeaderHovered,        { 0.15, 0.15, 0.25, 1.00 } },
    { ImGuiCol_HeaderActive,         { 0.20, 0.20, 0.35, 1.00 } },

    -- Buttons
    { ImGuiCol_Button,               { 0.10, 0.10, 0.18, 0.80 } },
    { ImGuiCol_ButtonHovered,        { 0.20, 0.20, 0.35, 0.90 } },
    { ImGuiCol_ButtonActive,         { 0.25, 0.25, 0.45, 1.00 } },

    -- Checkmark / sliders
    { ImGuiCol_CheckMark,            { 0.30, 0.50, 1.00, 1.00 } },
    { ImGuiCol_SliderGrab,           { 0.25, 0.45, 0.90, 1.00 } },
    { ImGuiCol_SliderGrabActive,     { 0.35, 0.55, 1.00, 1.00 } },

    -- Scrollbars
    { ImGuiCol_ScrollbarBg,          { 0.05, 0.05, 0.10, 1.00 } },
    { ImGuiCol_ScrollbarGrab,        { 0.20, 0.20, 0.35, 1.00 } },
    { ImGuiCol_ScrollbarGrabHovered, { 0.30, 0.30, 0.50, 1.00 } },
    { ImGuiCol_ScrollbarGrabActive,  { 0.40, 0.40, 0.65, 1.00 } },

    -- Borders / separators
    { ImGuiCol_Border,               { 0.30, 0.50, 1.00, 0.30 } },
    { ImGuiCol_Separator,            { 0.20, 0.30, 0.50, 1.00 } },

    -- Text
    { ImGuiCol_Text,                 { 1.00, 1.00, 1.00, 0.80 } },
    { ImGuiCol_TextDisabled,         { 0.40, 0.45, 0.55, 1.00 } },

    -- Resize grips
    { ImGuiCol_ResizeGrip,           { 0.20, 0.40, 0.80, 0.80 } },
    { ImGuiCol_ResizeGripHovered,    { 0.30, 0.50, 1.00, 0.90 } },
    { ImGuiCol_ResizeGripActive,     { 0.40, 0.60, 1.00, 1.00 } },
}

------------------------------------------------------------
-- STYLE VARS (PADDING, ROUNDING, ETC.)
------------------------------------------------------------
local THEME_VARS = {
    { ImGuiStyleVar_WindowPadding,    { 12, 12 } },
    { ImGuiStyleVar_FramePadding,     { 6, 4 } },
    { ImGuiStyleVar_ItemSpacing,      { 8, 7 } },
    { ImGuiStyleVar_FrameRounding,    4.0 },
    { ImGuiStyleVar_WindowRounding,   6.0 },
    { ImGuiStyleVar_ChildRounding,    4.0 },
    { ImGuiStyleVar_PopupRounding,    4.0 },
    { ImGuiStyleVar_ScrollbarRounding, 4.0 },
    { ImGuiStyleVar_GrabRounding,     4.0 },
    { ImGuiStyleVar_WindowBorderSize, 1.0 },
    { ImGuiStyleVar_ChildBorderSize,  1.0 },
    { ImGuiStyleVar_FrameBorderSize,  1.0 },
    { ImGuiStyleVar_WindowTitleAlign, { 0.5, 0.5 } },
}

------------------------------------------------------------
-- TAB BUTTON COLORS (USED IN TALLY TAB BAR)
------------------------------------------------------------
local TAB_BUTTON_COLORS = {
    base    = {0.10, 0.12, 0.20, 0.90},
    hover   = {0.20, 0.25, 0.40, 0.95},
    active  = {0.30, 0.40, 0.70, 1.00},
}

------------------------------------------------------------
-- OPTIONAL ACCENT COLORS (FOR FUTURE USE)
------------------------------------------------------------
local ACCENT = {
    highlight = {0.30, 0.50, 1.00, 1.00},
    warning   = {1.00, 0.40, 0.40, 1.00},
    success   = {0.40, 1.00, 0.40, 1.00},
}

------------------------------------------------------------
-- MODULE EXPORT
------------------------------------------------------------
local M = {}

function M.push()
    for _, e in ipairs(THEME_COLORS) do
        imgui.PushStyleColor(e[1], e[2])
    end
    for _, e in ipairs(THEME_VARS) do
        imgui.PushStyleVar(e[1], e[2])
    end
end

function M.pop()
    imgui.PopStyleVar(#THEME_VARS)
    imgui.PopStyleColor(#THEME_COLORS)
end

-- Export theme components
M.tabButton = TAB_BUTTON_COLORS
M.accent    = ACCENT

return M
