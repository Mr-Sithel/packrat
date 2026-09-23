-- XIUI Cream Purple Theme
local imgui = require('imgui')

------------------------------------------------------------
-- MAIN COLOR PALETTE (WINDOWS, FRAMES, TEXT, ETC.)
------------------------------------------------------------
local THEME_COLORS = {
    -- Backgrounds (Deep, dark eggplant/warm plum tint)
    { ImGuiCol_WindowBg,             { 0.03, 0.02, 0.04, 0.95 } },
    { ImGuiCol_ChildBg,              { 0.01, 0.00, 0.01, 1.00 } },
    { ImGuiCol_PopupBg,              { 0.05, 0.04, 0.06, 0.95 } },

    -- Title bar (Muted dusty purple)
    { ImGuiCol_TitleBg,              { 0.14, 0.11, 0.18, 1.00 } },
    { ImGuiCol_TitleBgActive,        { 0.24, 0.18, 0.30, 1.00 } },
    { ImGuiCol_TitleBgCollapsed,     { 0.09, 0.07, 0.11, 0.95 } },

    -- Frames (input boxes, dropdowns, etc.)
    { ImGuiCol_FrameBg,              { 0.15, 0.12, 0.18, 0.90 } },
    { ImGuiCol_FrameBgHovered,       { 0.22, 0.18, 0.28, 0.90 } },
    { ImGuiCol_FrameBgActive,        { 0.30, 0.24, 0.38, 0.90 } },

    -- Headers
    { ImGuiCol_Header,               { 0.20, 0.16, 0.26, 1.00 } },
    { ImGuiCol_HeaderHovered,        { 0.28, 0.22, 0.36, 1.00 } },
    { ImGuiCol_HeaderActive,         { 0.38, 0.30, 0.48, 1.00 } },

    -- Buttons (Soft Lavender Purple)
    { ImGuiCol_Button,               { 0.22, 0.17, 0.28, 0.80 } },
    { ImGuiCol_ButtonHovered,        { 0.32, 0.25, 0.42, 0.90 } },
    { ImGuiCol_ButtonActive,         { 0.44, 0.34, 0.56, 1.00 } },

    -- Checkmark / sliders (Bright Pastel Purple Highlight)
    { ImGuiCol_CheckMark,            { 0.78, 0.65, 0.92, 1.00 } },
    { ImGuiCol_SliderGrab,           { 0.54, 0.44, 0.66, 1.00 } },
    { ImGuiCol_SliderGrabActive,     { 0.72, 0.58, 0.88, 1.00 } },

    -- Scrollbars
    { ImGuiCol_ScrollbarBg,          { 0.08, 0.06, 0.10, 1.00 } },
    { ImGuiCol_ScrollbarGrab,        { 0.22, 0.18, 0.28, 1.00 } },
    { ImGuiCol_ScrollbarGrabHovered, { 0.30, 0.24, 0.38, 1.00 } },
    { ImGuiCol_ScrollbarGrabActive,  { 0.38, 0.30, 0.48, 1.00 } },

    -- Borders / separators (Warm Cream Accents)
    { ImGuiCol_Border,               { 0.90, 0.85, 0.75, 0.20 } },
    { ImGuiCol_Separator,            { 0.50, 0.45, 0.40, 0.80 } },

    -- Text (Soft Warm Cream / Off-White)
    { ImGuiCol_Text,                 { 0.96, 0.93, 0.86, 0.90 } },
    { ImGuiCol_TextDisabled,         { 0.55, 0.50, 0.45, 1.00 } },

    -- Resize grips
    { ImGuiCol_ResizeGrip,           { 0.32, 0.25, 0.40, 0.80 } },
    { ImGuiCol_ResizeGripHovered,    { 0.44, 0.34, 0.54, 0.90 } },
    { ImGuiCol_ResizeGripActive,     { 0.56, 0.44, 0.70, 1.00 } },
}

------------------------------------------------------------
-- STYLE VARS (unchanged)
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
-- TAB BUTTON COLORS (purple version)
------------------------------------------------------------
local TAB_BUTTON_COLORS = {
    base    = {0.20, 0.16, 0.25, 0.90},
    hover   = {0.30, 0.24, 0.38, 0.95},
    active  = {0.40, 0.32, 0.52, 1.00},
}

------------------------------------------------------------
-- OPTIONAL ACCENT COLORS
------------------------------------------------------------
local ACCENT = {
    highlight = {0.96, 0.93, 0.86, 1.00},
    warning   = {1.00, 0.40, 0.40, 1.00},
    success   = {0.60, 0.90, 0.60, 1.00},
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