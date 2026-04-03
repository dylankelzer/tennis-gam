extends Control

const PlayerClassDatabaseScript = preload("res://scripts/data/player_class_database.gd")
const PlayerCardLogicTreeScript = preload("res://scripts/ai/player_card_logic_tree.gd")
const CardDatabaseScript = preload("res://scripts/data/card_database.gd")
const CharacterModelDatabaseScript = preload("res://scripts/data/character_model_database.gd")
const BadgeIconScript = preload("res://scripts/ui/badge_icon.gd")
const CardFaceButtonScript = preload("res://scripts/ui/card_face_button.gd")
const CheckpointHeaderArtScript = preload("res://scripts/ui/checkpoint_header_art.gd")
const CheckpointScreenControllerScript = preload("res://scripts/ui/checkpoint_screen_controller.gd")
const CheckpointPanePresenterScript = preload("res://scripts/ui/checkpoint_pane_presenter.gd")
const CombatScreenControllerScript = preload("res://scripts/ui/combat_screen_controller.gd")
const CombatHudPresenterScript = preload("res://scripts/ui/combat_hud_presenter.gd")
const FrontScreenControllerScript = preload("res://scripts/ui/front_screen_controller.gd")
const FrontScreenPresenterScript = preload("res://scripts/ui/front_screen_presenter.gd")
const MainThemeControllerScript = preload("res://scripts/ui/main_theme_controller.gd")
const MetaSidebarControllerScript = preload("res://scripts/ui/meta_sidebar_controller.gd")
const MainUITextBuilderScript = preload("res://scripts/ui/main_ui_text_builder.gd")
const MainPaneStatePresenterScript = preload("res://scripts/ui/main_pane_state_presenter.gd")
const MatchEventBusScript = preload("res://scripts/ui/match_event_bus.gd")
const PathSelectPanePresenterScript = preload("res://scripts/ui/path_select_pane_presenter.gd")
const PathSelectScreenControllerScript = preload("res://scripts/ui/path_select_screen_controller.gd")
const ThemeManagerScript = preload("res://scripts/ui/theme_manager.gd")
const UnitDatabaseScript = preload("res://scripts/data/unit_database.gd")
const UnlockProgressionScript = preload("res://scripts/systems/unlock_progression.gd")
const SaveManagerScript = preload("res://scripts/systems/save_manager.gd")
const RunStateScript = preload("res://scripts/systems/run_state.gd")
const ENABLE_ASSET_MAJOR_STINGER := true
const BEGIN_TOURNAMENT_TIMEOUT_SEC := 2.0
const BEGIN_TOURNAMENT_MAX_RECOVERY_ATTEMPTS := 3
const MAJOR_STINGER_PATHS := {
	"Australian Open": {
		"intro": "res://assets/audio/major_stingers/australian_open_intro.wav",
		"final": "res://assets/audio/major_stingers/australian_open_final.wav",
	},
	"Roland-Garros": {
		"intro": "res://assets/audio/major_stingers/roland_garros_intro.wav",
		"final": "res://assets/audio/major_stingers/roland_garros_final.wav",
	},
	"Wimbledon": {
		"intro": "res://assets/audio/major_stingers/wimbledon_intro.wav",
		"final": "res://assets/audio/major_stingers/wimbledon_final.wav",
	},
	"US Open": {
		"intro": "res://assets/audio/major_stingers/us_open_intro.wav",
		"final": "res://assets/audio/major_stingers/us_open_final.wav",
	},
	"Default": {
		"intro": "res://assets/audio/major_stingers/intro.wav",
		"final": "res://assets/audio/major_stingers/final.wav",
	},
}
const PORTRAIT_EXTENSIONS = ["png", "webp", "jpg", "jpeg"]
const PORTRAIT_BASE_PATH := "res://assets/ui/portraits"
const PRESENTATION_THEMES := {
	# ── Australian Open ──────────────────────────────────────────────────────────
	# Melbourne Park: Plexicushion blue hardcourt, vivid green outfield, southern-
	# hemisphere summer bleach. Deep sapphire base with clean azure highlights and
	# a hint of Australian heat-gold on current/boss map nodes.
	"Australian Open": {
		"background": Color(0.03, 0.08, 0.18),
		"panel": Color(0.05, 0.12, 0.26, 0.94),
		"panel_alt": Color(0.07, 0.17, 0.34, 0.96),
		"border": Color(0.22, 0.66, 0.96, 1.0),
		"accent": Color(0.66, 0.92, 1.0, 1.0),
		"text": Color(0.97, 0.99, 1.0, 1.0),
		"ambient": "Sharp hardcourt pop, bright stadium wash, fast night-session energy.",
		"notes_intro": [392.0, 523.25, 659.25, 783.99],
		"notes_final": [392.0, 493.88, 659.25, 783.99, 987.77],
		"map_palette": {
			"line": Color(0.09, 0.22, 0.42, 0.72),
			"line_completed": Color(0.38, 0.80, 0.96, 0.94),
			"line_accessible": Color(0.28, 0.68, 0.90, 0.88),
			"current": Color(1.0, 0.86, 0.32, 1.0),
			"completed": Color(0.10, 0.38, 0.56, 1.0),
			"regular": Color(0.12, 0.50, 0.72, 1.0),
			"elite": Color(0.90, 0.40, 0.16, 1.0),
			"boss": Color(0.98, 0.76, 0.20, 1.0),
			"event": Color(0.18, 0.52, 0.80, 1.0),
		},
	},
	# ── Roland-Garros ────────────────────────────────────────────────────────────
	# Stade Roland-Garros: Terre battue clay, deep ochre-rust courts, cool Parisian
	# overcast light. Dark burnt-umber base with warm terracotta panels; cream-gold
	# accent instead of neon orange to evoke the refined Parisian aesthetic.
	"Roland-Garros": {
		"background": Color(0.12, 0.06, 0.03),
		"panel": Color(0.18, 0.09, 0.05, 0.94),
		"panel_alt": Color(0.26, 0.13, 0.07, 0.96),
		"border": Color(0.88, 0.46, 0.18, 1.0),
		"accent": Color(1.0, 0.82, 0.56, 1.0),
		"text": Color(1.0, 0.97, 0.92, 1.0),
		"ambient": "Heavy clay footsteps, longer echoes, and grinding baseline tension.",
		"notes_intro": [196.0, 246.94, 293.66, 349.23],
		"notes_final": [196.0, 261.63, 329.63, 392.0, 440.0],
		"map_palette": {
			"line": Color(0.30, 0.13, 0.07, 0.72),
			"line_completed": Color(0.94, 0.62, 0.30, 0.94),
			"line_accessible": Color(0.78, 0.44, 0.20, 0.88),
			"current": Color(1.0, 0.86, 0.48, 1.0),
			"completed": Color(0.46, 0.20, 0.10, 1.0),
			"regular": Color(0.60, 0.27, 0.14, 1.0),
			"elite": Color(0.84, 0.42, 0.12, 1.0),
			"boss": Color(0.96, 0.68, 0.20, 1.0),
			"event": Color(0.52, 0.26, 0.14, 1.0),
		},
	},
	# ── Wimbledon ────────────────────────────────────────────────────────────────
	# The All England Club: close-cut rye grass, Wimbledon purple + green heritage
	# colours, white attire, hushed grandeur. Deep forest-green base with the iconic
	# Wimbledon purple as the primary border/accent rather than lime green.
	"Wimbledon": {
		"background": Color(0.04, 0.10, 0.05),
		"panel": Color(0.07, 0.15, 0.08, 0.94),
		"panel_alt": Color(0.10, 0.21, 0.11, 0.96),
		"border": Color(0.46, 0.16, 0.58, 1.0),
		"accent": Color(0.94, 0.99, 0.88, 1.0),
		"text": Color(0.98, 1.0, 0.97, 1.0),
		"ambient": "Close-cut grass hush, soft crowd murmurs, and quick net-rush pressure.",
		"notes_intro": [329.63, 392.0, 493.88, 659.25],
		"notes_final": [329.63, 440.0, 554.37, 659.25, 880.0],
		"map_palette": {
			"line": Color(0.14, 0.26, 0.12, 0.72),
			"line_completed": Color(0.74, 0.92, 0.64, 0.94),
			"line_accessible": Color(0.58, 0.82, 0.48, 0.88),
			"current": Color(0.96, 0.90, 0.44, 1.0),
			"completed": Color(0.22, 0.40, 0.18, 1.0),
			"regular": Color(0.28, 0.52, 0.22, 1.0),
			"elite": Color(0.46, 0.16, 0.58, 1.0),
			"boss": Color(0.78, 0.66, 0.22, 1.0),
			"event": Color(0.22, 0.44, 0.18, 1.0),
		},
	},
	# ── US Open ──────────────────────────────────────────────────────────────────
	# USTA Billie Jean King National Tennis Center: DecoTurf blue hardcourt under
	# blazing stadium lights, electric atmosphere, Arthur Ashe grandeur. Near-black
	# midnight base with electric blue lines and championship gold accent.
	"US Open": {
		"background": Color(0.02, 0.03, 0.10),
		"panel": Color(0.04, 0.06, 0.18, 0.94),
		"panel_alt": Color(0.06, 0.10, 0.26, 0.96),
		"border": Color(0.30, 0.58, 1.0, 1.0),
		"accent": Color(1.0, 0.86, 0.36, 1.0),
		"text": Color(0.96, 0.98, 1.0, 1.0),
		"ambient": "Night hardcourt thunder, loud walk-ons, and a scoreboard that never lets up.",
		"notes_intro": [293.66, 392.0, 466.16, 587.33],
		"notes_final": [293.66, 392.0, 523.25, 698.46, 932.33],
		"map_palette": {
			"line": Color(0.10, 0.17, 0.38, 0.72),
			"line_completed": Color(0.56, 0.80, 1.0, 0.94),
			"line_accessible": Color(0.36, 0.60, 0.96, 0.88),
			"current": Color(1.0, 0.82, 0.26, 1.0),
			"completed": Color(0.12, 0.22, 0.50, 1.0),
			"regular": Color(0.16, 0.36, 0.72, 1.0),
			"elite": Color(0.84, 0.30, 0.18, 1.0),
			"boss": Color(0.96, 0.60, 0.14, 1.0),
			"event": Color(0.20, 0.28, 0.62, 1.0),
		},
	},
	"Default": {
		"background": Color(0.06, 0.08, 0.10),
		"panel": Color(0.10, 0.13, 0.16, 0.94),
		"panel_alt": Color(0.13, 0.17, 0.20, 0.96),
		"border": Color(0.48, 0.62, 0.60, 1.0),
		"accent": Color(0.88, 0.92, 0.90, 1.0),
		"text": Color(0.94, 0.96, 0.95, 1.0),
		"ambient": "Neutral practice-court ambience.",
		"notes_intro": [261.63, 329.63, 392.0],
		"notes_final": [261.63, 329.63, 392.0, 523.25],
		"map_palette": {},
	},
}
const CLASS_ASSET_THEMES := {
	# Richer, deeper jewel tones — less neon, more character
	"novice":          {"accent": Color(0.46, 0.76, 0.98), "glow": Color(0.14, 0.48, 0.90), "frame": Color(0.90, 0.95, 1.0),  "inner": Color(0.04, 0.10, 0.24), "silhouette": "cap",   "energy": "arc"},
	"pusher":          {"accent": Color(0.36, 0.82, 0.52), "glow": Color(0.18, 0.62, 0.34), "frame": Color(0.88, 0.98, 0.90), "inner": Color(0.05, 0.16, 0.08), "silhouette": "cap",   "energy": "spiral"},
	"slicer":          {"accent": Color(0.72, 0.40, 0.94), "glow": Color(0.50, 0.18, 0.82), "frame": Color(0.96, 0.88, 1.0),  "inner": Color(0.12, 0.05, 0.20), "silhouette": "hero",  "energy": "spiral"},
	"power":           {"accent": Color(0.98, 0.50, 0.18), "glow": Color(0.86, 0.16, 0.08), "frame": Color(1.0, 0.92, 0.80),  "inner": Color(0.22, 0.05, 0.02), "silhouette": "brute", "energy": "burst"},
	"all_arounder":    {"accent": Color(0.36, 0.88, 0.80), "glow": Color(0.12, 0.68, 0.62), "frame": Color(0.88, 0.98, 0.96), "inner": Color(0.04, 0.14, 0.14), "silhouette": "hero",  "energy": "arc"},
	"baseliner":       {"accent": Color(0.72, 0.96, 0.28), "glow": Color(0.50, 0.80, 0.12), "frame": Color(0.96, 0.99, 0.82), "inner": Color(0.09, 0.14, 0.04), "silhouette": "brute", "energy": "flare"},
	"serve_and_volley":{"accent": Color(0.56, 0.76, 0.98), "glow": Color(0.18, 0.46, 0.90), "frame": Color(0.92, 0.96, 1.0),  "inner": Color(0.06, 0.10, 0.20), "silhouette": "cap",   "energy": "arc"},
	"master":          {"accent": Color(0.82, 0.90, 1.0),  "glow": Color(0.32, 0.56, 0.96), "frame": Color(0.98, 0.98, 1.0),  "inner": Color(0.06, 0.08, 0.16), "silhouette": "hood",  "energy": "spiral"},
	"alcaraz":         {"accent": Color(0.98, 0.88, 0.28), "glow": Color(0.88, 0.68, 0.08), "frame": Color(1.0, 0.97, 0.80),  "inner": Color(0.10, 0.10, 0.06), "silhouette": "brute", "energy": "burst"},
}
const STATUS_ICON_MAP := {
	"Momentum": "momentum",
	"Focus": "focus",
	"Pressure": "pressure",
	"Spin": "spin",
	"Fatigue": "fatigue",
	"Open Court": "open_court",
	"Thorns": "thorns",
	"Tilt": "tilt",
	"Cost": "cost_up",
	"Pos": "position_lock",
}
const FRONT_SCREEN_LANDING := "landing"
const FRONT_SCREEN_CLASS_SELECT := "class_select"
const FRONT_SCREEN_TRANSITION := "transition"

@onready var backdrop: ColorRect = $Backdrop
@onready var theme_manager: Node = $ThemeManager
@onready var root_vbox: VBoxContainer = $MarginContainer/VBox
@onready var header_box: VBoxContainer = $MarginContainer/VBox/Header
@onready var title_label: Label = $MarginContainer/VBox/Header/Title
@onready var subtitle_label: Label = $MarginContainer/VBox/Header/Subtitle
@onready var atmosphere_panel: PanelContainer = $MarginContainer/VBox/Header/AtmospherePanel
@onready var atmosphere_label: Label = $MarginContainer/VBox/Header/AtmospherePanel/AtmosphereMargin/AtmosphereLabel
@onready var landing_center: CenterContainer = $MarginContainer/VBox/LandingCenter
@onready var landing_panel: PanelContainer = $MarginContainer/VBox/LandingCenter/LandingPanel
@onready var landing_ball_icon: Control = $MarginContainer/VBox/LandingCenter/LandingPanel/LandingMargin/LandingVBox/LandingIcons/LandingBall
@onready var landing_racquet_icon: Control = $MarginContainer/VBox/LandingCenter/LandingPanel/LandingMargin/LandingVBox/LandingIcons/LandingRacquet
@onready var landing_trophy_icon: Control = $MarginContainer/VBox/LandingCenter/LandingPanel/LandingMargin/LandingVBox/LandingIcons/LandingTrophy
@onready var landing_portrait: Control = $MarginContainer/VBox/LandingCenter/LandingPanel/LandingMargin/LandingVBox/LandingPortrait
@onready var landing_start_button: Button = $MarginContainer/VBox/LandingCenter/LandingPanel/LandingMargin/LandingVBox/LandingStartButton
@onready var reveal_panel: PanelContainer = $MarginContainer/VBox/RevealPanel
@onready var reveal_title_label: Label = $MarginContainer/VBox/RevealPanel/RevealMargin/RevealVBox/RevealTitle
@onready var reveal_body_label: Label = $MarginContainer/VBox/RevealPanel/RevealMargin/RevealVBox/RevealBody
@onready var reveal_proceed_button: Button = $MarginContainer/VBox/RevealPanel/RevealMargin/RevealVBox/RevealActions/RevealProceedButton
@onready var dismiss_reveal_button: Button = $MarginContainer/VBox/RevealPanel/RevealMargin/RevealVBox/RevealActions/DismissRevealButton
@onready var action_callout_panel: PanelContainer = $MarginContainer/VBox/ActionCalloutPanel
@onready var action_callout_icon: Control = $MarginContainer/VBox/ActionCalloutPanel/ActionCalloutMargin/ActionCalloutRow/ActionCalloutIcon
@onready var action_callout_label: Label = $MarginContainer/VBox/ActionCalloutPanel/ActionCalloutMargin/ActionCalloutRow/ActionCalloutLabel
@onready var primary_action_button: Button = $MarginContainer/VBox/ActionCalloutPanel/ActionCalloutMargin/ActionCalloutRow/PrimaryActionButton
@onready var combat_stage_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel
@onready var stage_player_hud: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StagePlayerHud
@onready var stage_player_portrait: Control = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StagePlayerHud/StagePlayerHudMargin/StagePlayerHudVBox/StagePlayerPortrait
@onready var stage_player_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StagePlayerHud/StagePlayerHudMargin/StagePlayerHudVBox/StagePlayerTitle
@onready var stage_player_hud_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StagePlayerHud/StagePlayerHudMargin/StagePlayerHudVBox/StagePlayerHudBody
@onready var stage_score_hud: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud
@onready var stage_major_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin/StageScoreHudVBox/StageMajorLabel
@onready var stage_serve_state_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin/StageScoreHudVBox/StageServeStatePanel
@onready var stage_serve_state_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin/StageScoreHudVBox/StageServeStatePanel/StageServeStateMargin/StageServeStateLabel
@onready var stage_score_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin/StageScoreHudVBox/StageScoreLabel
@onready var stage_meta_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin/StageScoreHudVBox/StageMetaLabel
@onready var stage_pressure_meter: Control = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin/StageScoreHudVBox/StagePressureMeter
@onready var stage_enemy_hud: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageEnemyHud
@onready var stage_enemy_portrait: Control = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageEnemyHud/StageEnemyHudMargin/StageEnemyHudVBox/StageEnemyPortrait
@onready var stage_enemy_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageEnemyHud/StageEnemyHudMargin/StageEnemyHudVBox/StageEnemyTitle
@onready var stage_enemy_hud_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageEnemyHud/StageEnemyHudMargin/StageEnemyHudVBox/StageEnemyHudBody
@onready var stage_equipment_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow
@onready var stage_string_badge_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageStringBadgePanel
@onready var stage_string_badge_tag_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageStringBadgePanel/StageStringBadgeMargin/StageStringBadgeVBox/StageStringBadgeTag
@onready var stage_string_badge_name_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageStringBadgePanel/StageStringBadgeMargin/StageStringBadgeVBox/StageStringBadgeName
@onready var stage_string_badge_info_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageStringBadgePanel/StageStringBadgeMargin/StageStringBadgeVBox/StageStringBadgeInfo
@onready var stage_racquet_badge_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageRacquetBadgePanel
@onready var stage_racquet_badge_tag_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageRacquetBadgePanel/StageRacquetBadgeMargin/StageRacquetBadgeVBox/StageRacquetBadgeTag
@onready var stage_racquet_badge_name_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageRacquetBadgePanel/StageRacquetBadgeMargin/StageRacquetBadgeVBox/StageRacquetBadgeName
@onready var stage_racquet_badge_info_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageEquipmentRow/StageRacquetBadgePanel/StageRacquetBadgeMargin/StageRacquetBadgeVBox/StageRacquetBadgeInfo
@onready var stage_top_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow
@onready var stage_score_hud_margin: MarginContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageTopRow/StageScoreHud/StageScoreHudMargin
@onready var stage_arena_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel
@onready var stage_arena_root: Control = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot
@onready var stage_arena_view: Control = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaView
@onready var stage_player_unit_view: Node2D = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StagePlayerUnitView
@onready var stage_enemy_unit_view: Node2D = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageEnemyUnitView
@onready var stage_fx_root: Node2D = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageFXRoot
@onready var stage_arena_overlay: MarginContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay
@onready var stage_arena_top_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow
@onready var stage_flow_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageFlowPanel
@onready var stage_flow_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageFlowPanel/StageFlowMargin/StageFlowVBox/StageFlowBody
@onready var stage_rally_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageRallyPanel
@onready var stage_rally_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageRallyPanel/StageRallyMargin/StageRallyVBox/StageRallyBody
@onready var stage_intent_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageIntentPanel
@onready var stage_intent_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaTopRow/StageIntentPanel/StageIntentMargin/StageIntentVBox/StageIntentBody
@onready var stage_arena_bottom_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow
@onready var stage_player_pod: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StagePlayerPod
@onready var stage_player_pod_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StagePlayerPod/StagePlayerPodMargin/StagePlayerPodVBox/StagePlayerPodTitle
@onready var stage_player_status_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StagePlayerPod/StagePlayerPodMargin/StagePlayerPodVBox/StagePlayerStatusRow
@onready var stage_player_pod_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StagePlayerPod/StagePlayerPodMargin/StagePlayerPodVBox/StagePlayerPodBody
@onready var stage_enemy_pod: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StageEnemyPod
@onready var stage_enemy_pod_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StageEnemyPod/StageEnemyPodMargin/StageEnemyPodVBox/StageEnemyPodTitle
@onready var stage_enemy_status_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StageEnemyPod/StageEnemyPodMargin/StageEnemyPodVBox/StageEnemyStatusRow
@onready var stage_enemy_pod_body_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageArenaPanel/StageArenaMargin/StageArenaRoot/StageArenaOverlay/StageArenaVBox/StageArenaBottomRow/StageEnemyPod/StageEnemyPodMargin/StageEnemyPodVBox/StageEnemyPodBody
@onready var stage_stamina_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageStaminaPanel
@onready var stage_stamina_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageStaminaPanel/StageStaminaMargin/StageStaminaVBox/StageStaminaTitle
@onready var stage_stamina_value_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageStaminaPanel/StageStaminaMargin/StageStaminaVBox/StageStaminaValue
@onready var stage_stamina_meter: Control = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageStaminaPanel/StageStaminaMargin/StageStaminaVBox/StageStaminaMeter
@onready var stage_stamina_hint_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageStaminaPanel/StageStaminaMargin/StageStaminaVBox/StageStaminaHint
@onready var stage_footer_row: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow
@onready var stage_hand_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageHandPanel
@onready var stage_hand_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageHandPanel/StageHandMargin/StageHandVBox/StageHandTitle
@onready var stage_hand_scroll: ScrollContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageHandPanel/StageHandMargin/StageHandVBox/StageHandScroll
@onready var stage_hand_buttons: HBoxContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageHandPanel/StageHandMargin/StageHandVBox/StageHandScroll/StageHandButtons
@onready var stage_action_panel: PanelContainer = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageActionPanel
@onready var stage_end_turn_button: Button = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageActionPanel/StageActionMargin/StageActionVBox/StageEndTurnButton
@onready var stage_turn_hint_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageActionPanel/StageActionMargin/StageActionVBox/StageTurnHint
@onready var stage_event_feed_title_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageActionPanel/StageActionMargin/StageActionVBox/StageEventFeedTitle
@onready var stage_event_feed_label: Label = $MarginContainer/VBox/CombatStagePanel/CombatStageMargin/CombatStageVBox/StageFooterRow/StageActionPanel/StageActionMargin/StageActionVBox/StageEventFeed
@onready var rest_checkpoint_panel: PanelContainer = $MarginContainer/VBox/RestCheckpointPanel
@onready var rest_prompt_panel: PanelContainer = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestPromptPanel
@onready var rest_eyebrow_label: Label = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestPromptPanel/RestPromptMargin/RestPromptVBox/RestEyebrow
@onready var rest_question_label: Label = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestPromptPanel/RestPromptMargin/RestPromptVBox/RestQuestion
@onready var rest_summary_label: Label = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestPromptPanel/RestPromptMargin/RestPromptVBox/RestSummary
@onready var rest_ledger_panel: PanelContainer = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestLedgerPanel
@onready var rest_ledger_title_label: Label = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestLedgerPanel/RestLedgerMargin/RestLedgerVBox/RestLedgerTitle
@onready var rest_ledger_body_label: Label = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestTopRow/RestLedgerPanel/RestLedgerMargin/RestLedgerVBox/RestLedgerBody
@onready var rest_choice_row: HBoxContainer = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestChoiceRow
@onready var rest_scene_panel: PanelContainer = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestScenePanel
@onready var rest_scene_view: Control = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestScenePanel/RestSceneMargin/RestSceneRoot/RestSceneView
@onready var rest_hint_label: Label = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestBottomRow/RestHint
@onready var rest_leave_button: Button = $MarginContainer/VBox/RestCheckpointPanel/RestCheckpointMargin/RestCheckpointVBox/RestBottomRow/RestLeaveButton
@onready var top_bar: HBoxContainer = $MarginContainer/VBox/TopBar
@onready var class_header_label: Label = $MarginContainer/VBox/TopBar/ClassControls/ClassHeader
@onready var body_split: HSplitContainer = $MarginContainer/VBox/Body
@onready var prev_button: Button = $MarginContainer/VBox/TopBar/ClassControls/ClassNav/PrevClassButton
@onready var class_name_label: Label = $MarginContainer/VBox/TopBar/ClassControls/ClassNav/ClassName
@onready var next_button: Button = $MarginContainer/VBox/TopBar/ClassControls/ClassNav/NextClassButton
@onready var start_run_button: Button = $MarginContainer/VBox/TopBar/ClassControls/ActionRow/StartRunButton
@onready var continue_run_button: Button = $MarginContainer/VBox/TopBar/ClassControls/ActionRow/ContinueRunButton
@onready var reset_run_button: Button = $MarginContainer/VBox/TopBar/ClassControls/ActionRow/ResetRunButton
@onready var class_portrait: Control = $MarginContainer/VBox/TopBar/ClassControls/ClassPortrait
@onready var run_status_panel: PanelContainer = $MarginContainer/VBox/TopBar/RunStatusPanel
@onready var run_status_label: Label = $MarginContainer/VBox/TopBar/RunStatusPanel/RunStatusMargin/RunStatus
@onready var class_panel: PanelContainer = $MarginContainer/VBox/Body/LeftColumn/ClassPanel
@onready var class_margin: MarginContainer = $MarginContainer/VBox/Body/LeftColumn/ClassPanel/ClassMargin
@onready var class_view: RichTextLabel = $MarginContainer/VBox/Body/LeftColumn/ClassPanel/ClassMargin/ClassView
@onready var map_panel: PanelContainer = $MarginContainer/VBox/Body/LeftColumn/MapPanel
@onready var map_title_label: Label = $MarginContainer/VBox/Body/LeftColumn/MapPanel/MapMargin/MapVBox/MapTitle
@onready var map_view = $MarginContainer/VBox/Body/LeftColumn/MapPanel/MapMargin/MapVBox/MapView
@onready var node_info_label: Label = $MarginContainer/VBox/Body/LeftColumn/MapPanel/MapMargin/MapVBox/NodeInfo
@onready var right_column: VBoxContainer = $MarginContainer/VBox/Body/RightColumn
@onready var combat_panel: PanelContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel
@onready var combat_header_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/CombatHeader
@onready var match_summary_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/MatchSummary
@onready var launch_panel: PanelContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/LaunchPanel
@onready var launch_title_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/LaunchPanel/LaunchMargin/LaunchVBox/LaunchTitle
@onready var launch_body_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/LaunchPanel/LaunchMargin/LaunchVBox/LaunchBody
@onready var launch_start_button: Button = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/LaunchPanel/LaunchMargin/LaunchVBox/LaunchActions/LaunchStartButton
@onready var launch_continue_button: Button = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/LaunchPanel/LaunchMargin/LaunchVBox/LaunchActions/LaunchContinueButton
@onready var equipment_row: HBoxContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow
@onready var string_badge_panel: PanelContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/StringBadgePanel
@onready var string_badge_tag_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/StringBadgePanel/StringBadgeMargin/StringBadgeVBox/StringBadgeTag
@onready var string_badge_name_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/StringBadgePanel/StringBadgeMargin/StringBadgeVBox/StringBadgeName
@onready var string_badge_info_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/StringBadgePanel/StringBadgeMargin/StringBadgeVBox/StringBadgeInfo
@onready var racquet_badge_panel: PanelContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/RacquetBadgePanel
@onready var racquet_badge_tag_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/RacquetBadgePanel/RacquetBadgeMargin/RacquetBadgeVBox/RacquetBadgeTag
@onready var racquet_badge_name_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/RacquetBadgePanel/RacquetBadgeMargin/RacquetBadgeVBox/RacquetBadgeName
@onready var racquet_badge_info_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/EquipmentRow/RacquetBadgePanel/RacquetBadgeMargin/RacquetBadgeVBox/RacquetBadgeInfo
@onready var player_summary_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/SummaryRow/PlayerPanel/PlayerMargin/PlayerSummary
@onready var enemy_intent_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/SummaryRow/EnemyPanel/EnemyMargin/EnemyVBox/EnemyIntent
@onready var enemy_summary_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/SummaryRow/EnemyPanel/EnemyMargin/EnemyVBox/EnemySummary
@onready var end_turn_button: Button = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/Controls/EndTurnButton
@onready var hand_header_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/HandHeader
@onready var hand_scroll: ScrollContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/HandScroll
@onready var hand_buttons: HBoxContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/HandScroll/HandButtons
@onready var reward_header_label: Label = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/RewardHeader
@onready var reward_scroll: ScrollContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/RewardScroll
@onready var reward_buttons: HBoxContainer = $MarginContainer/VBox/Body/RightColumn/CombatPanel/CombatMargin/CombatVBox/RewardScroll/RewardButtons
@onready var log_panel: PanelContainer = $MarginContainer/VBox/Body/RightColumn/LogPanel
@onready var log_view: RichTextLabel = $MarginContainer/VBox/Body/RightColumn/LogPanel/LogMargin/LogVBox/LogView
@onready var major_stinger_player: AudioStreamPlayer = $MajorStingerPlayer

