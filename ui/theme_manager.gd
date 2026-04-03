class_name ThemeManager
extends Node

const UI_ASSET_PATHS := {
	"base": {
		"panel_primary": "res://assets/ui/kenney_base/panel_primary.png",
		"panel_secondary": "res://assets/ui/kenney_base/panel_secondary.png",
		"button_primary_idle": "res://assets/ui/kenney_base/button_primary_idle.png",
		"button_primary_pressed": "res://assets/ui/kenney_base/button_primary_pressed.png",
		# Compatibility aliases while the rest of the UI still requests older semantic keys.
		"panel_fill": "res://assets/ui/kenney_base/panel_primary.png",
		"divider": "res://assets/ui/kenney_base/panel_secondary.png",
		"divider_fade": "res://assets/ui/kenney_base/panel_secondary.png",
	},
	"frames": {
		"card_frame_attack": "res://assets/ui/frames/card_frame_attack.png",
		"card_frame_skill": "res://assets/ui/frames/card_frame_skill.png",
		"card_frame_power": "res://assets/ui/frames/card_frame_power.png",
		# Compatibility aliases for existing callers.
		"card_border": "res://assets/ui/frames/card_frame_skill.png",
		"panel_border": "res://assets/ui/frames/panel_border.png",
	},
	"icons": {
		"ball": "res://assets/ui/icons/ball_tennis1.png",
		"ball_alt": "res://assets/ui/icons/ball_tennis2.png",
		"energy": "res://assets/icons/kenney_icons/energy.png",
		"health": "res://assets/icons/kenney_icons/health.png",
		"attack": "res://assets/icons/kenney_icons/attack.png",
		"defense": "res://assets/icons/kenney_icons/defense.png",
	},
	"backgrounds": {
		"hardcourt": "res://assets/ui/backgrounds/hardcourt.png",
		"grass": "res://assets/ui/backgrounds/grass.png",
		"clay": "res://assets/ui/backgrounds/clay.png",
		"tarmac": "res://assets/ui/backgrounds/tarmac.png",
	},
}

const PALETTE := {
	# Sapphire — primary UI chrome, default card fill, skill cards
	"primary":  Color(0.28, 0.62, 0.94, 1.0),
	# Jade — return, recovery, rest cards
	"jade":     Color(0.22, 0.72, 0.52, 1.0),
	# Ember — impact/damage call-outs; kept as named alias
	"impact":   Color(0.96, 0.52, 0.20, 1.0),
	# Amethyst — slice, trick, overlay cards
	"overlay":  Color(0.50, 0.22, 0.76, 1.0),
	# Crisp near-white body text
	"text":     Color(0.97, 0.99, 1.0, 1.0),
	# Very deep charcoal shadow
	"shadow":   Color(0.02, 0.02, 0.06, 0.90),
	# Desaturated blue-grey for modifier/blocked/utility
	"neutral":  Color(0.54, 0.64, 0.76, 1.0),
	# Championship gold — serve, signature, relic cards
	"gold":     Color(0.96, 0.80, 0.28, 1.0),
	# Court crimson — power shots
	"crimson":  Color(0.82, 0.18, 0.20, 1.0),
	# Topspin forest-green alias
	"positive": Color(0.32, 0.78, 0.46, 1.0),
}

const CARD_ROLE_STYLES := {
	# Each role gets a distinct jewel tone so cards are immediately legible by colour.
	"default":   {"fill": "primary",  "accent": "primary",  "icon_texture": "energy",  "frame_texture": "card_frame_attack"},
	"serve":     {"fill": "gold",     "accent": "gold",     "icon_texture": "attack",  "frame_texture": "card_frame_power"},
	"return":    {"fill": "jade",     "accent": "jade",     "icon_texture": "defense", "frame_texture": "card_frame_attack"},
	"topspin":   {"fill": "positive", "accent": "positive", "icon_texture": "attack",  "frame_texture": "card_frame_attack"},
	"slice":     {"fill": "overlay",  "accent": "overlay",  "icon_texture": "attack",  "frame_texture": "card_frame_attack"},
	"modifier":  {"fill": "neutral",  "accent": "primary",  "icon_texture": "defense", "frame_texture": "card_frame_skill"},
	"power":     {"fill": "crimson",  "accent": "crimson",  "icon_texture": "attack",  "frame_texture": "card_frame_power"},
	"skill":     {"fill": "primary",  "accent": "primary",  "icon_texture": "defense", "frame_texture": "card_frame_skill"},
	"signature": {"fill": "gold",     "accent": "overlay",  "icon_texture": "attack",  "frame_texture": "card_frame_power"},
	"blocked":   {"fill": "neutral",  "accent": "neutral",  "icon_texture": "defense", "frame_texture": "card_frame_skill"},
	"rest":      {"fill": "jade",     "accent": "jade",     "icon_texture": "health",  "frame_texture": "card_frame_skill"},
	"route":     {"fill": "primary",  "accent": "primary",  "icon_texture": "energy",  "frame_texture": "card_frame_skill"},
	"relic":     {"fill": "gold",     "accent": "gold",     "icon_texture": "health",  "frame_texture": "card_frame_power"},
	"skip":      {"fill": "neutral",  "accent": "overlay",  "icon_texture": "defense", "frame_texture": "card_frame_skill"},
}

