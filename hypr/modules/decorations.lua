-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 8,
		gaps_out = 20,

		border_size = 1,

		col = {
			active_border = { colors = { "rgb(45403d)" } },
			inactive_border = "rgba(45403d99)",
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,
	},

	decoration = {
		rounding = 15,
		rounding_power = 8,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 0.8,

		shadow = {
			enabled = true,
			range = 20,
			render_power = 3,
			color = 0xee121212,
		},

		blur = {
			enabled = true,
			size = 20,
			passes = 3,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

-- =========================
-- CURVES
-- =========================

hl.curve("easeOutQuint", {
	type = "bezier",
	points = { { 0.23, 1 }, { 0.32, 1 } },
})

hl.curve("easeInOutCubic", {
	type = "bezier",
	points = { { 0.65, 0.05 }, { 0.36, 1 } },
})

hl.curve("linear", {
	type = "bezier",
	points = { { 0, 0 }, { 1, 1 } },
})

hl.curve("almostLinear", {
	type = "bezier",
	points = { { 0.5, 0.5 }, { 0.75, 1 } },
})

hl.curve("quick", {
	type = "bezier",
	points = { { 0.15, 0 }, { 0.1, 1 } },
})

-- =========================
-- SPRING
-- =========================

hl.curve("easy", {
	type = "spring",
	mass = 1,
	stiffness = 238.1191,
	dampening = 24.21279333,
})

-- =========================
-- GLOBAL
-- =========================

hl.animation({
	leaf = "global",
	enabled = true,
	speed = 10,
	bezier = "easeInOutCubic",
})

-- =========================
-- BORDERS
-- =========================

hl.animation({
	leaf = "border",
	enabled = true,
	speed = 3.2,
	bezier = "easeOutQuint",
})

-- =========================
-- WINDOWS
-- =========================

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 2.5,
	bezier = "easeInOutCubic",
})

hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 2.6,
	bezier = "easeOutQuint",
	style = "popin 87%",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 2.8,
	bezier = "easeInOutCubic",
	style = "popin 87%",
})

-- =========================
-- FADE
-- =========================

hl.animation({
	leaf = "fadeIn",
	enabled = true,
	speed = 2.8,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "fadeOut",
	enabled = true,
	speed = 2.8,
	bezier = "easeInOutCubic",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 3.0,
	bezier = "easeInOutCubic",
})

-- =========================
-- LAYERS
-- =========================

hl.animation({
	leaf = "layers",
	enabled = true,
	speed = 2.8,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "layersIn",
	enabled = true,
	speed = 2.8,
	bezier = "easeOutQuint",
	style = "fade",
})

hl.animation({
	leaf = "layersOut",
	enabled = true,
	speed = 3.0,
	bezier = "easeInOutCubic",
	style = "fade",
})

hl.animation({
	leaf = "fadeLayersIn",
	enabled = true,
	speed = 2.8,
	bezier = "easeOutQuint",
})

hl.animation({
	leaf = "fadeLayersOut",
	enabled = true,
	speed = 3.0,
	bezier = "easeInOutCubic",
})

-- =========================
-- WORKSPACES
-- =========================

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 2.5,
	bezier = "easeInOutCubic",
	style = "fade",
})

hl.animation({
	leaf = "workspacesIn",
	enabled = true,
	speed = 2.7,
	bezier = "easeOutQuint",
	style = "fade",
})

hl.animation({
	leaf = "workspacesOut",
	enabled = true,
	speed = 2.7,
	bezier = "easeInOutCubic",
	style = "fade",
})

-- =========================
-- ZOOM
-- =========================

hl.animation({
	leaf = "zoomFactor",
	enabled = true,
	speed = 4,
	bezier = "easeOutQuint",
})