var _class_database: PlayerClassDatabase = PlayerClassDatabaseScript.new()
var _player_logic_tree: PlayerCardLogicTree = PlayerCardLogicTreeScript.new()
var _card_database: CardDatabase = CardDatabaseScript.new()
var _unit_database: UnitDatabase = UnitDatabaseScript.new()
var _model_database: CharacterModelDatabase = CharacterModelDatabaseScript.new()
var _unlock_progression: UnlockProgression = UnlockProgressionScript.new()
var _save_manager: SaveManager = SaveManagerScript.new()
var _run_state: RunState = RunStateScript.new()
var _combat_hud_presenter = null
var _combat_screen_controller = null
var _checkpoint_screen_controller = null
var _checkpoint_pane_presenter = null
var _front_screen_controller = null
var _front_screen_presenter = null
var _main_theme_controller = null
var _main_pane_state_presenter = null
var _meta_sidebar_controller = null
var _path_select_pane_presenter = null
var _path_select_screen_controller = null
var _ui_text_builder = null
var _progress: Dictionary = {}
var _available_classes: Array = []
var _selected_index: int = 0
var _run_completion_recorded: bool = false
var _last_audio_signature: String = ""
var _major_stinger_stream_cache: Dictionary = {}
var _right_scroll: ScrollContainer = null
var _combat_scroll: ScrollContainer = null
var _equipment_bonus_panel: PanelContainer = null
var _equipment_bonus_title_label: Label = null
var _equipment_bonus_body_label: Label = null
var _return_support_row: HBoxContainer = null
var _stage_return_support_row: HBoxContainer = null
var _shop_potion_panel: PanelContainer = null
var _shop_potion_title_label: Label = null
var _shop_potion_buttons: Container = null
var _shop_relic_panel: PanelContainer = null
var _shop_relic_title_label: Label = null
var _shop_relic_buttons: Container = null
var _shop_checkpoint_panel: PanelContainer = null
var _shop_prompt_panel: PanelContainer = null
var _shop_prompt_action_row: HBoxContainer = null
var _shop_eyebrow_label: Label = null
var _shop_question_label: Label = null
var _shop_summary_label: Label = null
var _shop_ledger_panel: PanelContainer = null
var _shop_ledger_title_label: Label = null
var _shop_ledger_body_label: Label = null
var _shop_market_panel: PanelContainer = null
var _shop_market_title_label: Label = null
var _shop_market_buttons: Container = null
var _shop_hint_label: Label = null
var _shop_leave_button_top: Button = null
var _shop_leave_button: Button = null
var _reward_checkpoint_panel: PanelContainer = null
var _reward_prompt_panel: PanelContainer = null
var _reward_eyebrow_label: Label = null
var _reward_question_label: Label = null
var _reward_summary_label: Label = null
var _reward_ledger_panel: PanelContainer = null
var _reward_ledger_title_label: Label = null
var _reward_ledger_body_label: Label = null
var _reward_bonus_panel: PanelContainer = null
var _reward_bonus_title_label: Label = null
var _reward_bonus_body_label: Label = null
var _reward_offer_panel: PanelContainer = null
var _reward_offer_title_label: Label = null
var _reward_offer_buttons: HBoxContainer = null
var _reward_hint_label: Label = null
var _reward_skip_button: Button = null
var _path_select_panel: PanelContainer = null
var _path_select_header_panel: PanelContainer = null
var _path_select_header_art: Control = null
var _path_select_prompt_panel: PanelContainer = null
var _path_select_eyebrow_label: Label = null
var _path_select_question_label: Label = null
var _path_select_summary_label: Label = null
var _path_select_info_panel: PanelContainer = null
var _path_select_info_title_label: Label = null
var _path_select_info_body_label: Label = null
var _path_select_map_panel: PanelContainer = null
var _path_select_map_title_label: Label = null
var _path_select_map_view = null
var _path_select_node_info_label: Label = null
var _path_select_hint_label: Label = null
var _combat_potion_panel: PanelContainer = null
var _combat_potion_title_label: Label = null
var _combat_potion_buttons: HBoxContainer = null
var _stage_potion_panel: PanelContainer = null
var _stage_potion_title_label: Label = null
var _stage_potion_buttons: HBoxContainer = null
var _class_showcase_panel: PanelContainer = null
var _class_showcase_portrait: Control = null
var _class_showcase_name_label: Label = null
var _class_showcase_subtitle_label: Label = null
var _class_showcase_meta_label: Label = null
var _class_showcase_chip_row: HBoxContainer = null
var _class_content_vbox: VBoxContainer = null
var _rest_header_panel: PanelContainer = null
var _rest_header_art: Control = null
var _shop_header_panel: PanelContainer = null
var _shop_header_art: Control = null
var _shop_header_leave_button: Button = null
var _reward_header_panel: PanelContainer = null
var _reward_header_art: Control = null
var _accessibility_button: Button = null
var _accessibility_overlay: Control = null
var _accessibility_panel: PanelContainer = null
var _accessibility_ui_scale_slider: Range = null
var _accessibility_ui_scale_value_label: Label = null
var _accessibility_font_scale_slider: Range = null
var _accessibility_font_scale_value_label: Label = null
var _accessibility_high_contrast_check: CheckBox = null
var _accessibility_reduced_motion_check: CheckBox = null
var _accessibility_binding_rows: Dictionary = {}
var _accessibility_binding_hint_label: Label = null
var _awaiting_rebind_action: String = ""
var _front_screen_mode: String = FRONT_SCREEN_LANDING
var _begin_tournament_in_progress: bool = false
var _pending_start_seed: int = 0
var _begin_tournament_recovery_attempts: int = 0
var _last_stage_point_context: String = ""
var _point_context_flash_tween: Tween = null
var _major_stinger_cleanup_tween: Tween = null
var _telemetry_last_phase: String = ""
var _telemetry_last_match_key: String = ""
var _telemetry_event_cursor: int = 0
var _last_theme_signature: String = ""
var _last_combat_layout_signature: String = ""
var _ui_tearing_down: bool = false
var _match_event_bus = null
var _bound_match_for_events = null
var _hand_button_pool: Array = []
var _stage_hand_button_pool: Array = []
var _combat_potion_button_pool: Array = []
var _stage_potion_button_pool: Array = []
var _status_row_pools: Dictionary = {}
var _status_row_stable_labels: Dictionary = {}
var _stage_perf_panel: PanelContainer = null
var _stage_perf_title_label: Label = null
var _stage_perf_body_label: Label = null
var _perf_turn_key: String = ""
var _perf_turn_object_baseline: float = 0.0
var _perf_turn_vram_baseline: float = 0.0
var _live_match_refresh_queued: bool = false
var _full_ui_refresh_queued: bool = false
var _stage_fx_tween: Tween = null
var _run_start_finalize_queued: bool = false
var _begin_tournament_transition_token: int = 0
var _begin_tournament_watchdog_token: int = 0
var _run_start_finalize_token: int = 0
var _combat_layout_refresh_queued: bool = false
var _path_select_hovered_node_id: int = -1

func _ready() -> void:
	title_label.text = "Court of Chaos"
	subtitle_label.text = "Grand Slam run prototype: four majors, branching mini-tournaments, rally-pressure combat, and persistent unlocks."

	_fit_window_to_screen()
	_wrap_right_column_in_scroll()
	_wrap_combat_stage_in_scroll()
	var window := get_window()
	if window != null:
		window.size_changed.connect(_on_window_size_changed)
	hand_buttons.add_theme_constant_override("separation", 12)
	stage_hand_buttons.add_theme_constant_override("separation", 14)
	stage_hand_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_hand_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_buttons.add_theme_constant_override("separation", 12)
	rest_choice_row.add_theme_constant_override("separation", 16)
	rest_hint_label.add_theme_font_size_override("font_size", 15)
	rest_summary_label.add_theme_font_size_override("font_size", 15)
	rest_ledger_body_label.add_theme_font_size_override("font_size", 15)
	rest_question_label.add_theme_font_size_override("font_size", 30)
	rest_eyebrow_label.add_theme_font_size_override("font_size", 15)
	rest_ledger_title_label.add_theme_font_size_override("font_size", 20)
	class_header_label.add_theme_font_size_override("font_size", 16)
	class_name_label.add_theme_font_size_override("font_size", 22)
	run_status_label.add_theme_font_size_override("font_size", 15)
	map_title_label.add_theme_font_size_override("font_size", 24)
	node_info_label.add_theme_font_size_override("font_size", 15)
	class_view.add_theme_font_size_override("normal_font_size", 15)
	class_view.add_theme_constant_override("line_separation", 6)
	stage_hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stage_hand_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hand_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	prev_button.pressed.connect(_on_prev_class_pressed)
	next_button.pressed.connect(_on_next_class_pressed)
	start_run_button.pressed.connect(_on_start_run_pressed)
	continue_run_button.pressed.connect(_on_continue_run_pressed)
	reset_run_button.pressed.connect(_on_reset_run_pressed)
	landing_start_button.pressed.connect(_on_start_run_pressed)
	launch_start_button.pressed.connect(_on_start_run_pressed)
	launch_continue_button.pressed.connect(_on_continue_run_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	stage_end_turn_button.pressed.connect(_on_end_turn_pressed)
	primary_action_button.pressed.connect(_on_primary_action_pressed)
	reveal_proceed_button.pressed.connect(_on_reveal_proceed_pressed)
	dismiss_reveal_button.pressed.connect(_on_dismiss_reveal_pressed)
	rest_leave_button.pressed.connect(_on_skip_reward_pressed)
	map_view.node_selected.connect(_on_map_node_selected)
	_ensure_equipment_bonus_panel()
	_ensure_return_support_rows()
	_ensure_shop_checkpoint_panel()
	_ensure_shop_offer_sections()
	_ensure_reward_checkpoint_panel()
	_ensure_path_select_panel()
	_ensure_rest_checkpoint_header()
	_ensure_combat_potion_rows()
	_ensure_stage_perf_panel()
	_ensure_class_showcase_panel()
	_ensure_accessibility_controls()
	_checkpoint_screen_controller = CheckpointScreenControllerScript.new()
	_checkpoint_pane_presenter = CheckpointPanePresenterScript.new()
	_combat_hud_presenter = CombatHudPresenterScript.new()
	_combat_screen_controller = CombatScreenControllerScript.new()
	_front_screen_controller = FrontScreenControllerScript.new()
	_front_screen_presenter = FrontScreenPresenterScript.new()
	_main_theme_controller = MainThemeControllerScript.new()
	_main_pane_state_presenter = MainPaneStatePresenterScript.new()
	_meta_sidebar_controller = MetaSidebarControllerScript.new()
	_path_select_pane_presenter = PathSelectPanePresenterScript.new()
	_path_select_screen_controller = PathSelectScreenControllerScript.new()
	_ui_text_builder = MainUITextBuilderScript.new(_card_database, _model_database, _unlock_progression)
	_match_event_bus = MatchEventBusScript.new()
	add_child(_match_event_bus)
	_match_event_bus.point_started.connect(_on_match_point_started)
	_match_event_bus.card_played.connect(_on_match_card_played)
	_match_event_bus.rally_updated.connect(_on_match_rally_updated)
	_match_event_bus.point_ended.connect(_on_match_point_ended)
	_match_event_bus.raw_event.connect(_on_match_raw_event)
	var accessibility = _accessibility_service()
	if accessibility != null:
		accessibility.settings_changed.connect(_on_accessibility_settings_changed)
		accessibility.bindings_changed.connect(_on_accessibility_bindings_changed)

	_load_progress()
	_apply_accessibility_preferences()
	_refresh_ui()
	_queue_combat_stage_layout()

func _exit_tree() -> void:
	_ui_tearing_down = true
	if is_instance_valid(_point_context_flash_tween):
		_point_context_flash_tween.kill()
	_point_context_flash_tween = null
	if is_instance_valid(_stage_fx_tween):
		_stage_fx_tween.kill()
	_stage_fx_tween = null
	if is_instance_valid(_major_stinger_cleanup_tween):
		_major_stinger_cleanup_tween.kill()
	_major_stinger_cleanup_tween = null
	_cleanup_major_stinger_audio()
	if is_instance_valid(_match_event_bus):
		_match_event_bus.clear_match()

func _load_progress() -> void:
	_progress = _save_manager.load_progress()
	_sync_available_classes()
	_select_class_by_id(StringName(String(_progress.get("last_selected_class", "novice"))))
	_front_screen_mode = FRONT_SCREEN_LANDING

func _has_saved_run() -> bool:
	return _save_manager.has_active_run()

func _telemetry_service():
	var telemetry = get_node_or_null("/root/TelemetryAutoload")
	if telemetry != null:
		return telemetry
	return get_node_or_null("/root/Telemetry")

func _accessibility_service():
	return get_node_or_null("/root/AccessibilitySettings")

func _current_reward_menu_kind() -> String:
	if _main_pane_state_presenter == null:
		return String(_run_state.get_reward_menu_kind())
	return String(_main_pane_state_presenter.classify_reward_menu(String(_run_state.phase), _run_state.get_reward_choices()))

func _ui_scale_factor() -> float:
	var accessibility = _accessibility_service()
	if accessibility != null and accessibility.has_method("get_ui_scale"):
		return float(accessibility.get_ui_scale())
	return 1.0

func _font_scale_factor() -> float:
	var accessibility = _accessibility_service()
	if accessibility != null and accessibility.has_method("get_font_scale"):
		return float(accessibility.get_font_scale())
	return 1.0

func _high_contrast_enabled() -> bool:
	var accessibility = _accessibility_service()
	if accessibility != null and accessibility.has_method("is_high_contrast_enabled"):
		return bool(accessibility.is_high_contrast_enabled())
	return false

func _reduced_motion_enabled() -> bool:
	var accessibility = _accessibility_service()
	if accessibility != null and accessibility.has_method("is_reduced_motion_enabled"):
		return bool(accessibility.is_reduced_motion_enabled())
	return false

func _scaled_font_size(base_size: int) -> int:
	return maxi(10, int(round(float(base_size) * _font_scale_factor())))

func _telemetry_run_id() -> String:
	return "%s_%d" % [String(_run_state.player_class_id), int(_run_state.seed)]

func _reset_telemetry_cursor() -> void:
	_telemetry_last_phase = String(_run_state.phase)
	_telemetry_last_match_key = ""
	_telemetry_event_cursor = 0

func _sync_telemetry_state() -> void:
	var telemetry = _telemetry_service()
	if telemetry == null:
		return
	var encounter_id := ""
	var average_rally_exchanges := 0.0
	if _run_state.active_match != null:
		var battle: Dictionary = _run_state.active_match.get_battle_presentation()
		encounter_id = "%d:%d:%s" % [
			int(_run_state.current_act),
			int(_run_state.current_node_id),
			String(battle.get("enemy_id", "unknown")),
		]
		average_rally_exchanges = float(battle.get("rally_exchanges", 0))
		if encounter_id != _telemetry_last_match_key:
			_telemetry_last_match_key = encounter_id
			_telemetry_event_cursor = 0
			telemetry.log_event("match_started", {
				"encounter_id": encounter_id,
				"enemy_id": String(battle.get("enemy_id", "")),
				"match_label": String(battle.get("match_label", "")),
				"surface": String(battle.get("surface_name", "")),
				"major_name": String(battle.get("major_name", "")),
				"player_class_id": String(battle.get("player_class_id", "")),
			})
	else:
		_telemetry_last_match_key = ""
		_telemetry_event_cursor = 0
	telemetry.update_run_context(int(_run_state.current_act), String(_run_state.phase), encounter_id)
	telemetry.update_average_rally_exchanges(average_rally_exchanges)
	var current_phase := String(_run_state.phase)
	if _telemetry_last_phase != current_phase:
		telemetry.log_event("phase_changed", {
			"from": _telemetry_last_phase,
			"to": current_phase,
		})
		_telemetry_last_phase = current_phase

func _log_encounter_outcome(previous_match) -> void:
	var telemetry = _telemetry_service()
	if telemetry == null or previous_match == null:
		return
	var battle: Dictionary = previous_match.get_battle_presentation()
	var player_data: Dictionary = Dictionary(battle.get("player", {}))
	var enemy_data: Dictionary = Dictionary(battle.get("enemy", {}))
	var outcome := "won" if String(previous_match.state) == "won" else "lost"
	telemetry.log_event("encounter_finished", {
		"encounter_id": _telemetry_last_match_key,
		"enemy_id": String(battle.get("enemy_id", "")),
		"enemy_name": String(enemy_data.get("name", "")),
		"major_name": String(battle.get("major_name", "")),
		"surface": String(battle.get("surface_name", "")),
		"match_label": String(battle.get("match_label", "")),
		"outcome": outcome,
		"result_reason": String(previous_match.result_reason),
		"score": String(battle.get("score", "")),
		"games_score": String(battle.get("games_score", "")),
		"point_number": int(battle.get("point_number", 0)),
		"rally_exchanges": int(battle.get("rally_exchanges", 0)),
		"rally_pressure": int(battle.get("rally_pressure", 0)),
		"player_condition": int(player_data.get("condition", 0)),
		"enemy_condition": int(enemy_data.get("condition", 0)),
		"player_statuses": PackedStringArray(player_data.get("statuses", PackedStringArray())),
		"enemy_statuses": PackedStringArray(enemy_data.get("statuses", PackedStringArray())),
		"last_point_summary": String(battle.get("last_point_summary", "")),
	})

func _on_match_raw_event(event: Dictionary) -> void:
	var telemetry = _telemetry_service()
	if _run_state.active_match == null:
		return
	var battle: Dictionary = _run_state.active_match.get_battle_presentation()
	var player_data: Dictionary = Dictionary(battle.get("player", {}))
	var enemy_data: Dictionary = Dictionary(battle.get("enemy", {}))
	var event_payload := Dictionary(event.get("payload", {}))
	if telemetry != null:
		telemetry.log_event("match_event", {
			"encounter_id": _telemetry_last_match_key,
			"event_kind": String(event.get("kind", "")),
			"event_side": String(event.get("side", "")),
			"point_number": int(event.get("point_number", 0)),
			"turn_number": int(event.get("turn_number", 0)),
			"payload": event_payload,
			"rally_exchanges": int(battle.get("rally_exchanges", 0)),
			"rally_pressure": int(battle.get("rally_pressure", 0)),
			"player_condition": int(player_data.get("condition", 0)),
			"enemy_condition": int(enemy_data.get("condition", 0)),
			"player_statuses": PackedStringArray(player_data.get("statuses", PackedStringArray())),
			"enemy_statuses": PackedStringArray(enemy_data.get("statuses", PackedStringArray())),
		})
	_play_match_raw_event_fx(String(event.get("kind", "")), String(event.get("side", "")), event_payload)

func _fit_window_to_screen() -> void:
	var window := get_window()
	if window == null:
		return
	var usable_rect := DisplayServer.screen_get_usable_rect(window.current_screen)
	var max_width := mini(usable_rect.size.x, 1600)
	var max_height := mini(usable_rect.size.y, 1000)
	var target_size := Vector2i(
		int(float(max_width) * 0.94),
		int(float(max_height) * 0.94)
	)
	target_size.x = clampi(target_size.x, 1100, max_width)
	target_size.y = clampi(target_size.y, 720, max_height)
	window.size = target_size
	window.position = usable_rect.position + (usable_rect.size - target_size) / 2

func _wrap_right_column_in_scroll() -> void:
	if body_split == null or right_column == null or is_instance_valid(_right_scroll):
		return
	var scroll := ScrollContainer.new()
	scroll.name = "RightScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	scroll.custom_minimum_size = Vector2(460, 0)
	body_split.remove_child(right_column)
	body_split.add_child(scroll)
	body_split.move_child(scroll, 1)
	scroll.add_child(right_column)
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right_column.custom_minimum_size = Vector2(460, 0)
	_right_scroll = scroll

func _wrap_combat_stage_in_scroll() -> void:
	if root_vbox == null or combat_stage_panel == null or is_instance_valid(_combat_scroll):
		return
	var stage_index := root_vbox.get_children().find(combat_stage_panel)
	if stage_index < 0:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "CombatStageScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	root_vbox.remove_child(combat_stage_panel)
	root_vbox.add_child(scroll)
	root_vbox.move_child(scroll, stage_index)
	scroll.add_child(combat_stage_panel)
	combat_stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_scroll = scroll

func _ensure_accessibility_controls() -> void:
	if is_instance_valid(_accessibility_overlay):
		return
	_accessibility_button = Button.new()
	_accessibility_button.name = "AccessibilityButton"
	_accessibility_button.text = "Accessibility"
	_accessibility_button.focus_mode = Control.FOCUS_NONE
	_accessibility_button.anchor_left = 1.0
	_accessibility_button.anchor_top = 0.0
	_accessibility_button.anchor_right = 1.0
	_accessibility_button.anchor_bottom = 0.0
	_accessibility_button.offset_left = -196.0
	_accessibility_button.offset_top = 14.0
	_accessibility_button.offset_right = -18.0
	_accessibility_button.offset_bottom = 58.0
	_accessibility_button.z_index = 40
	_accessibility_button.pressed.connect(_toggle_accessibility_overlay)
	add_child(_accessibility_button)

	_accessibility_overlay = Control.new()
	_accessibility_overlay.name = "AccessibilityOverlay"
	_accessibility_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_accessibility_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_accessibility_overlay.z_index = 80
	_accessibility_overlay.visible = false
	add_child(_accessibility_overlay)

	var scrim := ColorRect.new()
	scrim.set_anchors_preset(PRESET_FULL_RECT)
	scrim.color = Color(0.02, 0.05, 0.08, 0.78)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_accessibility_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_accessibility_overlay.add_child(center)

	_accessibility_panel = PanelContainer.new()
	_accessibility_panel.custom_minimum_size = Vector2(760, 620)
	_accessibility_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_accessibility_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	_accessibility_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 10)
	root.add_child(header_row)

	var header_box := VBoxContainer.new()
	header_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_theme_constant_override("separation", 6)
	header_row.add_child(header_box)

	var title := Label.new()
	title.name = "AccessibilityTitle"
	title.text = "Accessibility Settings"
	header_box.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "AccessibilitySubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.text = "Tune readability and motion, then remap the keys you use most. Settings save to user://settings.cfg."
	header_box.add_child(subtitle)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_toggle_accessibility_overlay)
	header_row.add_child(close_button)

	var scale_panel := PanelContainer.new()
	scale_panel.name = "AccessibilityScalePanel"
	root.add_child(scale_panel)
	var scale_margin := MarginContainer.new()
	scale_margin.add_theme_constant_override("margin_left", 16)
	scale_margin.add_theme_constant_override("margin_top", 16)
	scale_margin.add_theme_constant_override("margin_right", 16)
	scale_margin.add_theme_constant_override("margin_bottom", 16)
	scale_panel.add_child(scale_margin)
	var scale_box := VBoxContainer.new()
	scale_box.add_theme_constant_override("separation", 12)
	scale_margin.add_child(scale_box)

	var scale_title := Label.new()
	scale_title.name = "AccessibilityScaleTitle"
	scale_title.text = "Readability"
	scale_box.add_child(scale_title)

	var ui_scale_row := _build_accessibility_slider_row(
		"UI Scale",
		0.85,
		1.35,
		0.05,
		"_on_accessibility_ui_scale_changed"
	)
	_accessibility_ui_scale_slider = ui_scale_row["slider"]
	_accessibility_ui_scale_value_label = ui_scale_row["value"]
	scale_box.add_child(ui_scale_row["row"])

	var font_scale_row := _build_accessibility_slider_row(
		"Font Scale",
		0.85,
		1.50,
		0.05,
		"_on_accessibility_font_scale_changed"
	)
	_accessibility_font_scale_slider = font_scale_row["slider"]
	_accessibility_font_scale_value_label = font_scale_row["value"]
	scale_box.add_child(font_scale_row["row"])

	var toggle_panel := PanelContainer.new()
	toggle_panel.name = "AccessibilityTogglePanel"
	root.add_child(toggle_panel)
	var toggle_margin := MarginContainer.new()
	toggle_margin.add_theme_constant_override("margin_left", 16)
	toggle_margin.add_theme_constant_override("margin_top", 16)
	toggle_margin.add_theme_constant_override("margin_right", 16)
	toggle_margin.add_theme_constant_override("margin_bottom", 16)
	toggle_panel.add_child(toggle_margin)
	var toggle_box := VBoxContainer.new()
	toggle_box.add_theme_constant_override("separation", 10)
	toggle_margin.add_child(toggle_box)

	var contrast_check := CheckBox.new()
	contrast_check.text = "High Contrast Mode"
	contrast_check.toggled.connect(_on_accessibility_high_contrast_toggled)
	toggle_box.add_child(contrast_check)
	_accessibility_high_contrast_check = contrast_check

	var contrast_hint := Label.new()
	contrast_hint.name = "AccessibilityContrastHint"
	contrast_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contrast_hint.text = "Keeps key states readable with text labels like [SERVE], [RETURN], and [LOCKED], not color alone."
	toggle_box.add_child(contrast_hint)

	var motion_check := CheckBox.new()
	motion_check.text = "Reduced Motion"
	motion_check.toggled.connect(_on_accessibility_reduced_motion_toggled)
	toggle_box.add_child(motion_check)
	_accessibility_reduced_motion_check = motion_check

	var motion_hint := Label.new()
	motion_hint.name = "AccessibilityMotionHint"
	motion_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	motion_hint.text = "Disables point-state flashes and reduces card hover motion."
	toggle_box.add_child(motion_hint)

	var bindings_panel := PanelContainer.new()
	bindings_panel.name = "AccessibilityBindingsPanel"
	root.add_child(bindings_panel)
	var bindings_margin := MarginContainer.new()
	bindings_margin.add_theme_constant_override("margin_left", 16)
	bindings_margin.add_theme_constant_override("margin_top", 16)
	bindings_margin.add_theme_constant_override("margin_right", 16)
	bindings_margin.add_theme_constant_override("margin_bottom", 16)
	bindings_panel.add_child(bindings_margin)
	var bindings_box := VBoxContainer.new()
	bindings_box.add_theme_constant_override("separation", 10)
	bindings_margin.add_child(bindings_box)

	var bindings_title := Label.new()
	bindings_title.name = "AccessibilityBindingsTitle"
	bindings_title.text = "Remappable Controls"
	bindings_box.add_child(bindings_title)

	for action_name in ["coc_primary_action", "coc_end_turn", "coc_prev_class", "coc_next_class", "coc_settings"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		bindings_box.add_child(row)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = action_name
		row.add_child(label)

		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(180, 42)
		button.pressed.connect(func() -> void:
			_begin_rebind_action(action_name)
		)
		row.add_child(button)
		_accessibility_binding_rows[action_name] = {"label": label, "button": button}

	_accessibility_binding_hint_label = Label.new()
	_accessibility_binding_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_accessibility_binding_hint_label.text = "Choose an action, then press a key. Press Escape to cancel a rebind."
	bindings_box.add_child(_accessibility_binding_hint_label)

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 10)
	root.add_child(footer_row)

	var reset_bindings_button := Button.new()
	reset_bindings_button.text = "Reset Bindings"
	reset_bindings_button.focus_mode = Control.FOCUS_NONE
	reset_bindings_button.pressed.connect(_on_accessibility_reset_bindings_pressed)
	footer_row.add_child(reset_bindings_button)

	var close_footer_button := Button.new()
	close_footer_button.text = "Done"
	close_footer_button.focus_mode = Control.FOCUS_NONE
	close_footer_button.pressed.connect(_toggle_accessibility_overlay)
	footer_row.add_child(close_footer_button)

	_refresh_accessibility_controls()