const PANEL_VARIANT_TEXTURES := {
	"primary": "panel_primary",
	"secondary": "panel_secondary",
	"hero": "panel_primary",
	"subtle": "panel_secondary",
	"chip": "panel_secondary",
	"arena": "panel_secondary",
}

const PANEL_VARIANT_TINTS := {
	"primary": 0.82,
	"secondary": 0.70,
	"hero": 0.76,
	"subtle": 0.62,
	"chip": 0.66,
	"arena": 0.74,
}

var _texture_cache: Dictionary = {}

func get_palette() -> Dictionary:
	return PALETTE.duplicate(true)

func get_asset_paths() -> Dictionary:
	return UI_ASSET_PATHS.duplicate(true)

func get_texture(category: String, name: String) -> Texture2D:
	var category_assets: Dictionary = Dictionary(UI_ASSET_PATHS.get(category, {}))
	var path := String(category_assets.get(name, ""))
	if path == "":
		return null
	return _load_texture(path)

func get_background_texture(surface_key: String) -> Texture2D:
	var normalized := surface_key.strip_edges().to_lower()
	if normalized == "us_open":
		normalized = "hardcourt"
	if not Dictionary(UI_ASSET_PATHS.get("backgrounds", {})).has(normalized):
		normalized = "hardcourt"
	return get_texture("backgrounds", normalized)

func get_icon_texture(icon_kind: String) -> Texture2D:
	match icon_kind:
		"ball", "tennis_ball":
			return get_texture("icons", "ball")
		"energy", "stamina":
			return get_texture("icons", "energy")
		"health", "endurance", "fatigue":
			return get_texture("icons", "health")
		"attack", "pressure", "spin", "momentum", "serve":
			return get_texture("icons", "attack")
		"defense", "guard", "focus", "return":
			return get_texture("icons", "defense")
		_:
			return null

func get_combat_palette(major_theme: Dictionary = {}, player_subject: Dictionary = {}, enemy_subject: Dictionary = {}) -> Dictionary:
	var palette := get_palette()
	var primary: Color = Color(major_theme.get("accent", palette["primary"]))
	var border: Color = Color(major_theme.get("border", primary))
	var text_color: Color = Color(major_theme.get("text", palette["text"]))
	var player_accent: Color = Color(player_subject.get("accent_color", primary))
	var player_glow: Color = Color(player_subject.get("glow_color", primary))
	var enemy_accent: Color = Color(enemy_subject.get("accent_color", palette["impact"]))
	var enemy_glow: Color = Color(enemy_subject.get("glow_color", palette["overlay"]))
	return {
		"primary": primary,
		"positive": Color(palette["positive"]),
		"impact": Color(palette["impact"]),
		"overlay": Color(palette["overlay"]),
		"text": text_color,
		"neutral": border.lightened(0.10),
		"shadow": Color(palette["shadow"]),
		"player_accent": player_accent,
		"player_glow": player_glow,
		"enemy_accent": enemy_accent,
		"enemy_glow": enemy_glow,
		"court_border": border,
		"surface_texture": get_background_texture(String(major_theme.get("surface_key", "hardcourt"))),
	}

func make_panel_style(fill_color: Color, border_color: Color, options: Dictionary = {}) -> StyleBox:
	var use_texture := bool(options.get("use_texture", true))
	var radius := int(options.get("radius", 20))
	var shadow_alpha := float(options.get("shadow_alpha", 0.40))
	var border_width := int(options.get("border_width", 2))
	var variant := String(options.get("variant", "primary"))
	var texture_category := String(options.get("texture_category", "base"))
	var texture_key := String(options.get("texture_key", PANEL_VARIANT_TEXTURES.get(variant, "panel_primary")))
	var tint_strength := float(options.get("tint_strength", PANEL_VARIANT_TINTS.get(variant, 0.82)))
	var texture := get_texture(texture_category, texture_key) if use_texture else null
	if texture != null:
		var textured := StyleBoxTexture.new()
		textured.texture = texture
		var texture_tint := Color(1.0, 1.0, 1.0, fill_color.a).lerp(fill_color, clampf(tint_strength, 0.0, 1.0))
		texture_tint.a = fill_color.a
		textured.modulate_color = texture_tint
		textured.draw_center = true
		textured.content_margin_left = float(options.get("content_margin_left", 10.0))
		textured.content_margin_right = float(options.get("content_margin_right", 10.0))
		textured.content_margin_top = float(options.get("content_margin_top", 8.0))
		textured.content_margin_bottom = float(options.get("content_margin_bottom", 8.0))
		textured.texture_margin_left = float(options.get("texture_margin_left", 14.0))
		textured.texture_margin_right = float(options.get("texture_margin_right", 14.0))
		textured.texture_margin_top = float(options.get("texture_margin_top", 14.0))
		textured.texture_margin_bottom = float(options.get("texture_margin_bottom", 14.0))
		return textured
	return _build_flat_style(fill_color, border_color, radius, shadow_alpha, border_width)

