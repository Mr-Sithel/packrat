-- XIUI Ice Blue Theme
local imgui = require('imgui')

------------------------------------------------------------
-- MAIN COLOR PALETTE (WINDOWS, FRAMES, TEXT, ETC.)
------------------------------------------------------------
local THEME_COLORS = {
    -- Backgrounds (Deep cold slate/navy tint)
    { ImGuiCol_WindowBg,             { 0.02, 0.02, 0.04, 0.95 } },
    { ImGuiCol_ChildBg,              { 0.00, 0.00, 0.01, 1.00 } },
    { ImGuiCol_PopupBg,              { 0.04, 0.05, 0.07, 0.95 } },

    -- Title bar (Frozen deep blues)
    { ImGuiCol_TitleBg,              { 0.08, 0.11, 0.16, 1.00 } },
    { ImGuiCol_TitleBgActive,        { 0.15, 0.20, 0.30, 1.00 } },
    { ImGuiCol_TitleBgCollapsed,     { 0.05, 0.07, 0.10, 0.95 } },

    -- Frames (input boxes, dropdowns, etc.)
    { ImGuiCol_FrameBg,              { 0.11, 0.14, 0.20, 0.90 } },
    { ImGuiCol_FrameBgHovered,       { 0.18, 0.24, 0.32, 0.90 } },
    { ImGuiCol_FrameBgActive,        { 0.25, 0.34, 0.45, 0.90 } },

    -- Headers
    { ImGuiCol_Header,               { 0.15, 0.22, 0.32, 1.00 } },
    { ImGuiCol_HeaderHovered,        { 0.22, 0.31, 0.45, 1.00 } },
    { ImGuiCol_HeaderActive,         { 0.30, 0.42, 0.58, 1.00 } },

    -- Buttons (Crisp Frost Blue)
    { ImGuiCol_Button,               { 0.16, 0.24, 0.35, 0.80 } },
    { ImGuiCol_ButtonHovered,        { 0.24, 0.36, 0.52, 0.90 } },
    { ImGuiCol_ButtonActive,         { 0.34, 0.50, 0.70, 1.00 } },

    -- Checkmark / sliders (Bright Glacier Highlights)
    { ImGuiCol_CheckMark,            { 0.60, 0.85, 1.00, 1.00 } },
    { ImGuiCol_SliderGrab,           { 0.45, 0.70, 0.90, 1.00 } },
    { ImGuiCol_SliderGrabActive,     { 0.70, 0.92, 1.00, 1.00 } },

    -- Scrollbars
    { ImGuiCol_ScrollbarBg,          { 0.06, 0.08, 0.12, 1.00 } },
    { ImGuiCol_ScrollbarGrab,        { 0.18, 0.26, 0.36, 1.00 } },
    { ImGuiCol_ScrollbarGrabHovered, { 0.26, 0.36, 0.50, 1.00 } },
    { ImGuiCol_ScrollbarGrabActive,  { 0.34, 0.46, 0.64, 1.00 } },

    -- Borders / separators
    { ImGuiCol_Border,               { 0.50, 0.75, 0.95, 0.25 } },
    { ImGuiCol_Separator,            { 0.35, 0.50, 0.68, 1.00 } },

    -- Text (Crisp frosted white)
    { ImGuiCol_Text,                 { 0.92, 0.96, 1.00, 0.90 } },
    { ImGuiCol_TextDisabled,         { 0.45, 0.52, 0.60, 1.00 } },

    -- Resize grips
    { ImGuiCol_ResizeGrip,           { 0.25, 0.38, 0.52, 0.80 } },
    { ImGuiCol_ResizeGripHovered,    { 0.35, 0.52, 0.70, 0.90 } },
    { ImGuiCol_ResizeGripActive,     { 0.45, 0.65, 0.88, 1.00 } },
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
-- TAB BUTTON COLORS (ice blue version)
------------------------------------------------------------
local TAB_BUTTON_COLORS = {
    base    = {0.15, 0.23, 0.34, 0.90},
    hover   = {0.22, 0.34, 0.50, 0.95},
    active  = {0.30, 0.46, 0.68, 1.00},
}

------------------------------------------------------------
-- OPTIONAL ACCENT COLORS
------------------------------------------------------------
local ACCENT = {
    highlight = {0.60, 0.85, 1.00, 1.00},
    warning   = {1.00, 0.40, 0.40, 1.00},
    success   = {0.40, 0.90, 1.00, 1.00},
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