func _build_accessibility_slider_row(
	label_text: String,
	min_value: float,
	max_value: float,
	step_value: float,
	callback_name: String
) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.custom_minimum_size = Vector2(148, 0)
	label.text = label_text
	row.add_child(label)
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step_value
	slider.value_changed.connect(Callable(self, callback_name))
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return {"row": row, "slider": slider, "value": value_label}

func _toggle_accessibility_overlay() -> void:
	if not is_instance_valid(_accessibility_overlay):
		return
	if not _accessibility_available_on_current_screen() and not _accessibility_overlay.visible:
		return
	_awaiting_rebind_action = ""
	_accessibility_overlay.visible = not _accessibility_overlay.visible
	_refresh_accessibility_controls()

func _begin_rebind_action(action_name: String) -> void:
	_awaiting_rebind_action = action_name
	_refresh_accessibility_controls()

func _on_accessibility_ui_scale_changed(value: float) -> void:
	var accessibility = _accessibility_service()
	if accessibility != null:
		accessibility.set_setting("ui_scale", value, true)

func _on_accessibility_font_scale_changed(value: float) -> void:
	var accessibility = _accessibility_service()
	if accessibility != null:
		accessibility.set_setting("font_scale", value, true)

func _on_accessibility_high_contrast_toggled(enabled: bool) -> void:
	var accessibility = _accessibility_service()
	if accessibility != null:
		accessibility.set_setting("high_contrast", enabled, true)

func _on_accessibility_reduced_motion_toggled(enabled: bool) -> void:
	var accessibility = _accessibility_service()
	if accessibility != null:
		accessibility.set_setting("reduced_motion", enabled, true)

func _on_accessibility_reset_bindings_pressed() -> void:
	var accessibility = _accessibility_service()
	if accessibility != null and accessibility.has_method("reset_bindings"):
		accessibility.reset_bindings(true)

func _on_accessibility_settings_changed(_snapshot: Dictionary) -> void:
	_apply_accessibility_preferences()
	_refresh_accessibility_controls()
	_queue_refresh_ui()

func _on_accessibility_bindings_changed(_bindings: Dictionary) -> void:
	_refresh_accessibility_controls()

func _refresh_accessibility_controls() -> void:
	if not is_instance_valid(_accessibility_panel):
		return
	var accessibility = _accessibility_service()
	if accessibility == null:
		return
	if is_instance_valid(_accessibility_ui_scale_slider):
		_accessibility_ui_scale_slider.set_value_no_signal(accessibility.get_ui_scale())
	if is_instance_valid(_accessibility_ui_scale_value_label):
		_accessibility_ui_scale_value_label.text = "%.2fx" % accessibility.get_ui_scale()
	if is_instance_valid(_accessibility_font_scale_slider):
		_accessibility_font_scale_slider.set_value_no_signal(accessibility.get_font_scale())
	if is_instance_valid(_accessibility_font_scale_value_label):
		_accessibility_font_scale_value_label.text = "%.2fx" % accessibility.get_font_scale()
	if is_instance_valid(_accessibility_high_contrast_check):
		_accessibility_high_contrast_check.set_pressed_no_signal(accessibility.is_high_contrast_enabled())
	if is_instance_valid(_accessibility_reduced_motion_check):
		_accessibility_reduced_motion_check.set_pressed_no_signal(accessibility.is_reduced_motion_enabled())
	for action_name in _accessibility_binding_rows.keys():
		var row: Dictionary = _accessibility_binding_rows[action_name]
		var label: Label = row.get("label")
		var button: Button = row.get("button")
		if label != null:
			var label_text: String = String(action_name)
			for entry in accessibility.get_remappable_actions():
				if String(entry.get("action", "")) == action_name:
					label_text = String(entry.get("label", action_name))
					break
			label.text = label_text
		if button != null:
			button.text = "Press key..." if action_name == _awaiting_rebind_action else accessibility.get_binding_text(action_name)
	if is_instance_valid(_accessibility_binding_hint_label):
		if _awaiting_rebind_action == "":
			_accessibility_binding_hint_label.text = "Choose an action, then press a key. Press Escape to cancel a rebind."
		else:
			_accessibility_binding_hint_label.text = "Rebinding %s. Press a key now, or Escape to cancel." % _awaiting_rebind_action

func _accessibility_available_on_current_screen() -> bool:
	return _run_state.phase == "idle" and _front_screen_mode in [FRONT_SCREEN_LANDING, FRONT_SCREEN_CLASS_SELECT]

func _apply_accessibility_preferences() -> void:
	var ui_scale := _ui_scale_factor()
	var font_scale := _font_scale_factor()
	if is_instance_valid(_accessibility_button):
		_accessibility_button.custom_minimum_size = Vector2(0, 42.0 * ui_scale)
		_accessibility_button.add_theme_font_size_override("font_size", _scaled_font_size(14))
	if is_instance_valid(_accessibility_panel):
		_accessibility_panel.custom_minimum_size = Vector2(760.0 * ui_scale, 620.0 * ui_scale)
		_apply_panel_style(_accessibility_panel, Color(0.08, 0.11, 0.15, 0.98), Color(0.82, 0.91, 1.0, 1.0))
		for child in _accessibility_panel.find_children("*", "Label", true, false):
			var label := child as Label
			if label == null:
				continue
			var base_size := 15
			if label.name.find("Title") >= 0:
				base_size = 28
			elif label.name.find("Subtitle") >= 0:
				base_size = 15
			elif label.name.find("Hint") >= 0:
				base_size = 13
			label.add_theme_font_size_override("font_size", maxi(11, int(round(float(base_size) * font_scale))))
		for child in _accessibility_panel.find_children("*", "Button", true, false):
			var button := child as Button
			if button != null:
				button.add_theme_font_size_override("font_size", _scaled_font_size(14))
				_apply_button_style(button, Color(0.82, 0.90, 0.97, 1.0), Color(0.48, 0.62, 0.78, 1.0), Color(0.07, 0.09, 0.10))
		for child in _accessibility_panel.find_children("*", "CheckBox", true, false):
			var check_box := child as CheckBox
			if check_box != null:
				check_box.add_theme_font_size_override("font_size", _scaled_font_size(15))
	_apply_panel_style(stage_serve_state_panel, Color(0.14, 0.19, 0.24, 0.98), Color(0.70, 0.84, 1.0, 1.0))
	class_header_label.add_theme_font_size_override("font_size", _scaled_font_size(16))
	title_label.add_theme_font_size_override("font_size", _scaled_font_size(46))
	subtitle_label.add_theme_font_size_override("font_size", _scaled_font_size(18))
	class_name_label.add_theme_font_size_override("font_size", _scaled_font_size(22))
	run_status_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	map_title_label.add_theme_font_size_override("font_size", _scaled_font_size(24))
	node_info_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	class_view.add_theme_font_size_override("normal_font_size", _scaled_font_size(15))
	combat_header_label.add_theme_font_size_override("font_size", _scaled_font_size(22))
	match_summary_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	player_summary_label.add_theme_font_size_override("font_size", _scaled_font_size(14))
	enemy_intent_label.add_theme_font_size_override("font_size", _scaled_font_size(14))
	enemy_summary_label.add_theme_font_size_override("font_size", _scaled_font_size(14))
	hand_header_label.add_theme_font_size_override("font_size", _scaled_font_size(16))
	rest_hint_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	rest_summary_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	rest_ledger_body_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	rest_question_label.add_theme_font_size_override("font_size", _scaled_font_size(30))
	rest_eyebrow_label.add_theme_font_size_override("font_size", _scaled_font_size(15))
	rest_ledger_title_label.add_theme_font_size_override("font_size", _scaled_font_size(20))
	call_deferred("_configure_combat_stage_layout")

func _handle_accessibility_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	if _awaiting_rebind_action != "":
		if key_event.keycode == KEY_ESCAPE:
			_awaiting_rebind_action = ""
			_refresh_accessibility_controls()
			return true
		var accessibility = _accessibility_service()
		if accessibility != null:
			accessibility.rebind_action_to_keycode(_awaiting_rebind_action, int(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode), true)
		_awaiting_rebind_action = ""
		_refresh_accessibility_controls()
		return true
	if not _accessibility_available_on_current_screen():
		return false
	if not is_instance_valid(_accessibility_overlay) or not _accessibility_overlay.visible:
		return false
	if key_event.keycode == KEY_ESCAPE:
		_toggle_accessibility_overlay()
		return true
	return false

func _press_visible_button(button: Button) -> bool:
	if button == null or not button.visible or button.disabled:
		return false
	button.emit_signal("pressed")
	return true

func _trigger_primary_action() -> bool:
	if is_instance_valid(_accessibility_overlay) and _accessibility_overlay.visible:
		return false
	if _press_visible_button(primary_action_button):
		return true
	if _press_visible_button(reveal_proceed_button):
		return true
	if _press_visible_button(launch_start_button):
		return true
	if _press_visible_button(start_run_button):
		return true
	if _press_visible_button(landing_start_button):
		return true
	if _press_visible_button(rest_leave_button):
		return true
	if is_instance_valid(_reward_skip_button) and _press_visible_button(_reward_skip_button):
		return true
	if is_instance_valid(_shop_leave_button) and _press_visible_button(_shop_leave_button):
		return true
	if is_instance_valid(_shop_leave_button_top) and _press_visible_button(_shop_leave_button_top):
		return true
	if is_instance_valid(_shop_header_leave_button) and _press_visible_button(_shop_header_leave_button):
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if _handle_accessibility_input(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("coc_settings") and _accessibility_available_on_current_screen():
		_toggle_accessibility_overlay()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_accessibility_overlay) and _accessibility_overlay.visible:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("coc_prev_class"):
		_on_prev_class_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("coc_next_class"):
		_on_next_class_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("coc_end_turn"):
		_on_end_turn_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("coc_primary_action") and _trigger_primary_action():
		get_viewport().set_input_as_handled()

func _on_window_size_changed() -> void:
	_queue_combat_stage_layout()

func _queue_combat_stage_layout() -> void:
	if _combat_layout_refresh_queued or _ui_tearing_down or not is_inside_tree():
		return
	_combat_layout_refresh_queued = true
	call_deferred("_flush_combat_stage_layout")

func _flush_combat_stage_layout() -> void:
	_combat_layout_refresh_queued = false
	if _ui_tearing_down or not is_inside_tree():
		return
	_configure_combat_stage_layout()

func _configure_combat_stage_layout() -> void:
	if _ui_tearing_down or not is_inside_tree() or combat_stage_panel == null:
		return
	if String(DisplayServer.get_name()).to_lower().find("headless") >= 0:
		return
	if not combat_stage_panel.visible and (not is_instance_valid(_combat_scroll) or not _combat_scroll.visible):
		_last_combat_layout_signature = ""
		return
	var viewport_width := root_vbox.size.x
	var viewport_height := root_vbox.size.y
	if is_instance_valid(_combat_scroll) and _combat_scroll.visible:
		viewport_width = _combat_scroll.size.x
		viewport_height = _combat_scroll.size.y
	if viewport_width <= 0.0 or viewport_height <= 0.0:
		return

	var compact_level := _combat_compact_level(viewport_width, viewport_height)
	var ui_scale := _ui_scale_factor()

	var portrait_size := 58
	var side_hud_width := 140
	var arena_height := 300
	var hand_height := 248
	var score_font := 15
	var meta_font := 11
	var hud_title_font := 13
	var hud_body_font := 11
	var body_font := 11
	var pod_width := 194
	var flow_width := 170
	var rally_width := 0
	var intent_width := 154
	var score_width := 0
	var stamina_width := 126
	var action_width := 178
	var end_turn_height := 58
	var overlay_margin := 8
	var row_separation := 7
	var badge_name_font := 15
	var badge_info_font := 12
	var score_margin_horizontal := 10
	var pressure_meter_height := 12
	if compact_level == 1:
		portrait_size = 54
		side_hud_width = 134
		arena_height = 278
		hand_height = 236
		score_font = 14
		meta_font = 11
		hud_title_font = 13
		hud_body_font = 10
		body_font = 11
		pod_width = 184
		flow_width = 158
		rally_width = 0
		intent_width = 146
		stamina_width = 118
		action_width = 166
		end_turn_height = 54
		overlay_margin = 7
		row_separation = 6
		badge_name_font = 14
		badge_info_font = 11
		score_margin_horizontal = 8
		pressure_meter_height = 11
	elif compact_level == 2:
		portrait_size = 50
		side_hud_width = 124
		arena_height = 252
		hand_height = 224
		score_font = 13
		meta_font = 11
		hud_title_font = 12
		hud_body_font = 10
		body_font = 10
		pod_width = 170
		flow_width = 146
		rally_width = 0
		intent_width = 136
		stamina_width = 110
		action_width = 152
		end_turn_height = 50
		overlay_margin = 6
		row_separation = 6
		badge_name_font = 12
		badge_info_font = 10
		score_margin_horizontal = 6
		pressure_meter_height = 10
	else:
		portrait_size = 46
		side_hud_width = 116
		arena_height = 228
		hand_height = 212
		score_font = 12
		meta_font = 10
		hud_title_font = 12
		hud_body_font = 10
		body_font = 10
		pod_width = 152
		flow_width = 132
		rally_width = 0
		intent_width = 124
		stamina_width = 102
		action_width = 138
		end_turn_height = 46
		overlay_margin = 4
		row_separation = 5
		badge_name_font = 12
		badge_info_font = 10
		score_margin_horizontal = 4
		pressure_meter_height = 10

	portrait_size = int(round(float(portrait_size) * ui_scale))
	side_hud_width = int(round(float(side_hud_width) * ui_scale))
	arena_height = int(round(float(arena_height) * ui_scale))
	hand_height = int(round(float(hand_height) * ui_scale))
	pod_width = int(round(float(pod_width) * ui_scale))
	flow_width = int(round(float(flow_width) * ui_scale))
	intent_width = int(round(float(intent_width) * ui_scale))
	stamina_width = int(round(float(stamina_width) * ui_scale))
	action_width = int(round(float(action_width) * ui_scale))
	end_turn_height = int(round(float(end_turn_height) * ui_scale))
	overlay_margin = int(round(float(overlay_margin) * ui_scale))
	row_separation = int(round(float(row_separation) * ui_scale))
	score_margin_horizontal = int(round(float(score_margin_horizontal) * ui_scale))
	pressure_meter_height = int(round(float(pressure_meter_height) * ui_scale))
	pressure_meter_height = maxi(18, pressure_meter_height)

	var target_width := viewport_width
	if is_instance_valid(_combat_scroll):
		target_width = maxf(0.0, viewport_width - 2.0)
	var layout_signature := "%d|%d|%d|%d|%d|%d|%d|%d" % [
		compact_level,
		int(target_width),
		portrait_size,
		side_hud_width,
		arena_height,
		hand_height,
		flow_width,
		intent_width,
	]
	if layout_signature == _last_combat_layout_signature:
		return
	_last_combat_layout_signature = layout_signature

	stage_player_portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)
	stage_enemy_portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)
	stage_player_hud.custom_minimum_size = Vector2(side_hud_width, 0)
	stage_enemy_hud.custom_minimum_size = Vector2(side_hud_width, 0)
	stage_player_hud.size_flags_horizontal = Control.SIZE_FILL
	stage_enemy_hud.size_flags_horizontal = Control.SIZE_FILL
	stage_score_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_score_hud.custom_minimum_size = Vector2(score_width, 0)
	stage_flow_panel.custom_minimum_size = Vector2(flow_width, 0)
	stage_rally_panel.custom_minimum_size = Vector2(rally_width, 0)
	stage_intent_panel.custom_minimum_size = Vector2(intent_width, 0)
	stage_player_pod.custom_minimum_size = Vector2(pod_width, 0)
	stage_enemy_pod.custom_minimum_size = Vector2(pod_width, 0)
	stage_stamina_panel.custom_minimum_size = Vector2(stamina_width, 0)
	stage_action_panel.custom_minimum_size = Vector2(action_width, 0)
	stage_arena_root.custom_minimum_size = Vector2(0, arena_height)
	stage_hand_scroll.custom_minimum_size = Vector2(0, hand_height)
	stage_end_turn_button.custom_minimum_size = Vector2(0, end_turn_height)
	stage_pressure_meter.custom_minimum_size = Vector2(0, pressure_meter_height)

	stage_top_row.add_theme_constant_override("separation", row_separation)
	stage_equipment_row.add_theme_constant_override("separation", row_separation)
	if is_instance_valid(_stage_return_support_row):
		_stage_return_support_row.add_theme_constant_override("separation", maxi(6, row_separation - 2))
	stage_arena_top_row.add_theme_constant_override("separation", row_separation)
	stage_arena_bottom_row.add_theme_constant_override("separation", row_separation + 2)
	stage_footer_row.add_theme_constant_override("separation", row_separation)
	stage_arena_overlay.add_theme_constant_override("margin_left", overlay_margin)
	stage_arena_overlay.add_theme_constant_override("margin_top", overlay_margin)
	stage_arena_overlay.add_theme_constant_override("margin_right", overlay_margin)
	stage_arena_overlay.add_theme_constant_override("margin_bottom", overlay_margin)
	stage_score_hud_margin.add_theme_constant_override("margin_left", score_margin_horizontal)
	stage_score_hud_margin.add_theme_constant_override("margin_right", score_margin_horizontal)

	stage_major_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_title_font))
	stage_score_label.add_theme_font_size_override("font_size", _scaled_font_size(score_font))
	stage_meta_label.add_theme_font_size_override("font_size", _scaled_font_size(meta_font))
	stage_major_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_player_title_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_title_font))
	stage_enemy_title_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_title_font))
	stage_player_hud_body_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_body_font))
	stage_enemy_hud_body_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_body_font))
	stage_serve_state_label.add_theme_font_size_override("font_size", _scaled_font_size(maxi(11, body_font)))
	stage_flow_body_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_rally_body_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_intent_body_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_player_pod_title_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_title_font + 1))
	stage_enemy_pod_title_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_title_font + 1))
	stage_player_pod_body_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_enemy_pod_body_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_hand_title_label.add_theme_font_size_override("font_size", _scaled_font_size(hud_title_font))
	stage_stamina_value_label.add_theme_font_size_override("font_size", _scaled_font_size(28 if compact_level == 0 else 24 if compact_level == 1 else 22))
	stage_stamina_hint_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_turn_hint_label.add_theme_font_size_override("font_size", _scaled_font_size(body_font))
	stage_event_feed_title_label.add_theme_font_size_override("font_size", _scaled_font_size(maxi(11, body_font)))
	stage_event_feed_label.add_theme_font_size_override("font_size", _scaled_font_size(maxi(10, body_font - 1)))
	stage_string_badge_name_label.add_theme_font_size_override("font_size", _scaled_font_size(badge_name_font))
	stage_racquet_badge_name_label.add_theme_font_size_override("font_size", _scaled_font_size(badge_name_font))
	stage_string_badge_info_label.add_theme_font_size_override("font_size", _scaled_font_size(badge_info_font))
	stage_racquet_badge_info_label.add_theme_font_size_override("font_size", _scaled_font_size(badge_info_font))
	stage_player_title_label.clip_text = true
	stage_enemy_title_label.clip_text = true
	stage_player_hud_body_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_enemy_hud_body_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_player_hud_body_label.clip_text = true
	stage_enemy_hud_body_label.clip_text = true
	stage_flow_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_rally_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_intent_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_player_pod_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_enemy_pod_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if is_instance_valid(_combat_scroll):
		combat_stage_panel.custom_minimum_size.x = maxf(0.0, target_width)
		combat_stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var required_height := combat_stage_panel.get_combined_minimum_size().y
		_combat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if required_height <= viewport_height else ScrollContainer.SCROLL_MODE_AUTO
	if _run_state.active_match != null and combat_stage_panel.visible:
		_build_hand_buttons_into(stage_hand_buttons, true)
		_sync_stage_visual_layout()