func make_button_style(fill_color: Color, border_color: Color, text_color: Color, state: String = "normal", options: Dictionary = {}) -> Dictionary:
	var state_fill := fill_color
	var state_border := border_color
	var texture_key := "button_primary_idle"
	match state:
		"hover":
			state_fill = fill_color.lightened(0.08)
			state_border = border_color.lightened(0.08)
		"pressed":
			state_fill = fill_color.darkened(0.10)
			state_border = border_color.darkened(0.04)
			texture_key = "button_primary_pressed"
		"disabled":
			state_fill = fill_color.darkened(0.18)
			state_border = border_color.lerp(fill_color, 0.42)
		_:
			pass
	return {
		"style": make_panel_style(state_fill, state_border, {
			"radius": 20,
			"shadow_alpha": 0.28 if state == "pressed" else 0.42,
			"border_width": 2,
			"texture_key": texture_key,
			"variant": String(options.get("variant", "primary")),
			"content_margin_left": 12.0,
			"content_margin_right": 12.0,
			"content_margin_top": 10.0,
			"content_margin_bottom": 10.0,
			"texture_margin_left": 14.0,
			"texture_margin_right": 14.0,
			"texture_margin_top": 14.0,
			"texture_margin_bottom": 14.0,
		}),
		"text_color": text_color,
	}

func decorate_card_presentation(presentation: Dictionary, payload: Dictionary, mode: String) -> Dictionary:
	var result := presentation.duplicate(true)
	var role := _card_role_for(payload, mode)
	var role_style: Dictionary = Dictionary(CARD_ROLE_STYLES.get(role, CARD_ROLE_STYLES["default"]))
	var palette := get_palette()
	var fill_key := String(role_style.get("fill", "primary"))
	var accent_key := String(role_style.get("accent", fill_key))
	var fill_color := Color(palette.get(fill_key, palette["primary"]))
	var accent_color := Color(palette.get(accent_key, fill_color))
	result["fill_color"] = _mix_fill(fill_color, role, mode)
	result["accent_color"] = accent_color.lightened(0.06)
	result["text_color"] = Color(palette["text"])
	result["chip_fill"] = Color(result["fill_color"]).darkened(0.18)
	result["chip_text"] = Color(palette["text"])
	result["art_fill"] = Color(result["fill_color"]).lightened(0.06)
	result["surface_texture"] = get_texture("base", "panel_secondary")
	result["frame_texture"] = get_texture("frames", String(role_style.get("frame_texture", "card_frame_skill")))
	result["divider_texture"] = get_texture("base", "divider_fade")
	var icon_texture_key := String(role_style.get("icon_texture", ""))
	if icon_texture_key != "":
		result["icon_texture"] = get_texture("icons", icon_texture_key)
	else:
		result["icon_texture"] = get_icon_texture(String(result.get("icon_kind", "")))
	return result

func _card_role_for(payload: Dictionary, mode: String) -> String:
	match mode:
		"relic_reward":
			return "relic"
		"skip":
			return "skip"
		"route":
			return "route"
		"rest_choice":
			return "rest"
		_:
			pass
	var tags := PackedStringArray(payload.get("tags", PackedStringArray()))
	if not bool(payload.get("playable", true)) and String(payload.get("block_reason", "")) != "":
		return "blocked"
	if tags.has("serve"):
		return "serve"
	if tags.has("return"):
		return "return"
	if tags.has("topspin"):
		return "topspin"
	if tags.has("slice"):
		return "slice"
	if tags.has("modifier"):
		return "modifier"
	if tags.has("power"):
		return "power"
	if tags.has("signature"):
		return "signature"
	if tags.has("skill") or tags.has("guard") or tags.has("recovery"):
		return "skill"
	return "default"

func _mix_fill(base_color: Color, role: String, mode: String) -> Color:
	var shadow := Color(PALETTE["shadow"])
	var mixed := base_color.darkened(0.42).lerp(shadow.lightened(0.08), 0.18)
	mixed.a = 0.97
	if mode == "stage_card":
		mixed = mixed.lightened(0.06)
	if role == "modifier":
		mixed = base_color.darkened(0.54).lerp(Color(PALETTE["neutral"]).darkened(0.36), 0.32)
		mixed.a = 0.97
	return mixed

func _build_flat_style(fill_color: Color, border_color: Color, radius: int, shadow_alpha: float, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_detail = 16
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	style.draw_center = true
	style.shadow_color = Color(0.01, 0.02, 0.05, shadow_alpha)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 5)
	style.expand_margin_bottom = 5.0
	style.expand_margin_left = 1.0
	style.expand_margin_right = 1.0
	style.expand_margin_top = 1.0
	style.border_blend = true
	return style

func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		var absolute_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(absolute_path):
			var image := Image.load_from_file(absolute_path)
			if image != null and not image.is_empty():
				texture = ImageTexture.create_from_image(image)
	_texture_cache[path] = texture
	return texture
