-- XIUI Gold Theme
-- https://github.com/tirem/XIUI
local imgui = require('imgui')

------------------------------------------------------------
-- MAIN COLOR PALETTE (WINDOWS, FRAMES, TEXT, ETC.)
------------------------------------------------------------
local THEME_COLORS = {
    -- Backgrounds
    { ImGuiCol_WindowBg,             { 0.060, 0.055, 0.045, 0.97 } },
    { ImGuiCol_ChildBg,              { 0.000, 0.000, 0.000, 1.00 } },
    { ImGuiCol_PopupBg,              { 0.098, 0.090, 0.075, 1.00 } },

    -- Title bar
    { ImGuiCol_TitleBg,              { 0.098, 0.090, 0.075, 1.00 } },
    { ImGuiCol_TitleBgActive,        { 0.137, 0.125, 0.106, 1.00 } },
    { ImGuiCol_TitleBgCollapsed,     { 0.060, 0.055, 0.045, 0.97 } },

    -- Frames
    { ImGuiCol_FrameBg,              { 0.125, 0.110, 0.086, 0.98 } },
    { ImGuiCol_FrameBgHovered,       { 0.173, 0.153, 0.122, 0.98 } },
    { ImGuiCol_FrameBgActive,        { 0.231, 0.200, 0.157, 0.98 } },

    -- Headers
    { ImGuiCol_Header,               { 0.137, 0.125, 0.106, 1.00 } },
    { ImGuiCol_HeaderHovered,        { 0.176, 0.161, 0.137, 1.00 } },
    { ImGuiCol_HeaderActive,         { 0.957, 0.855, 0.592, 0.30 } },

    -- Text
    { ImGuiCol_Text,                 { 0.878, 0.855, 0.812, 1.00 } },
    { ImGuiCol_TextDisabled,         { 0.765, 0.684, 0.474, 1.00 } },

    -- Buttons
    { ImGuiCol_Button,               { 0.137, 0.125, 0.106, 0.50 } },
    { ImGuiCol_ButtonHovered,        { 0.286, 0.239, 0.165, 0.35 } },
    { ImGuiCol_ButtonActive,         { 0.420, 0.353, 0.243, 0.65 } },

    -- Checkmark / sliders
    { ImGuiCol_CheckMark,            { 0.957, 0.855, 0.592, 1.00 } },
    { ImGuiCol_SliderGrab,           { 0.765, 0.684, 0.474, 1.00 } },
    { ImGuiCol_SliderGrabActive,     { 0.957, 0.855, 0.592, 1.00 } },

    -- Scrollbars
    { ImGuiCol_ScrollbarBg,          { 0.098, 0.090, 0.075, 1.00 } },
    { ImGuiCol_ScrollbarGrab,        { 0.176, 0.161, 0.137, 1.00 } },
    { ImGuiCol_ScrollbarGrabHovered, { 0.300, 0.275, 0.235, 1.00 } },
    { ImGuiCol_ScrollbarGrabActive,  { 0.765, 0.684, 0.474, 1.00 } },

    -- Separators / borders
    { ImGuiCol_Separator,            { 0.300, 0.275, 0.235, 1.00 } },
    { ImGuiCol_Border,               { 0.900, 0.820, 0.600, 0.30 } },

    -- Resize grips
    { ImGuiCol_ResizeGrip,           { 0.573, 0.512, 0.355, 1.00 } },
    { ImGuiCol_ResizeGripHovered,    { 0.765, 0.684, 0.474, 1.00 } },
    { ImGuiCol_ResizeGripActive,     { 0.957, 0.855, 0.592, 1.00 } },
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
    base    = {0.137, 0.125, 0.106, 0.8},
    hover   = {0.176, 0.161, 0.137, 1.0},
    active  = {0.3, 0.275, 0.235, 1.0},
}

------------------------------------------------------------
-- OPTIONAL ACCENT COLORS
------------------------------------------------------------
local ACCENT = {
    highlight = { 0.957, 0.855, 0.592, 1.00 },
    warning   = { 1.00, 0.40, 0.40, 1.00 },
    success   = { 0.40, 1.00, 0.40, 1.00 },
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

M.tabButton = TAB_BUTTON_COLORS
M.accent    = ACCENT

return M