func _combat_compact_level(viewport_width: float, viewport_height: float) -> int:
	var compact_level := 0
	if viewport_height < 920.0 or viewport_width < 1500.0:
		compact_level = 1
	if viewport_height < 840.0 or viewport_width < 1320.0:
		compact_level = 2
	if viewport_height < 760.0 or viewport_width < 1180.0:
		compact_level = 3
	return compact_level

func _current_combat_compact_level() -> int:
	var viewport_width := root_vbox.size.x
	var viewport_height := root_vbox.size.y
	if is_instance_valid(_combat_scroll) and _combat_scroll.visible:
		viewport_width = _combat_scroll.size.x
		viewport_height = _combat_scroll.size.y
	return _combat_compact_level(viewport_width, viewport_height)

func _compact_stage_summary(text: String) -> String:
	var compact_level := _current_combat_compact_level()
	var normalized := text.replace("\n", " ").strip_edges()
	if compact_level <= 0:
		return text
	if compact_level == 1:
		if normalized.length() <= 88:
			return normalized
		return normalized.substr(0, 85).rstrip(" ,.;") + "..."
	var sentence_end := normalized.find(".")
	if sentence_end > 0:
		normalized = normalized.substr(0, sentence_end + 1)
	if normalized.length() <= 62:
		return normalized
	return normalized.substr(0, 59).rstrip(" ,.;") + "..."

func _sync_available_classes() -> void:
	_available_classes.clear()
	for class_id in _unlock_progression.get_unlocked_classes(int(_progress.get("run_clears", 0))):
		var player_class = _class_database.get_player_class(class_id)
		if player_class != null:
			_available_classes.append(player_class)
	if _available_classes.is_empty():
		var novice = _class_database.get_player_class(&"novice")
		if novice != null:
			_available_classes.append(novice)
	_selected_index = clampi(_selected_index, 0, maxi(0, _available_classes.size() - 1))

func _select_class_by_id(class_id: StringName) -> void:
	for index in range(_available_classes.size()):
		if _available_classes[index].id == class_id:
			_selected_index = index
			return
	_selected_index = 0

func _get_selected_class():
	if _available_classes.is_empty():
		return null
	return _available_classes[_selected_index]

func _persist_selected_class() -> void:
	var selected_class = _get_selected_class()
	if selected_class == null:
		return
	_progress["last_selected_class"] = String(selected_class.id)
	_save_manager.save_progress(_progress)

func _on_prev_class_pressed() -> void:
	if _is_run_active() or _available_classes.size() <= 1:
		return
	_selected_index = wrapi(_selected_index - 1, 0, _available_classes.size())
	_persist_selected_class()
	_queue_refresh_ui()

func _on_next_class_pressed() -> void:
	if _is_run_active() or _available_classes.size() <= 1:
		return
	_selected_index = wrapi(_selected_index + 1, 0, _available_classes.size())
	_persist_selected_class()
	_queue_refresh_ui()

func _on_start_run_pressed() -> void:
	if _begin_tournament_in_progress:
		return
	if _run_state.phase == "idle":
		if _front_screen_mode == FRONT_SCREEN_LANDING:
			_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
			_queue_refresh_ui()
			return
		begin_selected_class_run()
		return
	_start_run_internal()

func begin_selected_class_run(run_seed: int = 0) -> void:
	_queue_begin_tournament_transition(run_seed)

func _reset_begin_tournament_transition_state() -> void:
	_begin_tournament_in_progress = false
	_pending_start_seed = 0
	_begin_tournament_recovery_attempts = 0
	_begin_tournament_watchdog_token += 1

func _arm_begin_tournament_watchdog() -> void:
	if _ui_tearing_down or not is_inside_tree() or not _begin_tournament_in_progress:
		return
	_begin_tournament_watchdog_token += 1
	var expected_token := _begin_tournament_watchdog_token
	var timer := get_tree().create_timer(BEGIN_TOURNAMENT_TIMEOUT_SEC)
	timer.timeout.connect(func() -> void:
		_on_begin_tournament_watchdog_timeout(expected_token)
	, CONNECT_ONE_SHOT)

func _on_begin_tournament_watchdog_timeout(expected_token: int) -> void:
	if expected_token != _begin_tournament_watchdog_token:
		return
	if _ui_tearing_down or not is_inside_tree() or not _begin_tournament_in_progress:
		return
	var phase := String(_run_state.phase)
	if phase == "combat" or (phase == "map" and _run_state.current_node_id >= 0):
		_reset_begin_tournament_transition_state()
		_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
		_queue_refresh_ui()
		return
	if _begin_tournament_recovery_attempts < BEGIN_TOURNAMENT_MAX_RECOVERY_ATTEMPTS:
		_begin_tournament_recovery_attempts += 1
		_run_state.status_message = "Opening round is taking longer than expected. Retrying the handoff..."
		match phase:
			"idle":
				call_deferred("_finish_begin_tournament_transition", _begin_tournament_transition_token)
			"map":
				if _run_state.has_reveal():
					_run_state.dismiss_reveal()
				_queue_start_run_finalization()
			_:
				call_deferred("_finish_begin_tournament_transition", _begin_tournament_transition_token)
		_queue_refresh_ui()
		_arm_begin_tournament_watchdog()
		return
	_reset_begin_tournament_transition_state()
	_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
	_run_state.status_message = "Opening round could not be prepared automatically. Pick the class again and retry."
	_queue_refresh_ui()

func _start_run_internal(run_seed: int = 0) -> void:
	var selected_class = _get_selected_class()
	if selected_class == null:
		_reset_begin_tournament_transition_state()
		return
	if not _begin_tournament_in_progress:
		_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
	_run_completion_recorded = false
	_run_state.start_new_run(selected_class.id, run_seed)
	_reset_telemetry_cursor()
	var telemetry = _telemetry_service()
	if telemetry != null:
		telemetry.start_run(_telemetry_run_id(), {
			"class_id": String(selected_class.id),
			"seed": int(_run_state.seed),
			"source": "new_run",
		})
	_persist_selected_class()
	if _run_state.phase == "map" and _run_state.current_node_id < 0:
		_queue_start_run_finalization()
		_queue_refresh_ui()
		return
	_reset_begin_tournament_transition_state()
	_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
	_maybe_show_victory_axis_tutorial()
	_after_run_state_changed()

func _queue_start_run_finalization() -> void:
	_run_start_finalize_token += 1
	_run_start_finalize_queued = true
	call_deferred("_finalize_started_run", _run_start_finalize_token)

func _finalize_started_run(expected_token: int) -> void:
	if expected_token != _run_start_finalize_token:
		return
	_run_start_finalize_queued = false
	if _ui_tearing_down or not is_inside_tree():
		_reset_begin_tournament_transition_state()
		return
	var advanced := false
	if _run_state.phase == "map" and _run_state.current_node_id < 0:
		if _run_state.has_reveal():
			_run_state.dismiss_reveal()
		advanced = _run_state.advance_to_primary_accessible_node()
	if _run_state.phase == "map" and _run_state.current_node_id < 0 and not advanced:
		_reset_begin_tournament_transition_state()
		_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
		_run_state.status_message = "Opening round could not be prepared. Pick the class again and retry."
		_queue_refresh_ui()
		return
	_reset_begin_tournament_transition_state()
	_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
	_maybe_show_victory_axis_tutorial()
	_after_run_state_changed()

func _maybe_show_victory_axis_tutorial() -> void:
	if bool(_progress.get("victory_tutorial_seen", false)):
		return
	_progress["victory_tutorial_seen"] = true
	_save_manager.save_progress(_progress)
	_run_state.show_reveal(
		"How You Win Matches",
		"You win points by hitting the rally pressure target or forcing an error. Tennis score wins the match. Condition is run attrition."
	)

func _queue_begin_tournament_transition(run_seed: int = 0) -> void:
	if _begin_tournament_in_progress:
		return
	if _get_selected_class() == null:
		return
	_begin_tournament_in_progress = true
	_pending_start_seed = run_seed
	_begin_tournament_recovery_attempts = 0
	_front_screen_mode = FRONT_SCREEN_TRANSITION
	_begin_tournament_transition_token += 1
	_arm_begin_tournament_watchdog()
	_queue_refresh_ui()
	call_deferred("_finish_begin_tournament_transition", _begin_tournament_transition_token)

func _finish_begin_tournament_transition(expected_token: int) -> void:
	if expected_token != _begin_tournament_transition_token:
		return
	if not _begin_tournament_in_progress:
		return
	if _ui_tearing_down or not is_inside_tree():
		_reset_begin_tournament_transition_state()
		return
	var run_seed := _pending_start_seed
	_pending_start_seed = 0
	_start_run_internal(run_seed)

func _on_continue_run_pressed() -> void:
	if _begin_tournament_in_progress or _is_run_active() or not _has_saved_run():
		return

	var snapshot = _save_manager.load_active_run()
	if not _run_state.restore_from_snapshot(snapshot):
		_save_manager.clear_active_run()
		_run_state.abandon_run()
		_run_state.status_message = "Saved run could not be restored. Start a new tournament."
		_queue_refresh_ui()
		return

	_run_completion_recorded = false
	_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
	_select_class_by_id(_run_state.player_class_id)
	_progress["last_selected_class"] = String(_run_state.player_class_id)
	_save_manager.save_progress(_progress)
	_reset_telemetry_cursor()
	var telemetry = _telemetry_service()
	if telemetry != null:
		telemetry.start_run(_telemetry_run_id(), {
			"class_id": String(_run_state.player_class_id),
			"seed": int(_run_state.seed),
			"source": "continue_run",
		}, true)
	_after_run_state_changed()

func _on_reset_run_pressed() -> void:
	if _begin_tournament_in_progress and _run_state.phase == "idle":
		_run_start_finalize_queued = false
		_begin_tournament_transition_token += 1
		_run_start_finalize_token += 1
		_reset_begin_tournament_transition_state()
		_front_screen_mode = FRONT_SCREEN_CLASS_SELECT
		_queue_refresh_ui()
		return
	if _run_state.phase == "idle":
		_front_screen_mode = FRONT_SCREEN_LANDING
		_queue_refresh_ui()
		return
	var telemetry = _telemetry_service()
	if telemetry != null and not _run_completion_recorded:
		telemetry.finish_run("abandoned", {
			"class_id": String(_run_state.player_class_id),
			"phase": String(_run_state.phase),
			"act": int(_run_state.current_act),
		})
	_run_completion_recorded = false
	_run_state.abandon_run()
	_save_manager.clear_active_run()
	_front_screen_mode = FRONT_SCREEN_LANDING
	_reset_telemetry_cursor()
	_queue_refresh_ui()

func _on_map_node_selected(node_id: int) -> void:
	_path_select_hovered_node_id = -1
	if _run_state.select_node(node_id):
		_after_run_state_changed()

func _on_path_select_node_hovered(node_id: int) -> void:
	_path_select_hovered_node_id = node_id
	if String(_run_state.phase) == "map" and is_instance_valid(_path_select_panel) and _path_select_panel.visible:
		_refresh_path_select_hover_detail()

func _on_path_select_node_hover_cleared() -> void:
	_path_select_hovered_node_id = -1
	if String(_run_state.phase) == "map" and is_instance_valid(_path_select_panel) and _path_select_panel.visible:
		_refresh_path_select_hover_detail()

func _on_hand_card_pressed(card_index: int) -> void:
	var previous_phase := String(_run_state.phase)
	var previous_match = _run_state.active_match
	if _run_state.play_card(card_index):
		_after_match_action_changed(previous_phase, previous_match)

func _on_end_turn_pressed() -> void:
	var previous_phase := String(_run_state.phase)
	var previous_match = _run_state.active_match
	_run_state.end_player_turn()
	_after_match_action_changed(previous_phase, previous_match)

func _on_potion_pressed(potion_index: int) -> void:
	var previous_phase := String(_run_state.phase)
	var previous_match = _run_state.active_match
	if _run_state.use_potion(potion_index):
		_after_match_action_changed(previous_phase, previous_match)

func _on_reward_selected(reward_index: int) -> void:
	var reward_choices := _run_state.get_reward_choices()
	var selected_reward := Dictionary(reward_choices[reward_index]) if reward_index >= 0 and reward_index < reward_choices.size() else {}
	if _run_state.choose_reward(reward_index):
		var telemetry = _telemetry_service()
		if telemetry != null:
			var reward_type := String(selected_reward.get("reward_type", selected_reward.get("kind", "")))
			var telemetry_kind := "reward_selected"
			match reward_type:
				"card":
					telemetry_kind = "card_picked"
				"card_upgrade", "reward_upgrade":
					telemetry_kind = "card_upgraded"
				"deck_trim", "shop_remove":
					telemetry_kind = "card_removed"
				"shop_card":
					telemetry_kind = "shop_card_bought"
				"shop_potion":
					telemetry_kind = "potion_acquired"
				"shop_relic":
					telemetry_kind = "relic_acquired"
				"racquet_upgrade":
					telemetry_kind = "racquet_tuned"
			telemetry.log_event(telemetry_kind, {
				"reward_index": reward_index,
				"reward_kind": reward_type,
				"reward_label": String(selected_reward.get("label", selected_reward.get("name", selected_reward.get("card_name", selected_reward.get("title", ""))))),
				"card_id": String(selected_reward.get("card_id", selected_reward.get("base_card_id", ""))),
				"upgraded_card_id": String(selected_reward.get("upgraded_card_id", "")),
				"price_btc": int(selected_reward.get("price_btc", 0)),
			})
		_after_run_state_changed()

func _on_skip_reward_pressed() -> void:
	var telemetry = _telemetry_service()
	if telemetry != null and String(_run_state.phase) == "reward":
		telemetry.log_event("reward_skipped", {
			"reward_kind": _current_reward_menu_kind(),
			"reason": String(_run_state.pending_reward_reason),
		})
	_run_state.skip_reward()
	_after_run_state_changed()

func _on_dismiss_reveal_pressed() -> void:
	_run_state.dismiss_reveal()
	_sync_active_run_checkpoint()
	_queue_refresh_ui()

func _on_reveal_proceed_pressed() -> void:
	if _run_state.phase == "map":
		_run_state.dismiss_reveal()
		if _run_state.advance_to_primary_accessible_node():
			_after_run_state_changed()
			return
	elif _run_state.has_reveal():
		_run_state.dismiss_reveal()
	_sync_active_run_checkpoint()
	_queue_refresh_ui()

func _on_primary_action_pressed() -> void:
	match _run_state.phase:
		"map":
			_run_state.dismiss_reveal()
			if _run_state.advance_to_primary_accessible_node():
				_after_run_state_changed()
				return
		"reward":
			_on_skip_reward_pressed()
			return
		"run_won", "run_lost":
			_on_reset_run_pressed()
			return
	_sync_active_run_checkpoint()
	_queue_refresh_ui()

func _after_run_state_changed() -> void:
	_process_run_completion_if_needed()
	_auto_enter_opening_match_if_needed()
	_sync_active_run_checkpoint()
	_sync_telemetry_state()
	_queue_refresh_ui()

func _after_match_action_changed(previous_phase: String, previous_match) -> void:
	_process_run_completion_if_needed()
	_auto_enter_opening_match_if_needed()
	if previous_match != null and _run_state.active_match == null and previous_phase == "combat":
		_log_encounter_outcome(previous_match)
	_sync_active_run_checkpoint()
	_sync_telemetry_state()
	var match_changed: bool = previous_match != _run_state.active_match
	var phase_changed: bool = previous_phase != String(_run_state.phase)
	if match_changed or phase_changed or _run_state.active_match == null:
		_queue_refresh_ui()
	else:
		_sync_match_event_bus()

func _sync_match_event_bus() -> void:
	if not is_instance_valid(_match_event_bus):
		return
	if _bound_match_for_events == _run_state.active_match:
		return
	if _run_state.active_match == null:
		_match_event_bus.clear_match()
		_bound_match_for_events = null
		return
	_match_event_bus.bind_match(_run_state.active_match)
	_bound_match_for_events = _run_state.active_match

func _queue_live_match_refresh() -> void:
	if _live_match_refresh_queued or _ui_tearing_down:
		return
	_live_match_refresh_queued = true
	call_deferred("_flush_live_match_refresh")

func _flush_live_match_refresh() -> void:
	_live_match_refresh_queued = false
	if _ui_tearing_down or _run_state.active_match == null:
		return
	_refresh_live_match_views()

func _refresh_live_match_views() -> void:
	if _run_state.active_match == null:
		_clear_stage_visual_presentation()
		return
	var major_data: Dictionary = {} if _run_state.phase == "idle" else _run_state.get_major_data()
	_refresh_combat_stage(major_data)
	_refresh_potion_rows(major_data)
	_sync_stage_visual_presentation(major_data)
	end_turn_button.disabled = _run_state.active_match == null or _run_state.active_match.state != "player_turn"
	stage_end_turn_button.disabled = end_turn_button.disabled

func _on_match_point_started(context: Dictionary) -> void:
	_queue_live_match_refresh()
	var palette := _current_combat_palette()
	var server := String(context.get("server", "player"))
	if server == "player":
		_stage_unit_pulse(stage_player_unit_view, "activation")
		_stage_target_ping(stage_player_unit_view, "primary")
	else:
		_stage_unit_pulse(stage_enemy_unit_view, "activation")
		_stage_target_ping(stage_enemy_unit_view, "impact")
	_play_stage_fx(Color(palette.get("primary", Color(0.72, 0.90, 1.0))), 0.16)

func _on_match_card_played(actor: String, _card_id: String, delta: Dictionary) -> void:
	_queue_live_match_refresh()
	_play_attack_presentation(actor, delta)
	_play_stage_fx(Color(_current_combat_palette().get("neutral", Color(0.95, 0.97, 1.0))), 0.12)

func _on_match_rally_updated(_snapshot: Dictionary) -> void:
	_queue_live_match_refresh()

func _on_match_point_ended(winner: String, _score_snapshot: Dictionary, condition_delta: Dictionary) -> void:
	_queue_live_match_refresh()
	var palette := _current_combat_palette()
	if winner == "player":
		_stage_unit_status(stage_player_unit_view, Color(palette.get("positive", Color(0.80, 1.0, 0.84))))
		_stage_unit_status(stage_enemy_unit_view, Color(palette.get("overlay", Color(0.72, 0.56, 0.92))))
	else:
		_stage_unit_status(stage_enemy_unit_view, Color(palette.get("impact", Color(1.0, 0.82, 0.80))))
		_stage_unit_status(stage_player_unit_view, Color(palette.get("impact", Color(1.0, 0.82, 0.80))))
		if int(condition_delta.get("player", 0)) < 0:
			_stage_target_ping(stage_player_unit_view, "impact")
	var flash := Color(palette.get("positive", Color(0.80, 1.0, 0.84))) if winner == "player" else Color(palette.get("impact", Color(1.0, 0.82, 0.80)))
	_play_stage_fx(flash, 0.24)

func _current_combat_palette() -> Dictionary:
	var major_data: Dictionary = {} if _run_state.phase == "idle" else _run_state.get_major_data()
	var major_theme := _get_presentation_theme(major_data)
	var battle: Dictionary = _run_state.active_match.get_battle_presentation() if _run_state.active_match != null else {}
	var player_subject := _build_class_asset_subject(_get_selected_class(), true)
	var enemy_subject := _build_enemy_asset_subject(battle, major_theme)
	if theme_manager != null and theme_manager.has_method("get_combat_palette"):
		return theme_manager.call("get_combat_palette", major_theme, player_subject, enemy_subject)
	return {
		"primary": Color(major_theme.get("accent", Color(0.36, 0.82, 1.0))),
		"positive": Color(0.54, 0.96, 0.48, 1.0),
		"impact": Color(0.98, 0.56, 0.28, 1.0),
		"overlay": Color(0.55, 0.34, 0.90, 1.0),
		"neutral": Color(major_theme.get("text", Color(0.95, 0.98, 1.0))),
		"player_accent": Color(player_subject.get("accent_color", Color(0.36, 0.82, 1.0))),
		"player_glow": Color(player_subject.get("glow_color", Color(0.36, 0.82, 1.0))),
		"enemy_accent": Color(enemy_subject.get("accent_color", Color(0.98, 0.56, 0.28))),
		"enemy_glow": Color(enemy_subject.get("glow_color", Color(0.55, 0.34, 0.90))),
	}

func _build_player_unit_data(player_subject: Dictionary, palette: Dictionary):
	var unit_data = _unit_database.get_default_player().duplicate_data()
	unit_data.display_name = String(player_subject.get("title", "Player"))
	unit_data.face_left = false
	unit_data.aura_modulate = Color(palette.get("player_glow", player_subject.get("glow_color", palette.get("primary", Color.WHITE))))
	unit_data.aura_modulate.a = 0.32
	unit_data.racquet_modulate = Color(palette.get("player_accent", player_subject.get("accent_color", Color.WHITE))).lightened(0.14)
	unit_data.hit_flash_color = Color(palette.get("primary", Color.WHITE)).lightened(0.16)
	return unit_data

func _build_enemy_unit_data(enemy_subject: Dictionary, palette: Dictionary):
	var unit_data = _unit_database.get_default_enemy().duplicate_data()
	unit_data.display_name = String(enemy_subject.get("title", "Opponent"))
	unit_data.face_left = true
	unit_data.aura_modulate = Color(palette.get("enemy_glow", enemy_subject.get("glow_color", palette.get("impact", Color.WHITE))))
	unit_data.aura_modulate.a = 0.30
	unit_data.racquet_modulate = Color(palette.get("enemy_accent", enemy_subject.get("accent_color", Color.WHITE))).lightened(0.10)
	unit_data.hit_flash_color = Color(palette.get("impact", Color.WHITE)).lightened(0.16)
	return unit_data

func _sync_stage_visual_presentation(major_data: Dictionary) -> void:
	if _run_state.active_match == null or not combat_stage_panel.visible:
		_clear_stage_visual_presentation()
		return
	var major_theme := _get_presentation_theme(major_data)
	var battle: Dictionary = _run_state.active_match.get_battle_presentation()
	var player_subject := _build_class_asset_subject(_get_selected_class(), true)
	var enemy_subject := _build_enemy_asset_subject(battle, major_theme)
	var palette := _current_combat_palette()
	var player_data = _build_player_unit_data(player_subject, palette)
	var enemy_data = _build_enemy_unit_data(enemy_subject, palette)
	if stage_arena_view.has_method("set_external_units_enabled"):
		stage_arena_view.call("set_external_units_enabled", true)
	if stage_player_unit_view != null and stage_player_unit_view.has_method("apply_unit_data"):
		stage_player_unit_view.visible = true
		stage_player_unit_view.apply_unit_data(player_data, {
			"accent": palette.get("player_accent", Color.WHITE),
			"overlay": palette.get("overlay", Color.WHITE),
			"shadow": palette.get("shadow", Color(0.03, 0.04, 0.08, 0.82)),
		})
	if stage_enemy_unit_view != null and stage_enemy_unit_view.has_method("apply_unit_data"):
		stage_enemy_unit_view.visible = true
		stage_enemy_unit_view.apply_unit_data(enemy_data, {
			"accent": palette.get("enemy_accent", Color.WHITE),
			"overlay": palette.get("overlay", Color.WHITE),
			"shadow": palette.get("shadow", Color(0.03, 0.04, 0.08, 0.82)),
		})
	if stage_fx_root != null and stage_fx_root.has_method("apply_theme_palette"):
		stage_fx_root.call("apply_theme_palette", palette)
	_sync_stage_visual_layout()

func _sync_stage_visual_layout() -> void:
	if _run_state.active_match == null or stage_arena_view == null:
		return
	if not stage_arena_view.has_method("get_layout_snapshot"):
		return
	var layout: Dictionary = stage_arena_view.call("get_layout_snapshot")
	if layout.is_empty():
		return
	var player_anchor := Vector2(layout.get("player_anchor", Vector2.ZERO))
	var enemy_anchor := Vector2(layout.get("enemy_anchor", Vector2.ZERO))
	if stage_player_unit_view != null and stage_player_unit_view.has_method("set_anchor_position"):
		stage_player_unit_view.call("set_anchor_position", player_anchor)
	if stage_enemy_unit_view != null and stage_enemy_unit_view.has_method("set_anchor_position"):
		stage_enemy_unit_view.call("set_anchor_position", enemy_anchor)

func _clear_stage_visual_presentation() -> void:
	if stage_arena_view != null and stage_arena_view.has_method("set_external_units_enabled"):
		stage_arena_view.call("set_external_units_enabled", false)
	if stage_player_unit_view != null:
		stage_player_unit_view.visible = false
		if stage_player_unit_view.has_method("clear_feedback"):
			stage_player_unit_view.call("clear_feedback")
	if stage_enemy_unit_view != null:
		stage_enemy_unit_view.visible = false
		if stage_enemy_unit_view.has_method("clear_feedback"):
			stage_enemy_unit_view.call("clear_feedback")
	if stage_fx_root != null and stage_fx_root.has_method("clear_fx"):
		stage_fx_root.call("clear_fx")

func _play_attack_presentation(actor: String, delta: Dictionary) -> void:
	if _run_state.active_match == null:
		return
	var palette := _current_combat_palette()
	var attacker = stage_player_unit_view if actor == "player" else stage_enemy_unit_view
	var defender = stage_enemy_unit_view if actor == "player" else stage_player_unit_view
	if attacker != null:
		attacker.visible = true
		if attacker.has_method("play_attack"):
			attacker.call("play_attack")
	if defender != null:
		defender.visible = true
		if defender.has_method("play_hit_reaction"):
			defender.call("play_hit_reaction", -1.0 if actor == "player" else 1.0)
	var start_position := stage_player_unit_view.position if actor == "player" else stage_enemy_unit_view.position
	var end_position := stage_enemy_unit_view.position if actor == "player" else stage_player_unit_view.position
	if stage_fx_root != null and stage_fx_root.has_method("play_attack_exchange"):
		stage_fx_root.call(
			"play_attack_exchange",
			start_position + Vector2(0.0, -58.0),
			end_position + Vector2(0.0, -68.0),
			actor,
			String(delta.get("shot_family", ""))
		)
	if actor == "player":
		_stage_target_ping(stage_enemy_unit_view, "impact")
	else:
		_stage_target_ping(stage_player_unit_view, "impact")

func _stage_unit_pulse(unit_view: Node2D, kind: String) -> void:
	if unit_view == null:
		return
	unit_view.visible = true
	match kind:
		"activation":
			if unit_view.has_method("pulse_activation"):
				unit_view.call("pulse_activation")
		_:
			pass

func _stage_unit_status(unit_view: Node2D, color_value: Color) -> void:
	if unit_view == null:
		return
	unit_view.visible = true
	if unit_view.has_method("pulse_status"):
		unit_view.call("pulse_status", color_value)

func _stage_target_ping(unit_view: Node2D, kind: String) -> void:
	if unit_view == null:
		return
	unit_view.visible = true
	if unit_view.has_method("set_targeted"):
		unit_view.call("set_targeted", true)
	if stage_fx_root != null and stage_fx_root.has_method("play_target_ping"):
		stage_fx_root.call("play_target_ping", unit_view.position + Vector2(0.0, -62.0), kind)

func _play_match_raw_event_fx(kind: String, side: String, payload: Dictionary) -> void:
	if _run_state.active_match == null or stage_fx_root == null:
		return
	match kind:
		"pressure_shifted":
			var applied := int(payload.get("applied", 0))
			if applied == 0:
				return
			var target_unit := stage_enemy_unit_view if side == "player" else stage_player_unit_view
			_stage_target_ping(target_unit, "impact" if applied > 0 else "overlay")
		"potion_used":
			var target_unit := stage_player_unit_view if side != "enemy" else stage_enemy_unit_view
			_stage_unit_status(target_unit, Color(_current_combat_palette().get("positive", Color(0.54, 0.96, 0.48))))
			if stage_fx_root.has_method("play_status_pulse") and target_unit != null:
				stage_fx_root.call("play_status_pulse", target_unit.position + Vector2(0.0, -58.0), "positive")
		"turn_started":
			var target_unit := stage_player_unit_view if side != "enemy" else stage_enemy_unit_view
			_stage_target_ping(target_unit, "primary" if side != "enemy" else "impact")
		_:
			pass

func _play_stage_fx(flash_color: Color, duration: float) -> void:
	if not combat_stage_panel.visible:
		return
	if _reduced_motion_enabled():
		stage_score_hud.modulate = Color.WHITE
		stage_arena_panel.modulate = Color.WHITE
		return
	if is_instance_valid(_stage_fx_tween):
		_stage_fx_tween.kill()
	stage_score_hud.modulate = flash_color
	stage_arena_panel.modulate = flash_color
	_stage_fx_tween = create_tween()
	_stage_fx_tween.set_parallel(true)
	_stage_fx_tween.tween_property(stage_score_hud, "modulate", Color.WHITE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_stage_fx_tween.tween_property(stage_arena_panel, "modulate", Color.WHITE, duration + 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_stage_fx_tween.finished.connect(func() -> void:
		_stage_fx_tween = null
	)

func _auto_enter_opening_match_if_needed() -> void:
	if _run_state.phase != "map":
		return
	if _run_state.current_node_id >= 0:
		return
	if not _run_state.completed_node_ids.is_empty():
		return
	if _run_state.has_reveal():
		return
	if _run_state.get_primary_accessible_node_id() < 0:
		return
	_run_state.advance_to_primary_accessible_node()

func _process_run_completion_if_needed() -> void:
	if _run_state.run_failed:
		if _run_completion_recorded:
			_save_manager.clear_active_run()
			return
		var failed_telemetry = _telemetry_service()
		if failed_telemetry != null:
			failed_telemetry.finish_run("lost", {
				"class_id": String(_run_state.player_class_id),
				"act": int(_run_state.current_act),
			})
		_run_completion_recorded = true
		_save_manager.clear_active_run()
		return
	if not _run_state.run_complete or _run_completion_recorded:
		return

	var previous_clears := int(_progress.get("run_clears", 0))
	_progress["run_clears"] = previous_clears + 1
	_progress["last_selected_class"] = String(_run_state.player_class_id)
	_save_manager.save_progress(_progress)
	_sync_available_classes()
	_run_completion_recorded = true

	_run_state.status_message += "\nAll classes stay available. Build power now comes from route rewards, camp upgrades, shops, and boss checkpoints."
	_save_manager.clear_active_run()
	var won_telemetry = _telemetry_service()
	if won_telemetry != null:
		won_telemetry.finish_run("won", {
			"class_id": String(_run_state.player_class_id),
			"act": int(_run_state.current_act),
		})

func _sync_active_run_checkpoint() -> void:
	if _run_state.has_checkpoint():
		_save_manager.save_active_run(_run_state.to_snapshot())
	elif _run_state.run_complete or _run_state.run_failed or _run_state.phase in ["run_won", "run_lost"]:
		_save_manager.clear_active_run()

func _queue_refresh_ui() -> void:
	if _full_ui_refresh_queued or _ui_tearing_down or not is_inside_tree():
		return
	_full_ui_refresh_queued = true
	call_deferred("_flush_refresh_ui")

func _flush_refresh_ui() -> void:
	_full_ui_refresh_queued = false
	if _ui_tearing_down or not is_inside_tree():
		return
	_refresh_ui()

func _ensure_begin_tournament_progress() -> void:
	if not _begin_tournament_in_progress or _ui_tearing_down:
		return
	match String(_run_state.phase):
		"idle":
			if _front_screen_mode != FRONT_SCREEN_TRANSITION:
				_front_screen_mode = FRONT_SCREEN_TRANSITION
		"map":
			if _run_state.current_node_id < 0 and not _run_start_finalize_queued:
				_queue_start_run_finalization()
			elif _run_state.current_node_id >= 0:
				_reset_begin_tournament_transition_state()
		_:
			_reset_begin_tournament_transition_state()

func _refresh_ui() -> void:
	if _ui_tearing_down or not is_inside_tree():
		return
	_ensure_begin_tournament_progress()
	_refresh_accessibility_controls()
	var selected_class = _get_selected_class()
	var has_saved_run := _has_saved_run()
	var pane_state: Dictionary = _main_pane_state_presenter.build(_run_state, _front_screen_mode) if _main_pane_state_presenter != null else {}
	var is_idle: bool = bool(pane_state.get("is_idle", _run_state.phase == "idle"))
	var is_class_select_screen: bool = bool(pane_state.get("is_class_select_screen", false))
	var is_transition_screen: bool = bool(pane_state.get("is_transition_screen", false))
	var is_landing_screen: bool = bool(pane_state.get("is_landing_screen", false))
	var is_live_combat: bool = bool(pane_state.get("is_live_combat", _run_state.active_match != null))
	var reward_menu_kind := String(pane_state.get("reward_menu_kind", _current_reward_menu_kind()))
	var is_rest_checkpoint: bool = bool(pane_state.get("is_rest_checkpoint", reward_menu_kind == "rest"))
	var is_shop_checkpoint: bool = bool(pane_state.get("is_shop_checkpoint", reward_menu_kind == "shop"))
	var is_reward_checkpoint: bool = bool(pane_state.get("is_reward_checkpoint", _run_state.phase == "reward" and reward_menu_kind not in ["", "rest", "shop"]))
	var is_fullscreen_checkpoint: bool = bool(pane_state.get("is_fullscreen_checkpoint", is_rest_checkpoint or is_shop_checkpoint or is_reward_checkpoint))
	var is_path_select_screen: bool = bool(pane_state.get("is_path_select_screen", false))
	var is_fullscreen_flow_screen: bool = bool(pane_state.get("is_fullscreen_flow_screen", is_fullscreen_checkpoint or is_path_select_screen))
	var reveal_data: Dictionary = _run_state.get_reveal_data()
	var major_data: Dictionary = {} if _run_state.phase == "idle" else _run_state.get_major_data()
	_sync_match_event_bus()
	var show_accessibility_button := _accessibility_available_on_current_screen() and not is_transition_screen
	if is_instance_valid(_accessibility_button):
		_accessibility_button.visible = show_accessibility_button
	if is_instance_valid(_accessibility_overlay) and not show_accessibility_button:
		_accessibility_overlay.visible = false
		_awaiting_rebind_action = ""
	if not is_transition_screen:
		_refresh_meta_sidebar(selected_class, pane_state, has_saved_run)
	landing_center.visible = is_landing_screen
	action_callout_panel.visible = false
	combat_stage_panel.visible = is_live_combat
	if is_instance_valid(_combat_scroll):
		_combat_scroll.visible = is_live_combat
	rest_checkpoint_panel.visible = is_rest_checkpoint
	if is_instance_valid(_path_select_panel):
		_path_select_panel.visible = is_path_select_screen
	if not is_path_select_screen:
		_path_select_hovered_node_id = -1
	if is_instance_valid(_shop_checkpoint_panel):
		_shop_checkpoint_panel.visible = is_shop_checkpoint
	if is_instance_valid(_reward_checkpoint_panel):
		_reward_checkpoint_panel.visible = is_reward_checkpoint
	header_box.visible = bool(pane_state.get("show_header_box", (not is_live_combat) and (not is_fullscreen_flow_screen)))
	top_bar.visible = bool(pane_state.get("show_top_bar", false))
	body_split.visible = bool(pane_state.get("show_body_split", false))
	subtitle_label.visible = bool(pane_state.get("show_subtitle", false))
	reveal_panel.visible = bool(pane_state.get("show_reveal_panel", (not is_idle) and _run_state.has_reveal() and (not is_fullscreen_flow_screen)))
	reveal_title_label.text = String(reveal_data.get("title", ""))
	reveal_body_label.text = String(reveal_data.get("body", ""))
	_configure_reveal_actions()
	primary_action_button.visible = true
	if is_transition_screen:
		var transition_payload: Dictionary = _front_screen_presenter.build_transition_payload(selected_class) if _front_screen_presenter != null else {}
		action_callout_panel.visible = bool(transition_payload.get("callout_visible", true))
		action_callout_label.text = String(transition_payload.get("callout_text", ""))
		primary_action_button.visible = bool(transition_payload.get("primary_visible", false))
		if action_callout_icon.has_method("set"):
			action_callout_icon.set("icon_kind", String(transition_payload.get("icon_kind", "ball")))
	elif (not is_live_combat) and (not is_fullscreen_flow_screen):
		_refresh_primary_action(has_saved_run)
	landing_start_button.disabled = selected_class == null
	landing_start_button.text = "Start Run"
	if is_transition_screen:
		class_portrait.visible = false
		launch_panel.visible = false
		reveal_panel.visible = false
		_reset_point_context_flash_state()
		if is_instance_valid(_combat_scroll):
			_combat_scroll.visible = false
		_last_combat_layout_signature = ""
	else:
		_refresh_selection_portraits(selected_class)
		class_portrait.visible = not is_class_select_screen
		_apply_major_presentation(major_data)
		_maybe_play_major_stinger(major_data, reveal_data)
		_refresh_combat_panel()
		_refresh_combat_stage(major_data)
		_refresh_potion_rows(major_data)
		_refresh_rest_checkpoint_panel(selected_class, major_data)
		_refresh_shop_checkpoint_panel(major_data)
		_refresh_reward_checkpoint_panel(major_data)
		_refresh_path_select_panel(major_data)
		_refresh_reward_buttons()
		_refresh_equipment_bonus_panel()
		_refresh_log_panel()
	if is_live_combat:
		_queue_combat_stage_layout()
	else:
		_last_combat_layout_signature = ""

	var can_change_class := not _is_run_active() and not _begin_tournament_in_progress
	prev_button.disabled = not can_change_class or _available_classes.size() <= 1
	next_button.disabled = not can_change_class or _available_classes.size() <= 1
	start_run_button.disabled = selected_class == null or _begin_tournament_in_progress
	start_run_button.text = "Restart Run" if _is_run_active() else ("Begin Tournament" if is_class_select_screen else "Start Run")
	continue_run_button.disabled = _is_run_active() or not has_saved_run or _begin_tournament_in_progress
	launch_start_button.disabled = start_run_button.disabled
	launch_start_button.text = "Begin Tournament" if is_class_select_screen else start_run_button.text
	launch_continue_button.disabled = continue_run_button.disabled
	reset_run_button.disabled = is_landing_screen and not _begin_tournament_in_progress
	reset_run_button.text = "Back" if is_class_select_screen else "Abandon Run"
	end_turn_button.disabled = _run_state.active_match == null or _run_state.active_match.state != "player_turn"
	stage_end_turn_button.disabled = end_turn_button.disabled

func _refresh_meta_sidebar(selected_class, pane_state: Dictionary, has_saved_run: bool) -> void:
	if _meta_sidebar_controller == null:
		return
	_meta_sidebar_controller.refresh_overview(
		self,
		_run_state,
		selected_class,
		pane_state,
		_front_screen_mode,
		_ui_text_builder,
		_progress,
		_available_classes.size(),
		PlayerClassDatabaseScript.ORDER.size(),
		has_saved_run
	)

func _refresh_combat_panel() -> void:
	if _combat_screen_controller == null:
		return
	_combat_screen_controller.refresh_sidebar(
		self,
		_run_state,
		_combat_hud_presenter,
		_get_selected_class(),
		_available_classes.size(),
		PlayerClassDatabaseScript.ORDER.size(),
		RunStateScript.TOTAL_ACTS
	)

func _refresh_combat_stage(major_data: Dictionary) -> void:
	if _combat_screen_controller == null:
		return
	_combat_screen_controller.refresh_stage(
		self,
		_run_state,
		major_data,
		_combat_hud_presenter,
		_player_logic_tree,
		_class_database
	)

func _reset_point_context_flash_state() -> void:
	_last_stage_point_context = ""
	if is_instance_valid(_point_context_flash_tween):
		_point_context_flash_tween.kill()
	_point_context_flash_tween = null
	stage_serve_state_panel.modulate = Color.WHITE
	stage_hand_panel.modulate = Color.WHITE

func _maybe_flash_point_context(point_context: String) -> void:
	if _reduced_motion_enabled():
		_last_stage_point_context = point_context
		return
	if point_context == "":
		return
	if _last_stage_point_context == "":
		_last_stage_point_context = point_context
		return
	if _last_stage_point_context == point_context:
		return
	_play_point_context_flash(point_context)
	_last_stage_point_context = point_context

func _play_point_context_flash(point_context: String) -> void:
	if _reduced_motion_enabled():
		return
	var flash_color := Color(0.88, 0.94, 1.0, 1.0)
	match point_context:
		"serve":
			flash_color = Color(0.72, 0.90, 1.0, 1.0)
		"return":
			flash_color = Color(0.78, 1.0, 0.82, 1.0)
		"rally":
			flash_color = Color(0.94, 0.97, 1.0, 1.0)
	if is_instance_valid(_point_context_flash_tween):
		_point_context_flash_tween.kill()
	stage_serve_state_panel.modulate = flash_color
	stage_hand_panel.modulate = flash_color
	_point_context_flash_tween = create_tween()
	_point_context_flash_tween.set_parallel(true)
	_point_context_flash_tween.tween_property(stage_serve_state_panel, "modulate", Color.WHITE, 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_point_context_flash_tween.tween_property(stage_hand_panel, "modulate", Color.WHITE, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_point_context_flash_tween.finished.connect(func() -> void:
		_point_context_flash_tween = null
	)

func _format_accessible_point_context_banner(point_context: String, banner: String) -> String:
	if not _high_contrast_enabled():
		return banner
	match point_context:
		"serve":
			return "[SERVE] %s" % banner
		"return":
			return "[RETURN] %s" % banner
		_:
			return "[RALLY] %s" % banner

func _battle_initial_contact_context(battle: Dictionary) -> String:
	var context := String(battle.get("initial_contact_context", ""))
	if context != "":
		return context
	if int(battle.get("rally_exchanges", 0)) > 0:
		return "rally"
	return "serve" if String(battle.get("server", "player")) == "player" else "return"

func _battle_initial_contact_banner(battle: Dictionary) -> String:
	var banner := String(battle.get("initial_contact_banner", ""))
	if banner != "":
		return banner
	match _battle_initial_contact_context(battle):
		"serve":
			return "SERVE WINDOW"
		"return":
			return "RETURN WINDOW"
		_:
			return "RALLY LIVE"

func _battle_initial_contact_hint(battle: Dictionary) -> String:
	var hint := String(battle.get("initial_contact_hint", ""))
	if hint != "":
		return hint
	match _battle_initial_contact_context(battle):
		"serve":
			return "You are serving this point. Open with a serve card from the INITIAL slot."
		"return":
			return "The opponent is serving. Open with a return card from the INITIAL slot."
		_:
			return "The opening contact is gone. Serve and return cards are now locked for this point."

func _build_turn_hint(active_match, point_context: String, logic_tree: Dictionary = {}) -> String:
	if active_match.state != "player_turn":
		return "Enemy pattern resolving."
	var recommendation := String(logic_tree.get("recommended_card_name", ""))
	var recommendation_reason := String(logic_tree.get("recommended_reason", ""))
	match point_context:
		"serve":
			if recommendation != "":
				return "Serve: %s. %s" % [recommendation, recommendation_reason]
			return "Serve: use INITIAL, then plus-one."
		"return":
			if recommendation != "":
				return "Return: %s. %s" % [recommendation, recommendation_reason]
			return "Return: use INITIAL, then redirect or stabilize."
		_:
			if recommendation != "":
				return "Rally: %s. %s" % [recommendation, recommendation_reason]
			return "Rally: chain SHOT, ENHANCER, and MODIFIER."

func _apply_point_context_badge(theme: Dictionary, point_context: String) -> void:
	var text_color := Color(theme.get("text", Color.WHITE))
	var fill_color := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.02)
	var border_color := text_color.lerp(fill_color, 0.20)
	match point_context:
		"serve":
			fill_color = Color(0.12, 0.24, 0.42, 0.96)
			border_color = Color(0.54, 0.84, 1.0, 1.0)
		"return":
			fill_color = Color(0.12, 0.30, 0.18, 0.96)
			border_color = Color(0.62, 0.96, 0.70, 1.0)
	if _high_contrast_enabled():
		fill_color = fill_color.darkened(0.28)
		border_color = border_color.lightened(0.18)
		text_color = Color.WHITE
	_apply_panel_style(stage_serve_state_panel, fill_color, border_color)
	stage_serve_state_label.add_theme_color_override("font_color", text_color)

func _refresh_rest_checkpoint_panel(selected_class, major_data: Dictionary) -> void:
	if _checkpoint_screen_controller == null:
		return
	_checkpoint_screen_controller.refresh_rest_panel(
		self,
		_run_state,
		selected_class,
		major_data,
		_checkpoint_pane_presenter,
		RunStateScript.MAX_POTIONS
	)

func _refresh_path_select_panel(major_data: Dictionary) -> void:
	if _path_select_screen_controller == null or _path_select_pane_presenter == null:
		return
	var payload: Dictionary = _path_select_pane_presenter.build(_run_state, _path_select_hovered_node_id)
	_path_select_screen_controller.refresh_path_panel(self, payload, major_data)

func _refresh_path_select_hover_detail() -> void:
	if _path_select_screen_controller == null or _path_select_pane_presenter == null:
		return
	var payload: Dictionary = _path_select_pane_presenter.build_detail(_run_state, _path_select_hovered_node_id)
	_path_select_screen_controller.refresh_path_detail(self, payload)

func _build_rest_choice_payload(reward: Dictionary) -> Dictionary:
	var reward_type := String(reward.get("reward_type", "rest_heal"))
	var payload: Dictionary = reward.duplicate(true)
	match reward_type:
		"rest_heal":
			payload["display_title"] = "Rest"
			payload["display_description"] = String(reward.get("description", "Recover and reset before the next round."))
			payload["display_type"] = "REST"
			payload["display_art"] = "Ice Bath Reset"
			payload["display_icon"] = "focus"
		"reward_upgrade":
			payload["display_title"] = String(reward.get("name", "Upgrade Card"))
			payload["display_description"] = String(reward.get("description", "Upgrade one copy to its + version, then trim one card."))
			payload["display_type"] = "UPGRADE"
			payload["display_art"] = "Camp Workshop"
			payload["display_icon"] = "racquet_tune"
		_:
			payload["display_title"] = String(reward.get("name", "Camp Action"))
	return payload

func _ensure_class_showcase_panel() -> void:
	if class_margin == null or class_view == null:
		return
	if not is_instance_valid(_class_content_vbox):
		var existing_vbox := class_margin.get_node_or_null("ClassContentVBox")
		if existing_vbox is VBoxContainer:
			_class_content_vbox = existing_vbox
		else:
			var content_vbox := VBoxContainer.new()
			content_vbox.name = "ClassContentVBox"
			content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			content_vbox.add_theme_constant_override("separation", 14)
			class_margin.add_child(content_vbox)
			class_margin.move_child(content_vbox, 0)
			_class_content_vbox = content_vbox
		if class_view.get_parent() != _class_content_vbox:
			var previous_parent := class_view.get_parent()
			if previous_parent != null:
				previous_parent.remove_child(class_view)
			_class_content_vbox.add_child(class_view)
	class_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	class_view.scroll_active = true
	class_view.fit_content = false
	class_view.custom_minimum_size = Vector2(0, 260)

	if is_instance_valid(_class_showcase_panel):
		if _class_showcase_panel.get_parent() != _class_content_vbox:
			var old_parent := _class_showcase_panel.get_parent()
			if old_parent != null:
				old_parent.remove_child(_class_showcase_panel)
			_class_content_vbox.add_child(_class_showcase_panel)
			_class_content_vbox.move_child(_class_showcase_panel, 0)
		return

	var panel := PanelContainer.new()
	panel.name = "ClassShowcasePanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 206)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var portrait := PortraitTile.new()
	portrait.name = "ClassShowcasePortrait"
	portrait.custom_minimum_size = Vector2(152, 152)
	row.add_child(portrait)

	var details := VBoxContainer.new()
	details.name = "ClassShowcaseDetails"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 8)
	row.add_child(details)

	var name_label := Label.new()
	name_label.name = "ClassShowcaseName"
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(name_label)

	var subtitle_label := Label.new()
	subtitle_label.name = "ClassShowcaseSubtitle"
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(subtitle_label)

	var meta_label := Label.new()
	meta_label.name = "ClassShowcaseMeta"
	meta_label.add_theme_font_size_override("font_size", 14)
	meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(meta_label)

	var chip_row := HBoxContainer.new()
	chip_row.name = "ClassShowcaseChipRow"
	chip_row.add_theme_constant_override("separation", 8)
	details.add_child(chip_row)

	_class_content_vbox.add_child(panel)
	_class_content_vbox.move_child(panel, 0)

	_class_showcase_panel = panel
	_class_showcase_portrait = portrait
	_class_showcase_name_label = name_label
	_class_showcase_subtitle_label = subtitle_label
	_class_showcase_meta_label = meta_label
	_class_showcase_chip_row = chip_row

func _refresh_class_showcase_panel(selected_class) -> void:
	if _front_screen_controller == null:
		return
	_front_screen_controller.refresh_class_showcase(self, selected_class)

func _refresh_selection_portraits(selected_class) -> void:
	if _front_screen_controller == null:
		return
	_front_screen_controller.refresh_selection(self, selected_class)

func _build_class_asset_subject(selected_class, compact: bool = false) -> Dictionary:
	if selected_class == null:
		return {
			"title": "No Class",
			"subtitle": "Select a class",
			"accent_color": Color(0.84, 0.90, 0.98),
			"glow_color": Color(0.36, 0.52, 0.78),
			"frame_color": Color(0.94, 0.96, 1.0),
			"inner_color": Color(0.10, 0.14, 0.22),
			"silhouette_kind": "hero",
			"energy_kind": "arc",
			"enemy": false,
			"portrait_kind": "player",
			"variant_kind": "novice",
			"texture_path": "",
		}
	var theme: Dictionary = Dictionary(CLASS_ASSET_THEMES.get(String(selected_class.id), CLASS_ASSET_THEMES["novice"]))
	var model = _model_database.get_model(selected_class.id)
	var subtitle: String = selected_class.archetype
	if model != null and not compact:
		subtitle = model.model_name
	return {
		"title": selected_class.name,
		"subtitle": subtitle,
		"accent_color": Color(theme.get("accent", Color.WHITE)),
		"glow_color": Color(theme.get("glow", Color.WHITE)),
		"frame_color": Color(theme.get("frame", Color.WHITE)),
		"inner_color": Color(theme.get("inner", Color(0.12, 0.15, 0.22))),
		"silhouette_kind": String(theme.get("silhouette", "hero")),
		"energy_kind": String(theme.get("energy", "arc")),
		"enemy": false,
		"portrait_kind": "player",
		"variant_kind": String(selected_class.id),
		"texture_path": _find_portrait_texture_path("classes", String(selected_class.id)),
	}

func _build_enemy_asset_subject(battle: Dictionary, major_theme: Dictionary) -> Dictionary:
	var enemy_id := String(battle.get("enemy_id", ""))
	var enemy_name := enemy_id if enemy_id != "" else String(battle.get("enemy", {}))
	var enemy_style := String(battle.get("enemy_style", "Opponent"))
	var enemy_keywords := _keyword_array(battle.get("enemy_keywords", PackedStringArray()))
	var accent := Color(major_theme.get("accent", Color(0.92, 0.44, 0.22)))
	var glow := Color(0.92, 0.36, 0.22, 1.0)
	var inner := Color(0.19, 0.08, 0.09, 1.0)
	var frame := Color(0.99, 0.86, 0.78, 1.0)
	var silhouette := "hero"
	var energy := "burst"
	if enemy_keywords.has("machine"):
		accent = Color(0.60, 0.94, 1.0, 1.0)
		glow = Color(0.18, 0.74, 0.98, 1.0)
		inner = Color(0.06, 0.13, 0.18, 1.0)
		silhouette = "machine"
		energy = "flare"
	elif enemy_style.findn("Monster") >= 0:
		accent = Color(0.98, 0.76, 0.42, 1.0)
		glow = Color(0.92, 0.30, 0.20, 1.0)
		inner = Color(0.18, 0.08, 0.08, 1.0)
		silhouette = "horns"
		if enemy_name.findn("wraith") >= 0 or enemy_name.findn("specter") >= 0 or enemy_name.findn("umbra") >= 0 or enemy_name.findn("reaper") >= 0:
			silhouette = "hood"
		elif enemy_name.findn("golem") >= 0 or enemy_name.findn("ogre") >= 0 or enemy_name.findn("troll") >= 0 or enemy_name.findn("colossus") >= 0 or enemy_name.findn("brute") >= 0:
			silhouette = "brute"
	elif enemy_keywords.has("grass"):
		accent = Color(0.72, 0.98, 0.62, 1.0)
		glow = Color(0.34, 0.74, 0.28, 1.0)
		inner = Color(0.08, 0.18, 0.09, 1.0)
		energy = "arc"
	elif enemy_keywords.has("clay"):
		accent = Color(0.99, 0.72, 0.36, 1.0)
		glow = Color(0.88, 0.34, 0.14, 1.0)
		inner = Color(0.20, 0.09, 0.06, 1.0)
	elif enemy_keywords.has("hardcourt"):
		accent = Color(0.64, 0.82, 1.0, 1.0)
		glow = Color(0.28, 0.56, 0.96, 1.0)
		inner = Color(0.06, 0.12, 0.24, 1.0)
	var variant_kind := _enemy_variant_kind(enemy_name, enemy_style, enemy_keywords)
	return {
		"title": String(Dictionary(battle.get("enemy", {})).get("name", enemy_name)),
		"subtitle": enemy_style,
		"accent_color": accent,
		"glow_color": glow,
		"frame_color": frame,
		"inner_color": inner,
		"silhouette_kind": silhouette,
		"energy_kind": energy,
		"enemy": true,
		"portrait_kind": "enemy",
		"variant_kind": variant_kind,
		"texture_path": _find_portrait_texture_path("enemies", enemy_id if enemy_id != "" else String(Dictionary(battle.get("enemy", {})).get("name", enemy_name))),
	}

func _enemy_variant_kind(enemy_name: String, enemy_style: String, enemy_keywords: PackedStringArray) -> String:
	var lowered_name := enemy_name.to_lower()
	var lowered_style := enemy_style.to_lower()
	if enemy_keywords.has("pair") or lowered_style.find("rivals") >= 0 or lowered_name.find("duo") >= 0:
		return "duo"
	if enemy_keywords.has("machine") or lowered_name.find("machine") >= 0 or lowered_name.find("servebot") >= 0 or lowered_name.find("scoreboard") >= 0:
		return "machine"
	if lowered_name.find("wraith") >= 0 or lowered_name.find("specter") >= 0 or lowered_name.find("umbra") >= 0 or lowered_name.find("reaper") >= 0:
		return "specter"
	if lowered_name.find("gargoyle") >= 0 or lowered_name.find("ogre") >= 0 or lowered_name.find("colossus") >= 0 or lowered_name.find("troll") >= 0 or lowered_name.find("golem") >= 0:
		return "stone"
	if lowered_name.find("vampire") >= 0:
		return "vampire"
	if lowered_style.find("human") >= 0:
		return "human"
	return "beast"

func _keyword_array(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var keywords := PackedStringArray()
	if value is Array:
		for entry in value:
			keywords.append(String(entry))
	return keywords

func _find_portrait_texture_path(folder: String, asset_id: String) -> String:
	if asset_id.strip_edges() == "":
		return ""
	var sanitized := asset_id.strip_edges().to_lower()
	sanitized = sanitized.replace(" ", "_")
	sanitized = sanitized.replace("&", "and")
	sanitized = sanitized.replace("'", "")
	sanitized = sanitized.replace("-", "_")
	var candidate_stems := [
		"%s/%s/%s" % [PORTRAIT_BASE_PATH, folder, sanitized],
		"%s/%s/%s/portrait" % [PORTRAIT_BASE_PATH, folder, sanitized],
		"%s/%s/%s/card" % [PORTRAIT_BASE_PATH, folder, sanitized],
		"%s/%s/%s/hero" % [PORTRAIT_BASE_PATH, folder, sanitized],
		"%s/%s/%s/bust" % [PORTRAIT_BASE_PATH, folder, sanitized],
		"%s/%s/%s/main" % [PORTRAIT_BASE_PATH, folder, sanitized],
	]
	for extension in PORTRAIT_EXTENSIONS:
		for stem in candidate_stems:
			var candidate := "%s.%s" % [stem, extension]
			if ResourceLoader.exists(candidate):
				return candidate
	return ""

func _refresh_status_row(container: HBoxContainer, statuses_value, theme: Dictionary, align_right: bool = false) -> void:
	if container == null:
		return
	var statuses := PackedStringArray()
	if typeof(statuses_value) == TYPE_PACKED_STRING_ARRAY:
		statuses = statuses_value
	elif statuses_value is Array:
		for entry in statuses_value:
			statuses.append(String(entry))
	var stable_label := _get_status_row_stable_label(container)
	if statuses.is_empty():
		stable_label.text = "Stable"
		stable_label.visible = true
		stable_label.add_theme_color_override("font_color", Color(theme.get("text", Color.WHITE)).lerp(Color(theme.get("panel", Color.BLACK)), 0.30))
		_hide_pooled_controls(_get_status_chip_pool(container))
		return
	stable_label.visible = false
	var pool := _get_status_chip_pool(container)
	for index in range(statuses.size()):
		var chip = _get_pooled_status_chip(container, pool, index, align_right)
		_apply_status_chip(chip, String(statuses[index]), theme, align_right)
		chip.visible = true
	for index in range(statuses.size(), pool.size()):
		var extra = pool[index]
		if extra != null:
			extra.visible = false

func _build_status_chip(status_token: String, theme: Dictionary, align_right: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	var accent := Color(theme.get("accent", Color.WHITE))
	var fill := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.08)
	_apply_panel_style(panel, fill, accent.lerp(fill, 0.18))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if align_right else BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)
	var icon: Control = BadgeIconScript.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.icon_kind = _status_icon_kind_from_token(status_token)
	icon.set_palette(accent, Color(theme.get("text", Color.WHITE)))
	row.add_child(icon)
	var label := Label.new()
	label.text = status_token
	label.add_theme_color_override("font_color", Color(theme.get("text", Color.WHITE)))
	row.add_child(label)
	panel.set_meta("status_icon", icon)
	panel.set_meta("status_label", label)
	return panel

func _get_status_row_stable_label(container: HBoxContainer) -> Label:
	var key := str(container.get_instance_id())
	if _status_row_stable_labels.has(key):
		return _status_row_stable_labels[key]
	var label := Label.new()
	label.visible = false
	container.add_child(label)
	_status_row_stable_labels[key] = label
	return label

func _get_status_chip_pool(container: HBoxContainer) -> Array:
	var key := str(container.get_instance_id())
	if not _status_row_pools.has(key):
		_status_row_pools[key] = []
	return _status_row_pools[key]

func _get_pooled_status_chip(container: HBoxContainer, pool: Array, index: int, align_right: bool) -> PanelContainer:
	while pool.size() <= index:
		var chip := _build_status_chip("", {}, align_right)
		chip.visible = false
		pool.append(chip)
		container.add_child(chip)
	var chip = pool[index]
	if chip.get_parent() != container:
		var previous_parent: Node = chip.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(chip)
		container.add_child(chip)
	container.move_child(chip, index)
	return chip

func _apply_status_chip(chip: PanelContainer, status_token: String, theme: Dictionary, align_right: bool) -> void:
	var accent := Color(theme.get("accent", Color.WHITE))
	var fill := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).darkened(0.08)
	_apply_panel_style(chip, fill, accent.lerp(fill, 0.18))
	var icon: Control = chip.get_meta("status_icon", null)
	var label: Label = chip.get_meta("status_label", null)
	if icon != null:
		icon.custom_minimum_size = Vector2(22, 22)
		icon.icon_kind = _status_icon_kind_from_token(status_token)
		if icon.has_method("set_palette"):
			icon.set_palette(accent, Color(theme.get("text", Color.WHITE)))
	if label != null:
		label.text = status_token
		label.add_theme_color_override("font_color", Color(theme.get("text", Color.WHITE)))
	var margin := chip.get_child(0) if chip.get_child_count() > 0 else null
	var row := margin.get_child(0) if margin != null and margin.get_child_count() > 0 else null
	if row is HBoxContainer:
		row.alignment = BoxContainer.ALIGNMENT_END if align_right else BoxContainer.ALIGNMENT_BEGIN

func _format_recent_match_events(events: Array) -> String:
	if events.is_empty():
		return "Recent events will stack here once the point opens."
	var lines := PackedStringArray()
	for index in range(events.size() - 1, -1, -1):
		var event := Dictionary(events[index])
		var line := _describe_recent_event(event)
		if line == "":
			continue
		lines.append("• " + line)
		if lines.size() >= 3:
			break
	if lines.is_empty():
		return "Recent events will stack here once the point opens."
	return "\n".join(lines)

func _describe_recent_event(event: Dictionary) -> String:
	var kind := String(event.get("kind", ""))
	var payload := Dictionary(event.get("payload", {}))
	var side := String(event.get("side", ""))
	match kind:
		"card_played":
			return "%s: %s" % [_event_side_label(side), String(payload.get("name", "a card"))]
		"pressure_shifted":
			return "%s RP from %s" % [_signed_value(int(payload.get("amount", 0))), String(payload.get("source", "rally exchange"))]
		"point_started":
			return "Point %d • %s serves" % [int(event.get("point_number", 0)), String(payload.get("server", "player")).capitalize()]
		"point_resolved":
			return "%s won point • %s" % [String(payload.get("winner", "match")).capitalize(), String(payload.get("reason", "rally resolution"))]
		"game_won":
			return "%s took the game" % String(payload.get("winner", "match")).capitalize()
		"match_resolved":
			return "%s won the match" % String(payload.get("winner", "match")).capitalize()
		"potion_used":
			return "%s used %s" % [_event_side_label(side), String(payload.get("name", "a potion"))]
		"log":
			return String(payload.get("line", ""))
	return ""

func _event_side_label(side: String) -> String:
	if side == "":
		return "Match"
	return side.capitalize()

func _status_icon_kind_from_token(status_token: String) -> String:
	var prefix := status_token.get_slice(" ", 0)
	return String(STATUS_ICON_MAP.get(prefix, "ball"))

func _refresh_primary_action(has_saved_run: bool) -> void:
	if _front_screen_controller == null:
		return
	_front_screen_controller.refresh_primary_action(
		self,
		_run_state,
		_front_screen_mode,
		_get_selected_class(),
		has_saved_run,
		_front_screen_presenter
	)

func _configure_reveal_actions() -> void:
	if _front_screen_controller == null:
		return
	_front_screen_controller.configure_reveal_actions(self, _run_state, _front_screen_presenter)

func _refresh_launch_panel() -> void:
	if _front_screen_controller == null:
		return
	_front_screen_controller.refresh_launch_panel(
		self,
		_run_state,
		_front_screen_mode,
		_get_selected_class(),
		_has_saved_run(),
		_front_screen_presenter
	)

func _refresh_equipment_badges(active_match) -> void:
	if equipment_row == null:
		return
	if active_match == null:
		equipment_row.visible = false
		stage_equipment_row.visible = false
		if is_instance_valid(_return_support_row):
			_return_support_row.visible = false
		if is_instance_valid(_stage_return_support_row):
			_stage_return_support_row.visible = false
		return

	var major_data: Dictionary = {} if _run_state.phase == "idle" else _run_state.get_major_data()
	var theme: Dictionary = _get_presentation_theme(major_data)
	var base_fill: Color = Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22)))
	var accent: Color = Color(theme.get("accent", Color.WHITE))
	var text_color: Color = Color(theme.get("text", Color.WHITE))
	var loadout: Dictionary = active_match.call("get_equipment_loadout")

	equipment_row.visible = true
	stage_equipment_row.visible = true
	_apply_equipment_badge(
		string_badge_panel,
		string_badge_tag_label,
		string_badge_name_label,
		string_badge_info_label,
		Dictionary(loadout.get("string", {})),
		base_fill,
		accent,
		text_color
	)
	_apply_equipment_badge(
		racquet_badge_panel,
		racquet_badge_tag_label,
		racquet_badge_name_label,
		racquet_badge_info_label,
		Dictionary(loadout.get("racquet", {})),
		base_fill,
		accent,
		text_color
	)
	_apply_equipment_badge(
		stage_string_badge_panel,
		stage_string_badge_tag_label,
		stage_string_badge_name_label,
		stage_string_badge_info_label,
		Dictionary(loadout.get("string", {})),
		base_fill,
		accent,
		text_color
	)
	stage_string_badge_info_label.text = _compact_stage_summary(stage_string_badge_info_label.text)
	_apply_equipment_badge(
		stage_racquet_badge_panel,
		stage_racquet_badge_tag_label,
		stage_racquet_badge_name_label,
		stage_racquet_badge_info_label,
		Dictionary(loadout.get("racquet", {})),
		base_fill,
		accent,
		text_color
	)
	stage_racquet_badge_info_label.text = _compact_stage_summary(stage_racquet_badge_info_label.text)
	_refresh_return_support_badges(active_match, theme)

func _apply_equipment_badge(panel: PanelContainer, tag_label: Label, name_label: Label, info_label: Label, badge_data: Dictionary, base_fill: Color, accent: Color, text_color: Color) -> void:
	var equipped := bool(badge_data.get("equipped", false))
	var fill_color := base_fill.lerp(accent, 0.12) if equipped else base_fill.darkened(0.18)
	var border_color := accent if equipped else text_color.lerp(base_fill, 0.45)
	var info_color := text_color if equipped else text_color.lerp(fill_color, 0.25)

	_apply_panel_style(panel, fill_color, border_color)
	panel.tooltip_text = String(badge_data.get("details", ""))
	tag_label.text = String(badge_data.get("slot", "EQUIP"))
	name_label.text = String(badge_data.get("name", "Empty Slot"))
	info_label.text = String(badge_data.get("summary", ""))
	tag_label.add_theme_color_override("font_color", accent if equipped else border_color)
	name_label.add_theme_color_override("font_color", text_color)
	info_label.add_theme_color_override("font_color", info_color)

func _refresh_return_support_badges(active_match, theme: Dictionary) -> void:
	_ensure_return_support_rows()
	if not is_instance_valid(_return_support_row) or not is_instance_valid(_stage_return_support_row):
		return
	var badges: Array = active_match.call("get_return_relic_badges")
	var has_badges := not badges.is_empty()
	_return_support_row.visible = has_badges
	_stage_return_support_row.visible = has_badges
	if not has_badges:
		return
	_clear_container(_return_support_row)
	_clear_container(_stage_return_support_row)
	for badge in badges:
		var badge_dict := Dictionary(badge)
		_return_support_row.add_child(_build_return_support_badge(badge_dict, theme, false))
		_stage_return_support_row.add_child(_build_return_support_badge(badge_dict, theme, true))

func _build_return_support_badge(badge_data: Dictionary, theme: Dictionary, compact: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 58 if compact else 74)
	var accent := Color(theme.get("accent", Color.WHITE))
	var fill := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22))).lerp(accent, 0.10)
	_apply_panel_style(panel, fill, accent.lerp(fill, 0.16))
	panel.tooltip_text = String(badge_data.get("details", ""))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10 if compact else 12)
	margin.add_theme_constant_override("margin_top", 8 if compact else 10)
	margin.add_theme_constant_override("margin_right", 10 if compact else 12)
	margin.add_theme_constant_override("margin_bottom", 8 if compact else 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	vbox.add_child(title_row)

	var icon: Control = BadgeIconScript.new()
	icon.custom_minimum_size = Vector2(18, 18)
	icon.icon_kind = String(badge_data.get("icon_kind", "ball"))
	icon.set_palette(accent, Color(theme.get("text", Color.WHITE)))
	title_row.add_child(icon)

	var tag_label := Label.new()
	tag_label.text = String(badge_data.get("slot", "RETURN RELIC"))
	tag_label.add_theme_color_override("font_color", accent)
	tag_label.add_theme_font_size_override("font_size", 10 if compact else 11)
	title_row.add_child(tag_label)

	var name_label := Label.new()
	name_label.text = String(badge_data.get("name", "Return Support"))
	name_label.add_theme_color_override("font_color", Color(theme.get("text", Color.WHITE)))
	name_label.add_theme_font_size_override("font_size", 15 if compact else 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var summary_label := Label.new()
	var summary_text := String(badge_data.get("summary", ""))
	summary_label.text = _compact_stage_summary(summary_text) if compact else summary_text
	summary_label.add_theme_color_override("font_color", Color(theme.get("text", Color.WHITE)).lerp(fill, 0.18))
	summary_label.add_theme_font_size_override("font_size", 11 if compact else 12)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(summary_label)
	return panel

func _build_hand_buttons() -> void:
	_build_hand_buttons_into(hand_buttons, false)

func _build_hand_buttons_into(target_container: HBoxContainer, is_stage: bool = false) -> void:
	var hand_display: Array = _run_state.active_match.call("get_hand_slot_display")
	if hand_display.is_empty():
		_hide_pooled_controls(_stage_hand_button_pool if is_stage else _hand_button_pool)
		return
	var separation := _stage_hand_overlap_separation() if is_stage else 12
	target_container.add_theme_constant_override("separation", separation)
	var pool: Array = _stage_hand_button_pool if is_stage else _hand_button_pool
	var size_override := Vector2.ZERO
	if is_stage:
		size_override = _stage_card_size_override(hand_display.size(), separation)
		var content_width := _stage_hand_content_width()
		target_container.custom_minimum_size = Vector2(content_width, 0) if content_width > 0.0 else Vector2.ZERO
	else:
		target_container.custom_minimum_size = Vector2.ZERO

	for index in range(hand_display.size()):
		var card: Dictionary = hand_display[index]
		var button = _get_pooled_hand_button(target_container, pool, index)
		button.set_tile_payload(card, {
			"mode": "stage_card" if is_stage else "card",
			"large": is_stage,
			"compact_level": _current_combat_compact_level() if is_stage else 0,
			"theme": _get_presentation_theme({} if _run_state.phase == "idle" else _run_state.get_major_data()),
			"size_override": size_override,
		})
		var hand_index := int(card.get("hand_index", -1))
		button.set_meta("hand_index", hand_index)
		button.visible = true
		button.disabled = _run_state.active_match.state != "player_turn" or hand_index < 0 or not bool(card.get("playable", true))
		if is_stage:
			if button.has_method("clear_stage_hand_fan"):
				button.call("clear_stage_hand_fan")
		elif button.has_method("clear_stage_hand_fan"):
			button.call("clear_stage_hand_fan")
	for index in range(hand_display.size(), pool.size()):
		var extra = pool[index]
		if extra != null:
			extra.visible = false
			extra.disabled = true

func _get_pooled_hand_button(target_container: HBoxContainer, pool: Array, index: int):
	while pool.size() <= index:
		var tile = CardFaceButtonScript.new()
		tile.pressed.connect(_on_pooled_hand_button_pressed.bind(tile))
		pool.append(tile)
		target_container.add_child(tile)
	var button = pool[index]
	if button.get_parent() != target_container:
		var previous_parent: Node = button.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(button)
		target_container.add_child(button)
	target_container.move_child(button, index)
	return button

func _hide_pooled_controls(pool: Array) -> void:
	for control in pool:
		if control == null:
			continue
		control.visible = false
		if control is BaseButton:
			control.disabled = true

func _on_pooled_hand_button_pressed(button) -> void:
	if button == null:
		return
	var hand_index := int(button.get_meta("hand_index", -1))
	if hand_index < 0:
		return
	_on_hand_card_pressed(hand_index)

func _stage_hand_overlap_separation() -> int:
	match _current_combat_compact_level():
		0:
			return 8
		1:
			return 6
		2:
			return 4
		_:
			return 4

func _stage_hand_content_width() -> float:
	if is_instance_valid(stage_hand_scroll) and stage_hand_scroll.size.x > 0.0:
		return maxf(0.0, stage_hand_scroll.size.x - 8.0)
	if is_instance_valid(stage_hand_panel) and stage_hand_panel.size.x > 0.0:
		return maxf(0.0, stage_hand_panel.size.x - 28.0)
	return 0.0

func _stage_hand_content_height() -> float:
	if is_instance_valid(stage_hand_scroll) and stage_hand_scroll.size.y > 0.0:
		return maxf(0.0, stage_hand_scroll.size.y - 8.0)
	if is_instance_valid(stage_hand_scroll) and stage_hand_scroll.custom_minimum_size.y > 0.0:
		return maxf(0.0, stage_hand_scroll.custom_minimum_size.y - 8.0)
	return 0.0

func _stage_card_size_override(card_count: int, separation: int) -> Vector2:
	if card_count <= 0:
		return Vector2.ZERO
	var available_width := _stage_hand_content_width()
	var available_height := _stage_hand_content_height()
	if available_width <= 0.0 or available_height <= 0.0:
		return Vector2.ZERO
	var total_gap := float(maxi(0, card_count - 1) * separation)
	var width_by_row: float = floor((available_width - total_gap) / float(card_count))
	var target_height: float = clampf(available_height - 6.0, 184.0, 248.0)
	var width_by_height: float = floor(target_height / 1.42)
	var slot_width: float = minf(width_by_row, width_by_height)
	if slot_width <= 0.0:
		return Vector2.ZERO
	var width: float = clampf(slot_width, 126.0, 188.0)
	var height: float = mini(target_height, clampf(width * 1.42, 184.0, 248.0))
	return Vector2(width, height)

func _build_route_buttons() -> void:
	var accessible_nodes: PackedInt32Array = _run_state.accessible_node_ids
	if accessible_nodes.is_empty():
		_add_placeholder(hand_buttons, "No routes are currently available.")
		return

	for node_id in accessible_nodes:
		var summary := String(_run_state.get_node_summary(int(node_id)))
		var node = _run_state.get_node(int(node_id))
		var node_label := "Next Route"
		var round_name := "Next Round"
		if node != null:
			var node_type := String(node.node_type).capitalize()
			round_name = String(_run_state.get_round_name(int(node.floor)))
			node_label = "%s\n%s" % [round_name, node_type]
			if String(node.node_type) == "regular":
				node_label = "%s\nPlay Opening Match" % round_name if int(node.floor) == 0 else "%s\nPlay Match" % round_name
			elif String(node.node_type) == "elite":
				node_label = "%s\nPlay Elite" % round_name
			elif String(node.node_type) == "boss":
				node_label = "%s\nPlay Final" % round_name
			elif String(node.node_type) == "shop":
				node_label = "%s\nVisit Shop" % round_name
			elif String(node.node_type) == "rest":
				node_label = "%s\nRecover" % round_name
			elif String(node.node_type) == "event":
				node_label = "%s\nTake Event" % round_name
			elif String(node.node_type) == "treasure":
				node_label = "%s\nOpen Cache" % round_name
		var button = _make_asset_tile({
			"title": node_label.get_slice("\n", 0),
			"description": summary,
			"footer_text": "Click to enter this bracket branch.",
			"node_type": String(node.node_type) if node != null else "regular",
			"round_label": _compact_round_label(round_name),
			"seed_text": _compact_round_label(round_name),
		}, "route")
		button.pressed.connect(_on_map_node_selected.bind(int(node_id)))
		hand_buttons.add_child(button)

func _make_asset_tile(payload: Dictionary, mode: String, large: bool = false):
	var tile = CardFaceButtonScript.new()
	var major_data: Dictionary = {} if _run_state.phase == "idle" else _run_state.get_major_data()
	var compact_level := 0
	if mode == "stage_card":
		compact_level = _current_combat_compact_level()
	tile.set_tile_payload(payload, {
		"mode": mode,
		"large": large,
		"compact_level": compact_level,
		"theme": _get_presentation_theme(major_data),
	})
	return tile

func _compact_round_label(round_name: String) -> String:
	if round_name.find("Qualifying") >= 0:
		return "Q"
	if round_name.find("Opening") >= 0:
		return "R1"
	if round_name.find("32") >= 0:
		return "R32"
	if round_name.find("16") >= 0:
		return "R16"
	if round_name.find("Quarter") >= 0:
		return "QF"
	if round_name.find("Semifinal") >= 0:
		return "SF"
	if round_name.find("Final") >= 0:
		return "F"
	return round_name.left(3).to_upper()

func _build_stage_hud_body(actor_data: Dictionary) -> String:
	var status_summary := "Stable"
	var status_value = actor_data.get("statuses", PackedStringArray())
	if typeof(status_value) == TYPE_PACKED_STRING_ARRAY and not PackedStringArray(status_value).is_empty():
		status_summary = PackedStringArray(status_value)[0]
	elif status_value is Array and not Array(status_value).is_empty():
		status_summary = String(Array(status_value)[0])
	var summary := PackedStringArray([
		"C%d" % int(actor_data.get("condition", 0)),
		"S%d" % int(actor_data.get("stamina", 0)),
		"G%d" % int(actor_data.get("guard", 0)),
		_compact_court_position(String(actor_data.get("position", "Baseline"))),
	])
	if status_summary != "Stable":
		summary.append(_compact_actor_title(status_summary, 10))
	return " • ".join(summary)

func _build_stage_actor_body(actor_data: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append("Court %s • Guard %d" % [
		String(actor_data.get("position", "Baseline")),
		int(actor_data.get("guard", 0)),
	])
	var status_summary := "Stable"
	var statuses := PackedStringArray()
	var status_value = actor_data.get("statuses", PackedStringArray())
	if typeof(status_value) == TYPE_PACKED_STRING_ARRAY:
		statuses = status_value
	elif status_value is Array:
		for entry in status_value:
			statuses.append(String(entry))
	if not statuses.is_empty():
		status_summary = _join_strings(statuses)
	lines.append(status_summary)
	return "\n".join(lines)

func _compact_actor_title(name: String, max_length: int) -> String:
	if name.length() <= max_length:
		return name
	return name.substr(0, max_length - 3).rstrip(" ") + "..."

func _compact_court_position(position: String) -> String:
	match position.to_lower():
		"baseline":
			return "Base"
		"serviceline":
			return "Mid"
		"net":
			return "Net"
		_:
			return position.left(4)

func _signed_value(value: int) -> String:
	return "%+d" % value

func _build_reward_tile_spec(reward: Dictionary) -> Dictionary:
	var reward_type := String(reward.get("reward_type", "card"))
	var tile_payload: Dictionary = reward.duplicate(true)
	var tile_mode := "relic_reward" if reward_type == "relic" else "reward_card"
	match reward_type:
		"shop_card":
			tile_payload["display_type"] = "BUY"
			tile_payload["display_art"] = "Card Market"
			tile_payload["display_icon"] = "ball"
			tile_payload["display_footer"] = String(reward.get("footer_text", "Costs %d BTC" % int(reward.get("price_btc", 0))))
			tile_payload["tooltip_text"] = "Buy this card for bitcoin."
		"shop_remove":
			tile_payload["display_title"] = String(reward.get("name", "Deck Purge Service"))
			tile_payload["display_description"] = String(reward.get("description", "Pay to remove one card from the deck."))
			tile_payload["display_type"] = "CUT"
			tile_payload["display_art"] = "Deck Surgeon"
			tile_payload["display_icon"] = "focus"
			tile_payload["display_footer"] = String(reward.get("footer_text", ""))
			tile_payload["tooltip_text"] = "Pay for a deck-thinning service, then choose exactly which card to cut."
		"card_upgrade":
			tile_payload["display_title"] = String(reward.get("name", "Card Upgrade"))
			tile_payload["display_description"] = String(reward.get("description", "Upgrade one card in the deck."))
			tile_payload["display_type"] = "UPGRADE"
			tile_payload["display_art"] = "Card Lab"
			tile_payload["display_icon"] = "pressure"
			tile_payload["display_footer"] = String(reward.get("footer_text", ""))
		"reward_upgrade":
			tile_payload["display_title"] = String(reward.get("name", "Card Upgrade"))
			tile_payload["display_description"] = String(reward.get("description", "Upgrade one card in the deck."))
			tile_payload["display_type"] = "PLUS"
			tile_payload["display_art"] = "Card Lab"
			tile_payload["display_icon"] = "pressure"
			tile_payload["display_footer"] = String(reward.get("footer_text", ""))
		"deck_trim":
			tile_payload["display_title"] = "Cut %s" % String(reward.get("name", "Card"))
			tile_payload["display_description"] = String(reward.get("description", "Remove one card from the deck."))
			tile_payload["display_type"] = "CUT"
			tile_payload["display_art"] = "Deck Trim"
			tile_payload["display_icon"] = "focus"
			tile_payload["display_footer"] = String(reward.get("footer_text", ""))
		"racquet_upgrade":
			tile_payload["display_title"] = String(reward.get("name", "Racquet Tune"))
			tile_payload["display_description"] = String(reward.get("description", "Upgrade racquet tuning for the run."))
			tile_payload["display_type"] = "TUNE"
			tile_payload["display_art"] = "Frame Bench"
			tile_payload["display_icon"] = "frame"
			tile_payload["display_footer"] = String(reward.get("footer_text", ""))
		"rest_heal", "rest_endurance", "rest_focus":
			tile_payload["display_title"] = String(reward.get("name", "Checkpoint Action"))
			tile_payload["display_description"] = String(reward.get("description", "Recover before the next round."))
			tile_payload["display_type"] = String(reward.get("display_type", "REST"))
			tile_payload["display_art"] = String(reward.get("display_art", "Recovery Check"))
			tile_payload["display_icon"] = String(reward.get("display_icon", "focus"))
			tile_payload["display_footer"] = String(reward.get("footer_text", "Free action"))
	return {
		"payload": tile_payload,
		"mode": tile_mode,
	}

func _refresh_reward_checkpoint_panel(major_data: Dictionary) -> void:
	if _checkpoint_screen_controller == null:
		return
	_checkpoint_screen_controller.refresh_reward_panel(
		self,
		_run_state,
		major_data,
		_checkpoint_pane_presenter,
		RunStateScript.MAX_POTIONS
	)


func _refresh_reward_buttons() -> void:
	if _checkpoint_screen_controller == null:
		return
	_checkpoint_screen_controller.refresh_reward_buttons(self, _run_state)

func _refresh_shop_offer_sections(potion_offers: Array, relic_offers: Array, theme: Dictionary) -> void:
	if _checkpoint_screen_controller == null:
		return
	_checkpoint_screen_controller.refresh_shop_offer_sections(self, _run_state, potion_offers, relic_offers, theme)

func _refresh_shop_checkpoint_panel(major_data: Dictionary) -> void:
	if _checkpoint_screen_controller == null:
		return
	_checkpoint_screen_controller.refresh_shop_panel(
		self,
		_run_state,
		major_data,
		_checkpoint_pane_presenter,
		RunStateScript.MAX_POTIONS
	)

func _build_shop_offer_payload(reward: Dictionary) -> Dictionary:
	var payload := reward.duplicate(true)
	var reward_type := String(reward.get("reward_type", ""))
	match reward_type:
		"shop_potion":
			payload["display_title"] = String(reward.get("name", "Potion"))
			payload["display_description"] = String(reward.get("description", "Use during a tough match swing."))
			payload["display_type"] = "POTION"
			payload["display_art"] = String(reward.get("display_art", "Bench Cooler"))
			payload["display_icon"] = _icon_for_potion_offer_name(String(reward.get("name", "")))
			payload["display_footer"] = String(reward.get("footer_text", "Costs %d BTC" % int(reward.get("price_btc", 0))))
			payload["tooltip_text"] = "Consumable. Best saved for boss matches or rough swing turns."
		"shop_relic":
			payload["display_footer"] = String(reward.get("footer_text", "Costs %d BTC" % int(reward.get("price_btc", 0))))
			payload["tooltip_text"] = "%s [%s]" % [String(reward.get("name", "Relic")), String(reward.get("rarity", "common")).capitalize()]
	return payload

func _icon_for_potion_offer_name(potion_name: String) -> String:
	var lowered := potion_name.to_lower()
	if lowered.find("stamina") >= 0 or lowered.find("gel") >= 0:
		return "stamina_potion"
	if lowered.find("spin") >= 0:
		return "spin_potion"
	if lowered.find("focus") >= 0:
		return "focus_potion"
	if lowered.find("clutch") >= 0:
		return "clutch_potion"
	return "potion"

func _find_reward_choice_index(target_reward: Dictionary) -> int:
	var reward_choices: Array = _run_state.get_reward_choices()
	for index in range(reward_choices.size()):
		var reward: Dictionary = reward_choices[index]
		if String(reward.get("reward_type", "")) != String(target_reward.get("reward_type", "")):
			continue
		if reward.has("potion_id") and String(reward.get("potion_id", "")) == String(target_reward.get("potion_id", "")):
			return index
		if reward.has("relic_id") and String(reward.get("relic_id", "")) == String(target_reward.get("relic_id", "")):
			return index
		if reward.has("card_id") and String(reward.get("card_id", "")) == String(target_reward.get("card_id", "")):
			return index
		if String(reward.get("name", "")) == String(target_reward.get("name", "")):
			return index
		if not reward.has("card_id") and not reward.has("potion_id") and not reward.has("relic_id"):
			return index
	return -1

func _refresh_potion_rows(major_data: Dictionary) -> void:
	if _combat_screen_controller == null:
		return
	_combat_screen_controller.refresh_potion_rows(self, _run_state, major_data)

func _build_potion_action_button(potion_entry: Dictionary, accent: Color, text_color: Color, large: bool) -> Button:
	var button := Button.new()
	button.text = String(potion_entry.get("name", "Potion"))
	button.tooltip_text = String(potion_entry.get("description", ""))
	button.custom_minimum_size = Vector2(180, 52 if large else 44)
	button.disabled = not bool(potion_entry.get("usable", true))
	_apply_button_style(button, accent.lightened(0.06), accent.darkened(0.24), Color(0.08, 0.10, 0.12))
	button.add_theme_font_size_override("font_size", 14 if large else 13)
	button.add_theme_color_override("font_color_disabled", text_color.lerp(Color(0.2, 0.24, 0.28), 0.5))
	return button

func _sync_potion_buttons(target_container: HBoxContainer, pool: Array, potions: Array, accent: Color, text_color: Color, large: bool) -> void:
	for index in range(potions.size()):
		var potion_entry := Dictionary(potions[index])
		var button = _get_pooled_potion_button(target_container, pool, index)
		button.text = String(potion_entry.get("name", "Potion"))
		button.tooltip_text = String(potion_entry.get("description", ""))
		button.custom_minimum_size = Vector2(180, 52 if large else 44)
		button.disabled = not bool(potion_entry.get("usable", true))
		button.visible = true
		button.set_meta("inventory_index", int(potion_entry.get("inventory_index", -1)))
		_apply_button_style(button, accent.lightened(0.06), accent.darkened(0.24), Color(0.08, 0.10, 0.12))
		button.add_theme_font_size_override("font_size", 14 if large else 13)
		button.add_theme_color_override("font_color_disabled", text_color.lerp(Color(0.2, 0.24, 0.28), 0.5))
	for index in range(potions.size(), pool.size()):
		var extra = pool[index]
		if extra != null:
			extra.visible = false
			extra.disabled = true

func _get_pooled_potion_button(target_container: HBoxContainer, pool: Array, index: int) -> Button:
	while pool.size() <= index:
		var button := Button.new()
		button.pressed.connect(_on_pooled_potion_button_pressed.bind(button))
		pool.append(button)
		target_container.add_child(button)
	var button = pool[index]
	if button.get_parent() != target_container:
		var previous_parent: Node = button.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(button)
		target_container.add_child(button)
	target_container.move_child(button, index)
	return button

func _on_pooled_potion_button_pressed(button: Button) -> void:
	if button == null:
		return
	var potion_index := int(button.get_meta("inventory_index", -1))
	if potion_index < 0:
		return
	_on_potion_pressed(potion_index)

func _ensure_stage_perf_panel() -> void:
	if is_instance_valid(_stage_perf_panel) or stage_action_panel == null:
		return
	var parent := stage_end_turn_button.get_parent()
	if parent == null:
		return
	_stage_perf_panel = PanelContainer.new()
	_stage_perf_panel.name = "StagePerfPanel"
	_stage_perf_panel.visible = OS.is_debug_build()
	_stage_perf_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	_stage_perf_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_stage_perf_title_label = Label.new()
	_stage_perf_title_label.text = "Debug Perf"
	_stage_perf_title_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_stage_perf_title_label)

	_stage_perf_body_label = Label.new()
	_stage_perf_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stage_perf_body_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_stage_perf_body_label)

	parent.add_child(_stage_perf_panel)

func _refresh_stage_perf_panel(theme: Dictionary, battle: Dictionary) -> void:
	if not is_instance_valid(_stage_perf_panel):
		return
	var should_show := combat_stage_panel.visible and OS.is_debug_build()
	_stage_perf_panel.visible = should_show
	if not should_show:
		_perf_turn_key = ""
		return
	var telemetry = _telemetry_service()
	var snapshot: Dictionary = {}
	if telemetry != null and telemetry.has_method("poll_perf_snapshot"):
		snapshot = telemetry.poll_perf_snapshot()
	else:
		snapshot = {
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"video_mem_used": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		}
	var turn_key := "%s:%s:%s" % [
		str(battle.get("point_number", 0)),
		str(battle.get("turn_number", 0)),
		str(battle.get("state", "")),
	]
	if turn_key != _perf_turn_key:
		_perf_turn_key = turn_key
		_perf_turn_object_baseline = float(snapshot.get("objects", 0.0))
		_perf_turn_vram_baseline = float(snapshot.get("video_mem_used", 0.0))
	var objects_now := float(snapshot.get("objects", 0.0))
	var draw_calls_now := float(snapshot.get("draw_calls", 0.0))
	var vram_now := float(snapshot.get("video_mem_used", 0.0))
	var fps_now := float(snapshot.get("fps", 0.0))
	var object_delta := int(round(objects_now - _perf_turn_object_baseline))
	var vram_delta_mb := (vram_now - _perf_turn_vram_baseline) / (1024.0 * 1024.0)
	var accent := Color(theme.get("accent", Color.WHITE))
	var text_color := Color(theme.get("text", Color.WHITE))
	var fill := Color(theme.get("panel_alt", Color(0.16, 0.20, 0.24))).darkened(0.10)
	_apply_panel_style(_stage_perf_panel, fill, accent)
	_stage_perf_title_label.add_theme_color_override("font_color", accent)
	_stage_perf_body_label.add_theme_color_override("font_color", text_color)
	_stage_perf_body_label.text = "FPS %.0f • Draw Calls %.0f\nObjects %.0f • Turn ΔObj %+d\nVRAM %.1f MB • Turn ΔVRAM %+0.2f MB" % [
		fps_now,
		draw_calls_now,
		objects_now,
		object_delta,
		vram_now / (1024.0 * 1024.0),
		vram_delta_mb,
	]

func _refresh_equipment_bonus_panel() -> void:
	if not is_instance_valid(_equipment_bonus_panel):
		return
	var summary := ""
	if _run_state.phase == "reward":
		summary = String(_run_state.get_pending_equipment_bonus_summary()).strip_edges()
	var reward_kind := _current_reward_menu_kind()
	var should_show := summary != "" and reward_kind != "rest"
	_equipment_bonus_panel.visible = should_show
	if not should_show:
		return
	_equipment_bonus_title_label.text = "Equipment Payout"
	_equipment_bonus_body_label.text = summary

func _ensure_equipment_bonus_panel() -> void:
	if is_instance_valid(_equipment_bonus_panel) or reward_scroll == null:
		return
	var parent := reward_scroll.get_parent()
	if parent == null:
		return

	_equipment_bonus_panel = PanelContainer.new()
	_equipment_bonus_panel.name = "EquipmentBonusPanel"
	_equipment_bonus_panel.visible = false
	_equipment_bonus_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equipment_bonus_panel.custom_minimum_size = Vector2(0, 86)

	var margin := MarginContainer.new()
	margin.name = "EquipmentBonusMargin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_equipment_bonus_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "EquipmentBonusVBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	_equipment_bonus_title_label = Label.new()
	_equipment_bonus_title_label.name = "EquipmentBonusTitle"
	_equipment_bonus_title_label.text = "Equipment Payout"
	_equipment_bonus_title_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_equipment_bonus_title_label)

	_equipment_bonus_body_label = Label.new()
	_equipment_bonus_body_label.name = "EquipmentBonusBody"
	_equipment_bonus_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equipment_bonus_body_label.text = ""
	vbox.add_child(_equipment_bonus_body_label)

	parent.add_child(_equipment_bonus_panel)
	parent.move_child(_equipment_bonus_panel, reward_scroll.get_index())

func _ensure_shop_offer_sections() -> void:
	if is_instance_valid(_shop_potion_panel) or not is_instance_valid(_shop_checkpoint_panel):
		return
	var body := _shop_checkpoint_panel.get_node_or_null("ShopCheckpointMargin/ShopCheckpointVBox/ShopInfoRow")
	if body == null:
		return
	var potion_section := _build_shop_section_panel("ShopPotionPanel", "Potion Bench")
	_shop_potion_panel = potion_section["panel"]
	_shop_potion_title_label = potion_section["title"]
	_shop_potion_buttons = potion_section["buttons"]
	body.add_child(_shop_potion_panel)

	var relic_section := _build_shop_section_panel("ShopRelicPanel", "Relic Cabinet")
	_shop_relic_panel = relic_section["panel"]
	_shop_relic_title_label = relic_section["title"]
	_shop_relic_buttons = relic_section["buttons"]
	body.add_child(_shop_relic_panel)

func _build_shop_section_panel(panel_name: String, title_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.visible = false
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)
	var title_icon := BadgeIconScript.new()
	title_icon.custom_minimum_size = Vector2(28, 28)
	title_icon.set("icon_kind", "potion" if title_text.find("Potion") >= 0 else "trophy")
	title_row.add_child(title_icon)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title_row.add_child(title)
	var buttons := HFlowContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("h_separation", 12)
	buttons.add_theme_constant_override("v_separation", 12)
	vbox.add_child(buttons)
	return {
		"panel": panel,
		"title": title,
		"buttons": buttons,
	}

func _ensure_path_select_panel() -> void:
	if is_instance_valid(_path_select_panel) or root_vbox == null:
		return

	_path_select_panel = PanelContainer.new()
	_path_select_panel.name = "PathSelectPanel"
	_path_select_panel.visible = false
	_path_select_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_select_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "PathSelectMargin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_path_select_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "PathSelectVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_path_select_header_panel = _build_checkpoint_header_panel("PathSelectHeaderPanel")
	_path_select_header_art = _path_select_header_panel.get_node("HeaderMargin/HeaderRow/CheckpointHeaderArt")
	vbox.add_child(_path_select_header_panel)

	var top_row := HBoxContainer.new()
	top_row.name = "PathSelectTopRow"
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 14)
	vbox.add_child(top_row)

	_path_select_prompt_panel = PanelContainer.new()
	_path_select_prompt_panel.name = "PathSelectPromptPanel"
	_path_select_prompt_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_path_select_prompt_panel)

	var prompt_margin := MarginContainer.new()
	prompt_margin.name = "PathSelectPromptMargin"
	prompt_margin.add_theme_constant_override("margin_left", 20)
	prompt_margin.add_theme_constant_override("margin_top", 18)
	prompt_margin.add_theme_constant_override("margin_right", 20)
	prompt_margin.add_theme_constant_override("margin_bottom", 18)
	_path_select_prompt_panel.add_child(prompt_margin)

	var prompt_vbox := VBoxContainer.new()
	prompt_vbox.name = "PathSelectPromptVBox"
	prompt_vbox.add_theme_constant_override("separation", 6)
	prompt_margin.add_child(prompt_vbox)

	_path_select_eyebrow_label = Label.new()
	_path_select_eyebrow_label.name = "PathSelectEyebrow"
	_path_select_eyebrow_label.add_theme_font_size_override("font_size", 15)
	prompt_vbox.add_child(_path_select_eyebrow_label)

	_path_select_question_label = Label.new()
	_path_select_question_label.name = "PathSelectQuestion"
	_path_select_question_label.add_theme_font_size_override("font_size", 30)
	_path_select_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_vbox.add_child(_path_select_question_label)

	_path_select_summary_label = Label.new()
	_path_select_summary_label.name = "PathSelectSummary"
	_path_select_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_path_select_summary_label.add_theme_font_size_override("font_size", 15)
	prompt_vbox.add_child(_path_select_summary_label)

	_path_select_info_panel = PanelContainer.new()
	_path_select_info_panel.name = "PathSelectInfoPanel"
	_path_select_info_panel.custom_minimum_size = Vector2(320, 0)
	top_row.add_child(_path_select_info_panel)

	var info_margin := MarginContainer.new()
	info_margin.name = "PathSelectInfoMargin"
	info_margin.add_theme_constant_override("margin_left", 14)
	info_margin.add_theme_constant_override("margin_top", 12)
	info_margin.add_theme_constant_override("margin_right", 14)
	info_margin.add_theme_constant_override("margin_bottom", 12)
	_path_select_info_panel.add_child(info_margin)

	var info_vbox := VBoxContainer.new()
	info_vbox.name = "PathSelectInfoVBox"
	info_vbox.add_theme_constant_override("separation", 6)
	info_margin.add_child(info_vbox)

	_path_select_info_title_label = Label.new()
	_path_select_info_title_label.name = "PathSelectInfoTitle"
	_path_select_info_title_label.add_theme_font_size_override("font_size", 20)
	info_vbox.add_child(_path_select_info_title_label)

	_path_select_info_body_label = Label.new()
	_path_select_info_body_label.name = "PathSelectInfoBody"
	_path_select_info_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_path_select_info_body_label.add_theme_font_size_override("font_size", 15)
	info_vbox.add_child(_path_select_info_body_label)

	_path_select_map_panel = PanelContainer.new()
	_path_select_map_panel.name = "PathSelectMapPanel"
	_path_select_map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_select_map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_path_select_map_panel)

	var map_margin := MarginContainer.new()
	map_margin.name = "PathSelectMapMargin"
	map_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_margin.add_theme_constant_override("margin_left", 14)
	map_margin.add_theme_constant_override("margin_top", 12)
	map_margin.add_theme_constant_override("margin_right", 14)
	map_margin.add_theme_constant_override("margin_bottom", 12)
	_path_select_map_panel.add_child(map_margin)

	var map_vbox := VBoxContainer.new()
	map_vbox.name = "PathSelectMapVBox"
	map_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_vbox.add_theme_constant_override("separation", 10)
	map_margin.add_child(map_vbox)

	_path_select_map_title_label = Label.new()
	_path_select_map_title_label.name = "PathSelectMapTitle"
	_path_select_map_title_label.add_theme_font_size_override("font_size", 22)
	map_vbox.add_child(_path_select_map_title_label)

	_path_select_map_view = MapView.new()
	_path_select_map_view.name = "PathSelectMapView"
	_path_select_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_select_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_path_select_map_view.custom_minimum_size = Vector2(0, 420)
	_path_select_map_view.node_selected.connect(_on_map_node_selected)
	_path_select_map_view.node_hovered.connect(_on_path_select_node_hovered)
	_path_select_map_view.node_hover_cleared.connect(_on_path_select_node_hover_cleared)
	map_vbox.add_child(_path_select_map_view)

	_path_select_node_info_label = Label.new()
	_path_select_node_info_label.name = "PathSelectNodeInfo"
	_path_select_node_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_path_select_node_info_label.add_theme_font_size_override("font_size", 15)
	map_vbox.add_child(_path_select_node_info_label)

	_path_select_hint_label = Label.new()
	_path_select_hint_label.name = "PathSelectHint"
	_path_select_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_path_select_hint_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_path_select_hint_label)

	root_vbox.add_child(_path_select_panel)
	var top_bar_index := root_vbox.get_children().find(top_bar)
	if top_bar_index >= 0:
		root_vbox.move_child(_path_select_panel, top_bar_index)

func _ensure_shop_checkpoint_panel() -> void:
	if is_instance_valid(_shop_checkpoint_panel) or root_vbox == null:
		return

	_shop_checkpoint_panel = PanelContainer.new()
	_shop_checkpoint_panel.name = "ShopCheckpointPanel"
	_shop_checkpoint_panel.visible = false
	_shop_checkpoint_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_checkpoint_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "ShopCheckpointMargin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_shop_checkpoint_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "ShopCheckpointVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_shop_header_panel = _build_checkpoint_header_panel("ShopHeaderPanel")
	_shop_header_art = _shop_header_panel.get_node("HeaderMargin/HeaderRow/CheckpointHeaderArt")
	_shop_header_leave_button = _shop_header_panel.get_node("HeaderMargin/HeaderRow/HeaderActionButton")
	_shop_header_leave_button.pressed.connect(_on_skip_reward_pressed)
	vbox.add_child(_shop_header_panel)

	_shop_prompt_panel = PanelContainer.new()
	_shop_prompt_panel.name = "ShopPromptPanel"
	_shop_prompt_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_shop_prompt_panel)

	var prompt_margin := MarginContainer.new()
	prompt_margin.name = "ShopPromptMargin"
	prompt_margin.add_theme_constant_override("margin_left", 20)
	prompt_margin.add_theme_constant_override("margin_top", 18)
	prompt_margin.add_theme_constant_override("margin_right", 20)
	prompt_margin.add_theme_constant_override("margin_bottom", 18)
	_shop_prompt_panel.add_child(prompt_margin)

	var prompt_vbox := VBoxContainer.new()
	prompt_vbox.name = "ShopPromptVBox"
	prompt_vbox.add_theme_constant_override("separation", 6)
	prompt_margin.add_child(prompt_vbox)

	_shop_prompt_action_row = HBoxContainer.new()
	_shop_prompt_action_row.name = "ShopPromptActionRow"
	_shop_prompt_action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_prompt_action_row.alignment = BoxContainer.ALIGNMENT_END
	prompt_vbox.add_child(_shop_prompt_action_row)

	_shop_leave_button_top = Button.new()
	_shop_leave_button_top.name = "ShopLeaveButtonTop"
	_shop_leave_button_top.custom_minimum_size = Vector2(220, 46)
	_shop_leave_button_top.text = "Back to Route"
	_shop_leave_button_top.pressed.connect(_on_skip_reward_pressed)
	_shop_prompt_action_row.add_child(_shop_leave_button_top)

	_shop_eyebrow_label = Label.new()
	_shop_eyebrow_label.name = "ShopEyebrow"
	_shop_eyebrow_label.add_theme_font_size_override("font_size", 15)
	prompt_vbox.add_child(_shop_eyebrow_label)

	_shop_question_label = Label.new()
	_shop_question_label.name = "ShopQuestion"
	_shop_question_label.add_theme_font_size_override("font_size", 30)
	_shop_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_vbox.add_child(_shop_question_label)

	_shop_summary_label = Label.new()
	_shop_summary_label.name = "ShopSummary"
	_shop_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_summary_label.add_theme_font_size_override("font_size", 15)
	prompt_vbox.add_child(_shop_summary_label)

	var info_row := HBoxContainer.new()
	info_row.name = "ShopInfoRow"
	info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_theme_constant_override("separation", 14)
	vbox.add_child(info_row)

	_shop_ledger_panel = PanelContainer.new()
	_shop_ledger_panel.name = "ShopLedgerPanel"
	_shop_ledger_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_shop_ledger_panel)

	var ledger_margin := MarginContainer.new()
	ledger_margin.name = "ShopLedgerMargin"
	ledger_margin.add_theme_constant_override("margin_left", 14)
	ledger_margin.add_theme_constant_override("margin_top", 12)
	ledger_margin.add_theme_constant_override("margin_right", 14)
	ledger_margin.add_theme_constant_override("margin_bottom", 12)
	_shop_ledger_panel.add_child(ledger_margin)

	var ledger_vbox := VBoxContainer.new()
	ledger_vbox.name = "ShopLedgerVBox"
	ledger_vbox.add_theme_constant_override("separation", 6)
	ledger_margin.add_child(ledger_vbox)

	_shop_ledger_title_label = Label.new()
	_shop_ledger_title_label.name = "ShopLedgerTitle"
	_shop_ledger_title_label.add_theme_font_size_override("font_size", 20)
	ledger_vbox.add_child(_shop_ledger_title_label)

	_shop_ledger_body_label = Label.new()
	_shop_ledger_body_label.name = "ShopLedgerBody"
	_shop_ledger_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_ledger_body_label.add_theme_font_size_override("font_size", 15)
	ledger_vbox.add_child(_shop_ledger_body_label)

	_shop_market_panel = PanelContainer.new()
	_shop_market_panel.name = "ShopMarketPanel"
	_shop_market_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_shop_market_panel)

	var market_margin := MarginContainer.new()
	market_margin.name = "ShopMarketMargin"
	market_margin.add_theme_constant_override("margin_left", 14)
	market_margin.add_theme_constant_override("margin_top", 12)
	market_margin.add_theme_constant_override("margin_right", 14)
	market_margin.add_theme_constant_override("margin_bottom", 12)
	_shop_market_panel.add_child(market_margin)

	var market_vbox := VBoxContainer.new()
	market_vbox.name = "ShopMarketVBox"
	market_vbox.add_theme_constant_override("separation", 8)
	market_margin.add_child(market_vbox)

	_shop_market_title_label = Label.new()
	_shop_market_title_label.name = "ShopMarketTitle"
	_shop_market_title_label.add_theme_font_size_override("font_size", 22)
	market_vbox.add_child(_shop_market_title_label)

	_shop_market_buttons = HFlowContainer.new()
	_shop_market_buttons.name = "ShopMarketButtons"
	_shop_market_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_market_buttons.add_theme_constant_override("h_separation", 12)
	_shop_market_buttons.add_theme_constant_override("v_separation", 12)
	market_vbox.add_child(_shop_market_buttons)

	_shop_hint_label = Label.new()
	_shop_hint_label.name = "ShopHint"
	_shop_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_hint_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_shop_hint_label)

	var action_row := HBoxContainer.new()
	action_row.name = "ShopActionRow"
	action_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(action_row)

	_shop_leave_button = Button.new()
	_shop_leave_button.name = "ShopLeaveButton"
	_shop_leave_button.custom_minimum_size = Vector2(200, 54)
	_shop_leave_button.text = "Leave Shop"
	_shop_leave_button.pressed.connect(_on_skip_reward_pressed)
	action_row.add_child(_shop_leave_button)

	root_vbox.add_child(_shop_checkpoint_panel)
	var top_bar_index := root_vbox.get_children().find(top_bar)
	if top_bar_index >= 0:
		root_vbox.move_child(_shop_checkpoint_panel, top_bar_index)

func _ensure_reward_checkpoint_panel() -> void:
	if is_instance_valid(_reward_checkpoint_panel) or root_vbox == null:
		return

	_reward_checkpoint_panel = PanelContainer.new()
	_reward_checkpoint_panel.name = "RewardCheckpointPanel"
	_reward_checkpoint_panel.visible = false
	_reward_checkpoint_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_checkpoint_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "RewardCheckpointMargin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_reward_checkpoint_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "RewardCheckpointVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_reward_header_panel = _build_checkpoint_header_panel("RewardHeaderPanel")
	_reward_header_art = _reward_header_panel.get_node("HeaderMargin/HeaderRow/CheckpointHeaderArt")
	vbox.add_child(_reward_header_panel)

	var top_row := HBoxContainer.new()
	top_row.name = "RewardTopRow"
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 14)
	vbox.add_child(top_row)

	_reward_prompt_panel = PanelContainer.new()
	_reward_prompt_panel.name = "RewardPromptPanel"
	_reward_prompt_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_reward_prompt_panel)

	var prompt_margin := MarginContainer.new()
	prompt_margin.name = "RewardPromptMargin"
	prompt_margin.add_theme_constant_override("margin_left", 20)
	prompt_margin.add_theme_constant_override("margin_top", 18)
	prompt_margin.add_theme_constant_override("margin_right", 20)
	prompt_margin.add_theme_constant_override("margin_bottom", 18)
	_reward_prompt_panel.add_child(prompt_margin)

	var prompt_vbox := VBoxContainer.new()
	prompt_vbox.name = "RewardPromptVBox"
	prompt_vbox.add_theme_constant_override("separation", 6)
	prompt_margin.add_child(prompt_vbox)

	_reward_eyebrow_label = Label.new()
	_reward_eyebrow_label.name = "RewardEyebrow"
	_reward_eyebrow_label.add_theme_font_size_override("font_size", 15)
	prompt_vbox.add_child(_reward_eyebrow_label)

	_reward_question_label = Label.new()
	_reward_question_label.name = "RewardQuestion"
	_reward_question_label.add_theme_font_size_override("font_size", 30)
	_reward_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_vbox.add_child(_reward_question_label)

	_reward_summary_label = Label.new()
	_reward_summary_label.name = "RewardSummary"
	_reward_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_summary_label.add_theme_font_size_override("font_size", 15)
	prompt_vbox.add_child(_reward_summary_label)

	_reward_ledger_panel = PanelContainer.new()
	_reward_ledger_panel.name = "RewardLedgerPanel"
	_reward_ledger_panel.custom_minimum_size = Vector2(290, 0)
	top_row.add_child(_reward_ledger_panel)

	var ledger_margin := MarginContainer.new()
	ledger_margin.name = "RewardLedgerMargin"
	ledger_margin.add_theme_constant_override("margin_left", 14)
	ledger_margin.add_theme_constant_override("margin_top", 12)
	ledger_margin.add_theme_constant_override("margin_right", 14)
	ledger_margin.add_theme_constant_override("margin_bottom", 12)
	_reward_ledger_panel.add_child(ledger_margin)

	var ledger_vbox := VBoxContainer.new()
	ledger_vbox.name = "RewardLedgerVBox"
	ledger_vbox.add_theme_constant_override("separation", 6)
	ledger_margin.add_child(ledger_vbox)

	_reward_ledger_title_label = Label.new()
	_reward_ledger_title_label.name = "RewardLedgerTitle"
	_reward_ledger_title_label.add_theme_font_size_override("font_size", 20)
	ledger_vbox.add_child(_reward_ledger_title_label)

	_reward_ledger_body_label = Label.new()
	_reward_ledger_body_label.name = "RewardLedgerBody"
	_reward_ledger_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_ledger_body_label.add_theme_font_size_override("font_size", 15)
	ledger_vbox.add_child(_reward_ledger_body_label)

	_reward_bonus_panel = PanelContainer.new()
	_reward_bonus_panel.name = "RewardBonusPanel"
	_reward_bonus_panel.visible = false
	_reward_bonus_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_reward_bonus_panel)

	var bonus_margin := MarginContainer.new()
	bonus_margin.name = "RewardBonusMargin"
	bonus_margin.add_theme_constant_override("margin_left", 14)
	bonus_margin.add_theme_constant_override("margin_top", 12)
	bonus_margin.add_theme_constant_override("margin_right", 14)
	bonus_margin.add_theme_constant_override("margin_bottom", 12)
	_reward_bonus_panel.add_child(bonus_margin)

	var bonus_vbox := VBoxContainer.new()
	bonus_vbox.name = "RewardBonusVBox"
	bonus_vbox.add_theme_constant_override("separation", 6)
	bonus_margin.add_child(bonus_vbox)

	_reward_bonus_title_label = Label.new()
	_reward_bonus_title_label.name = "RewardBonusTitle"
	_reward_bonus_title_label.add_theme_font_size_override("font_size", 20)
	bonus_vbox.add_child(_reward_bonus_title_label)

	_reward_bonus_body_label = Label.new()
	_reward_bonus_body_label.name = "RewardBonusBody"
	_reward_bonus_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_bonus_body_label.add_theme_font_size_override("font_size", 15)
	bonus_vbox.add_child(_reward_bonus_body_label)

	_reward_offer_panel = PanelContainer.new()
	_reward_offer_panel.name = "RewardOfferPanel"
	_reward_offer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_offer_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_reward_offer_panel)

	var offer_margin := MarginContainer.new()
	offer_margin.name = "RewardOfferMargin"
	offer_margin.add_theme_constant_override("margin_left", 14)
	offer_margin.add_theme_constant_override("margin_top", 12)
	offer_margin.add_theme_constant_override("margin_right", 14)
	offer_margin.add_theme_constant_override("margin_bottom", 12)
	_reward_offer_panel.add_child(offer_margin)

	var offer_vbox := VBoxContainer.new()
	offer_vbox.name = "RewardOfferVBox"
	offer_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offer_vbox.add_theme_constant_override("separation", 8)
	offer_margin.add_child(offer_vbox)

	_reward_offer_title_label = Label.new()
	_reward_offer_title_label.name = "RewardOfferTitle"
	_reward_offer_title_label.add_theme_font_size_override("font_size", 22)
	offer_vbox.add_child(_reward_offer_title_label)

	var offer_scroll := ScrollContainer.new()
	offer_scroll.name = "RewardOfferScroll"
	offer_scroll.custom_minimum_size = Vector2(0, 308)
	offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	offer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	offer_vbox.add_child(offer_scroll)

	_reward_offer_buttons = HBoxContainer.new()
	_reward_offer_buttons.name = "RewardOfferButtons"
	_reward_offer_buttons.add_theme_constant_override("separation", 14)
	offer_scroll.add_child(_reward_offer_buttons)

	_reward_hint_label = Label.new()
	_reward_hint_label.name = "RewardHint"
	_reward_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reward_hint_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_reward_hint_label)

	var action_row := HBoxContainer.new()
	action_row.name = "RewardActionRow"
	action_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(action_row)

	_reward_skip_button = Button.new()
	_reward_skip_button.name = "RewardSkipButton"
	_reward_skip_button.custom_minimum_size = Vector2(200, 54)
	_reward_skip_button.text = "Skip Reward"
	_reward_skip_button.pressed.connect(_on_skip_reward_pressed)
	action_row.add_child(_reward_skip_button)

	root_vbox.add_child(_reward_checkpoint_panel)
	var top_bar_index := root_vbox.get_children().find(top_bar)
	if top_bar_index >= 0:
		root_vbox.move_child(_reward_checkpoint_panel, top_bar_index)

func _ensure_rest_checkpoint_header() -> void:
	if is_instance_valid(_rest_header_panel) or rest_checkpoint_panel == null:
		return
	var rest_vbox := rest_checkpoint_panel.get_node_or_null("RestCheckpointMargin/RestCheckpointVBox")
	if rest_vbox == null:
		return
	_rest_header_panel = _build_checkpoint_header_panel("RestHeaderPanel")
	_rest_header_art = _rest_header_panel.get_node("HeaderMargin/HeaderRow/CheckpointHeaderArt")
	rest_vbox.add_child(_rest_header_panel)
	rest_vbox.move_child(_rest_header_panel, 0)

func _build_checkpoint_header_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, 152.0)
	var margin := MarginContainer.new()
	margin.name = "HeaderMargin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var art := CheckpointHeaderArtScript.new()
	art.name = "CheckpointHeaderArt"
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.custom_minimum_size = Vector2(0.0, 132.0)
	row.add_child(art)

	var action_button := Button.new()
	action_button.name = "HeaderActionButton"
	action_button.visible = false
	action_button.custom_minimum_size = Vector2(210.0, 48.0)
	row.add_child(action_button)
	return panel

func _refresh_checkpoint_header_art(header_art: Control, mode: String, title: String, subtitle: String, theme: Dictionary) -> void:
	if header_art != null and header_art.has_method("apply_header"):
		header_art.call("apply_header", theme, mode, title, subtitle)

func _ensure_return_support_rows() -> void:
	if equipment_row == null or stage_equipment_row == null:
		return
	if not is_instance_valid(_return_support_row):
		_return_support_row = HBoxContainer.new()
		_return_support_row.name = "ReturnSupportRow"
		_return_support_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_return_support_row.add_theme_constant_override("separation", 8)
		_return_support_row.visible = false
		var combat_parent := equipment_row.get_parent()
		combat_parent.add_child(_return_support_row)
		combat_parent.move_child(_return_support_row, equipment_row.get_index() + 1)
	if not is_instance_valid(_stage_return_support_row):
		_stage_return_support_row = HBoxContainer.new()
		_stage_return_support_row.name = "StageReturnSupportRow"
		_stage_return_support_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stage_return_support_row.add_theme_constant_override("separation", 8)
		_stage_return_support_row.visible = false
		var stage_parent := stage_equipment_row.get_parent()
		stage_parent.add_child(_stage_return_support_row)
		stage_parent.move_child(_stage_return_support_row, stage_equipment_row.get_index() + 1)

func _ensure_combat_potion_rows() -> void:
	if equipment_row == null or stage_equipment_row == null:
		return
	if not is_instance_valid(_combat_potion_panel):
		var combat_section := _build_potion_panel("CombatPotionPanel")
		_combat_potion_panel = combat_section["panel"]
		_combat_potion_title_label = combat_section["title"]
		_combat_potion_buttons = combat_section["buttons"]
		var combat_parent := equipment_row.get_parent()
		combat_parent.add_child(_combat_potion_panel)
		combat_parent.move_child(_combat_potion_panel, equipment_row.get_index() + 1)
	if not is_instance_valid(_stage_potion_panel):
		var stage_section := _build_potion_panel("StagePotionPanel")
		_stage_potion_panel = stage_section["panel"]
		_stage_potion_title_label = stage_section["title"]
		_stage_potion_buttons = stage_section["buttons"]
		var stage_parent := stage_equipment_row.get_parent()
		stage_parent.add_child(_stage_potion_panel)
		stage_parent.move_child(_stage_potion_panel, stage_equipment_row.get_index() + 1)

func _build_potion_panel(panel_name: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.visible = false
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Potions"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	var buttons := HBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 8)
	vbox.add_child(buttons)
	return {
		"panel": panel,
		"title": title,
		"buttons": buttons,
	}

func _refresh_log_panel() -> void:
	if _meta_sidebar_controller == null:
		return
	_meta_sidebar_controller.refresh_log_panel(self, _run_state, _ui_text_builder, _unlock_progression)

func _build_deck_mix_lines(deck_ids: Array) -> PackedStringArray:
	return _ui_text_builder.build_deck_mix_lines(deck_ids)

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _clear_container_preserving_pool(container: Node, pool: Array) -> void:
	for child in container.get_children():
		if pool.has(child):
			child.visible = false
			if child is BaseButton:
				child.disabled = true
			continue
		container.remove_child(child)
		child.queue_free()

func _add_placeholder(container: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(180, 72)
	container.add_child(label)

func _join_strings(values: PackedStringArray) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(String(value))
	return ", ".join(parts)

func _coerce_tags(value) -> PackedStringArray:
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		return value
	var tags := PackedStringArray()
	if value is Array:
		for entry in value:
			tags.append(String(entry))
	return tags

func _is_run_active() -> bool:
	return _run_state.phase in ["map", "combat", "reward"]

func _apply_major_presentation(major_data: Dictionary) -> void:
	if _main_theme_controller == null:
		return
	var major_name := String(major_data.get("name", "Default"))
	var theme_signature := "%s|%s|%s" % [major_name, String(_run_state.phase), str(_high_contrast_enabled())]
	if theme_signature == _last_theme_signature:
		return
	_last_theme_signature = theme_signature
	_main_theme_controller.apply_major_presentation(self, _run_state, major_data)

func _get_presentation_theme(major_data: Dictionary) -> Dictionary:
	var major_name := String(major_data.get("name", "Default"))
	if PRESENTATION_THEMES.has(major_name):
		return Dictionary(PRESENTATION_THEMES[major_name])
	return Dictionary(PRESENTATION_THEMES["Default"])

func _apply_panel_style(panel: PanelContainer, fill_color: Color, border_color: Color, options: Dictionary = {}) -> void:
	if panel == null:
		return
	var style: StyleBox = null
	if theme_manager != null and theme_manager.has_method("make_panel_style"):
		var merged_options := {
			"radius": 18,
			"shadow_alpha": 0.26,
			"border_width": 2,
		}
		for key in options.keys():
			merged_options[key] = options[key]
		style = theme_manager.call("make_panel_style", fill_color, border_color, merged_options)
	if style == null:
		style = _build_gloss_stylebox(fill_color, border_color, 18, 0.26, 2)
	panel.add_theme_stylebox_override("panel", style)

func _apply_button_style(button: Button, fill_color: Color, border_color: Color, text_color: Color, options: Dictionary = {}) -> void:
	if button == null:
		return
	var normal: StyleBox = null
	var hover: StyleBox = null
	var pressed: StyleBox = null
	var disabled: StyleBox = null
	if theme_manager != null and theme_manager.has_method("make_button_style"):
		var normal_data: Dictionary = theme_manager.call("make_button_style", fill_color, border_color, text_color, "normal", options)
		var hover_data: Dictionary = theme_manager.call("make_button_style", fill_color, border_color, text_color, "hover", options)
		var pressed_data: Dictionary = theme_manager.call("make_button_style", fill_color, border_color, text_color, "pressed", options)
		var disabled_data: Dictionary = theme_manager.call("make_button_style", fill_color, border_color, text_color, "disabled", options)
		normal = normal_data.get("style")
		hover = hover_data.get("style")
		pressed = pressed_data.get("style")
		disabled = disabled_data.get("style")
	if normal == null:
		normal = _build_gloss_stylebox(fill_color, border_color, 18, 0.30, 2)
	if hover == null:
		hover = _build_gloss_stylebox(fill_color.lightened(0.08), border_color.lightened(0.08), 18, 0.36, 2)
	if pressed == null:
		pressed = _build_gloss_stylebox(fill_color.darkened(0.10), border_color.darkened(0.04), 18, 0.18, 2)
	if disabled == null:
		disabled = _build_gloss_stylebox(fill_color.darkened(0.18), border_color.lerp(fill_color, 0.42), 18, 0.12, 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color.lightened(0.06))
	button.add_theme_color_override("font_pressed_color", text_color.darkened(0.04))
	button.add_theme_color_override("font_disabled_color", text_color.lerp(fill_color, 0.45))

func _build_gloss_stylebox(
	fill_color: Color,
	border_color: Color,
	radius: int = 18,
	shadow_alpha: float = 0.30,
	border_width: int = 2
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var shaded_fill := fill_color.darkened(0.03)
	shaded_fill.a = fill_color.a
	style.bg_color = shaded_fill
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_detail = 12
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	style.draw_center = true
	style.shadow_color = Color(0.02, 0.04, 0.07, shadow_alpha)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.expand_margin_bottom = 4.0
	style.expand_margin_left = 1.0
	style.expand_margin_right = 1.0
	style.expand_margin_top = 1.0
	style.border_blend = true
	return style

func _maybe_play_major_stinger(major_data: Dictionary, reveal_data: Dictionary) -> void:
	if major_data.is_empty():
		_last_audio_signature = ""
		_cleanup_major_stinger_audio()
		return
	if not ENABLE_ASSET_MAJOR_STINGER:
		_cleanup_major_stinger_audio()
		return
	var major_name := String(major_data.get("name", "Major"))
	var reveal_title := String(reveal_data.get("title", ""))
	var has_reveal := _run_state.has_reveal()
	var signature := "%s|%s|%s" % [major_name, reveal_title, String(_run_state.phase)]
	if not has_reveal:
		signature = "%s|ambient" % major_name
	if signature == _last_audio_signature:
		return
	_last_audio_signature = signature
	_play_major_stinger(major_name, reveal_title.find("Final") >= 0 or reveal_title.find("Grand Slam Complete") >= 0)

func _play_major_stinger(major_name: String, is_final: bool) -> void:
	var stream := _load_major_stinger_stream(major_name, is_final)
	if stream == null:
		_cleanup_major_stinger_audio()
		return
	_cleanup_major_stinger_audio()
	major_stinger_player.stop()
	major_stinger_player.stream = stream
	major_stinger_player.play()
	var total_duration := maxf(stream.get_length(), 0.25) + 0.10
	_major_stinger_cleanup_tween = create_tween()
	_major_stinger_cleanup_tween.tween_interval(total_duration)
	_major_stinger_cleanup_tween.finished.connect(func() -> void:
		_major_stinger_cleanup_tween = null
		_cleanup_major_stinger_audio()
	)

func _load_major_stinger_stream(major_name: String, is_final: bool) -> AudioStream:
	var bank: Dictionary = Dictionary(MAJOR_STINGER_PATHS.get(major_name, MAJOR_STINGER_PATHS["Default"]))
	var path := String(bank.get("final" if is_final else "intro", ""))
	if _major_stinger_stream_cache.has(path):
		return _major_stinger_stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path)
	if stream == null:
		return null
	_major_stinger_stream_cache[path] = stream
	return stream

func _cleanup_major_stinger_audio() -> void:
	if is_instance_valid(_major_stinger_cleanup_tween):
		_major_stinger_cleanup_tween.kill()
	_major_stinger_cleanup_tween = null
	if not is_instance_valid(major_stinger_player):
		return
	major_stinger_player.stop()
	major_stinger_player.stream = null
