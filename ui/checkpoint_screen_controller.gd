extends RefCounted

func refresh_rest_panel(host, run_state, selected_class, major_data: Dictionary, checkpoint_pane_presenter, max_potions: int) -> void:
	host._clear_container(host.rest_choice_row)
	if host._current_reward_menu_kind() != "rest":
		host.rest_checkpoint_panel.visible = false
		return

	var theme: Dictionary = host._get_presentation_theme(major_data)
	var payload: Dictionary = checkpoint_pane_presenter.build_rest_payload(run_state, max_potions) if checkpoint_pane_presenter != null else {}
	var reward_choices: Array = run_state.get_reward_choices()
	host.rest_eyebrow_label.text = String(payload.get("eyebrow", run_state.get_major_name() + " Recovery Camp"))
	host.rest_question_label.text = String(payload.get("question", "Reset the body or sharpen the deck?"))
	host.rest_summary_label.text = String(payload.get("summary", "Recovery stop between matches."))
	host.rest_ledger_title_label.text = String(payload.get("ledger_title", "Camp Ledger"))
	host.rest_ledger_body_label.text = String(payload.get("ledger_body", ""))
	host.rest_hint_label.text = String(payload.get("hint", "Choose one checkpoint action."))
	host.rest_leave_button.text = String(payload.get("leave_text", "Leave Camp"))
	host._refresh_checkpoint_header_art(
		host._rest_header_art,
		"rest",
		String(payload.get("header_title", run_state.get_major_name() + " Recovery Camp")),
		String(payload.get("header_body", "Restore condition or upgrade the deck before the next round.")),
		theme
	)

	if host.rest_scene_view.has_method("apply_theme"):
		host.rest_scene_view.call("apply_theme", theme)
	if host.rest_scene_view.has_method("apply_subject"):
		host.rest_scene_view.call("apply_subject", host._build_class_asset_subject(selected_class, true))

	for index in range(reward_choices.size()):
		var reward: Dictionary = reward_choices[index]
		var button = host._make_asset_tile(host._build_rest_choice_payload(reward), "rest_choice")
		button.pressed.connect(host._on_reward_selected.bind(index))
		host.rest_choice_row.add_child(button)

func refresh_reward_panel(host, run_state, major_data: Dictionary, checkpoint_pane_presenter, max_potions: int) -> void:
	if not is_instance_valid(host._reward_checkpoint_panel):
		return
	var reward_kind: String = String(host._current_reward_menu_kind())
	var is_reward_checkpoint: bool = run_state.phase == "reward" and reward_kind not in ["", "rest", "shop"]
	if not is_reward_checkpoint:
		host._reward_checkpoint_panel.visible = false
		return

	var theme: Dictionary = host._get_presentation_theme(major_data)
	var payload: Dictionary = checkpoint_pane_presenter.build_reward_payload(run_state, reward_kind, max_potions) if checkpoint_pane_presenter != null else {}
	var accent := Color(theme.get("accent", Color.WHITE))
	var text_color := Color(theme.get("text", Color.WHITE))
	var panel_fill := Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.03)
	var alt_fill := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22)))
	var reward_choices: Array = run_state.get_reward_choices()

	host._apply_panel_style(host._reward_checkpoint_panel, panel_fill, accent, {"variant": "primary"})
	if is_instance_valid(host._reward_header_panel):
		host._apply_panel_style(host._reward_header_panel, alt_fill.lightened(0.01), accent, {"variant": "hero", "tint_strength": 0.70})
	host._apply_panel_style(host._reward_prompt_panel, alt_fill.lightened(0.02), accent, {"variant": "primary"})
	host._apply_panel_style(host._reward_ledger_panel, alt_fill.darkened(0.01), accent, {"variant": "secondary"})
	host._apply_panel_style(host._reward_offer_panel, alt_fill.darkened(0.05), accent, {"variant": "secondary"})

	host._reward_eyebrow_label.text = String(payload.get("eyebrow", "%s Reward Screen" % run_state.get_major_name()))
	host._reward_question_label.text = String(payload.get("question", "What do you add to your bag for the next round?"))
	host._reward_offer_title_label.text = String(payload.get("offer_title", "Reward Draft"))
	host._reward_hint_label.text = String(payload.get("hint", "Pick one reward, or skip if you want to keep the deck lean."))
	host._reward_summary_label.text = String(payload.get("summary", String(run_state.pending_reward_reason).strip_edges()))
	host._refresh_checkpoint_header_art(
		host._reward_header_art,
		"reward",
		String(payload.get("header_title", run_state.get_major_name() + " Reward Room")),
		String(payload.get("header_body", "Draft for the next round and shape the bracket.")),
		theme
	)
	host._reward_ledger_title_label.text = String(payload.get("ledger_title", "Run Ledger"))
	host._reward_ledger_body_label.text = String(payload.get("ledger_body", ""))
	host._reward_eyebrow_label.add_theme_color_override("font_color", accent)
	host._reward_question_label.add_theme_color_override("font_color", text_color)
	host._reward_summary_label.add_theme_color_override("font_color", text_color)
	host._reward_ledger_title_label.add_theme_color_override("font_color", accent)
	host._reward_ledger_body_label.add_theme_color_override("font_color", text_color)
	host._reward_offer_title_label.add_theme_color_override("font_color", accent)
	host._reward_hint_label.add_theme_color_override("font_color", text_color)

	var equipment_summary := String(run_state.get_pending_equipment_bonus_summary()).strip_edges()
	host._reward_bonus_panel.visible = equipment_summary != ""
	if host._reward_bonus_panel.visible:
		host._apply_panel_style(host._reward_bonus_panel, alt_fill.darkened(0.03), accent, {"variant": "secondary"})
		host._reward_bonus_title_label.text = "Equipment Payout"
		host._reward_bonus_body_label.text = equipment_summary
		host._reward_bonus_title_label.add_theme_color_override("font_color", accent)
		host._reward_bonus_body_label.add_theme_color_override("font_color", text_color)

	host._clear_container(host._reward_offer_buttons)
	for index in range(reward_choices.size()):
		var reward: Dictionary = reward_choices[index]
		var tile_spec: Dictionary = host._build_reward_tile_spec(reward)
		var button = host._make_asset_tile(Dictionary(tile_spec.get("payload", {})), String(tile_spec.get("mode", "reward_card")))
		if reward.has("price_btc"):
			button.disabled = int(reward.get("price_btc", 0)) > int(run_state.bitcoin)
		button.pressed.connect(host._on_reward_selected.bind(index))
		host._reward_offer_buttons.add_child(button)

	host._reward_skip_button.visible = run_state.is_reward_skip_allowed()
	if host._reward_skip_button.visible:
		host._reward_skip_button.text = "Skip Reward" if reward_kind != "trim" else "Continue"
	host._apply_button_style(host._reward_skip_button, accent.lightened(0.02), accent.darkened(0.24), Color(0.07, 0.09, 0.10))

func refresh_reward_buttons(host, run_state) -> void:
	host._clear_container(host.reward_buttons)
	host._refresh_shop_offer_sections([], [], {})
	if run_state.phase != "reward":
		host.reward_header_label.text = "Reward Choices"
		host._add_placeholder(host.reward_buttons, "Rewards appear here after combats, treasure nodes, shops, and some events.")
		return

	host.reward_header_label.text = run_state.pending_reward_reason
	var reward_choices: Array = run_state.get_reward_choices()
	var reward_kind: String = String(host._current_reward_menu_kind())
	var potion_offers: Array = []
	var relic_offers: Array = []
	if reward_kind == "shop":
		for reward in reward_choices:
			var reward_type := String(Dictionary(reward).get("reward_type", ""))
			if reward_type == "shop_potion":
				potion_offers.append(Dictionary(reward))
			elif reward_type == "shop_relic":
				relic_offers.append(Dictionary(reward))
	host._refresh_shop_offer_sections(potion_offers, relic_offers, host._get_presentation_theme({} if run_state.phase == "idle" else run_state.get_major_data()))
	for index in range(reward_choices.size()):
		var reward: Dictionary = reward_choices[index]
		var reward_type := String(reward.get("reward_type", "card"))
		if reward_type in ["shop_potion", "shop_relic"]:
			continue
		var tile_spec: Dictionary = host._build_reward_tile_spec(reward)
		var button = host._make_asset_tile(Dictionary(tile_spec.get("payload", {})), String(tile_spec.get("mode", "reward_card")))
		if reward.has("price_btc"):
			button.disabled = int(reward.get("price_btc", 0)) > int(run_state.bitcoin)
		button.pressed.connect(host._on_reward_selected.bind(index))
		host.reward_buttons.add_child(button)
	if run_state.is_reward_skip_allowed():
		var is_checkpoint_menu: bool = run_state.is_checkpoint_menu()
		var skip_button = host._make_asset_tile({
			"title": "Leave Checkpoint" if is_checkpoint_menu else "Skip Reward",
			"description": "Head back to the bracket without spending more bitcoin." if is_checkpoint_menu else "Leave the card pool unchanged and head back to the bracket.",
			"footer_text": "Keep your bitcoin for the next stop." if is_checkpoint_menu else "No card or relic will be added.",
		}, "skip")
		skip_button.pressed.connect(host._on_skip_reward_pressed)
		host.reward_buttons.add_child(skip_button)

func refresh_shop_offer_sections(host, run_state, potion_offers: Array, relic_offers: Array, theme: Dictionary) -> void:
	if not is_instance_valid(host._shop_potion_panel) or not is_instance_valid(host._shop_relic_panel):
		return
	host._clear_container(host._shop_potion_buttons)
	host._clear_container(host._shop_relic_buttons)
	var show_potions := not potion_offers.is_empty()
	var show_relics := not relic_offers.is_empty()
	host._shop_potion_panel.visible = show_potions
	host._shop_relic_panel.visible = show_relics
	if not show_potions and not show_relics:
		return
	var accent := Color(theme.get("accent", Color(0.72, 0.88, 1.0)))
	var panel_fill := Color(theme.get("panel_alt", Color(0.15, 0.20, 0.24))).darkened(0.06)
	host._apply_panel_style(host._shop_potion_panel, panel_fill, accent, {"variant": "secondary"})
	host._apply_panel_style(host._shop_relic_panel, panel_fill, accent, {"variant": "secondary"})
	host._shop_potion_title_label.text = "Potion Bench"
	host._shop_relic_title_label.text = "Relic Cabinet"
	host._shop_potion_title_label.add_theme_color_override("font_color", accent)
	host._shop_relic_title_label.add_theme_color_override("font_color", accent)
	for reward in potion_offers:
		var button = host._make_asset_tile(host._build_shop_offer_payload(reward), "reward_card")
		if reward.has("price_btc"):
			button.disabled = int(reward.get("price_btc", 0)) > int(run_state.bitcoin)
		var reward_index: int = int(host._find_reward_choice_index(reward))
		if reward_index >= 0:
			button.pressed.connect(host._on_reward_selected.bind(reward_index))
		else:
			button.disabled = true
		host._shop_potion_buttons.add_child(button)
	for reward in relic_offers:
		var button = host._make_asset_tile(host._build_shop_offer_payload(reward), "relic_reward")
		if reward.has("price_btc"):
			button.disabled = int(reward.get("price_btc", 0)) > int(run_state.bitcoin)
		var reward_index: int = int(host._find_reward_choice_index(reward))
		if reward_index >= 0:
			button.pressed.connect(host._on_reward_selected.bind(reward_index))
		else:
			button.disabled = true
		host._shop_relic_buttons.add_child(button)

func refresh_shop_panel(host, run_state, major_data: Dictionary, checkpoint_pane_presenter, max_potions: int) -> void:
	if not is_instance_valid(host._shop_checkpoint_panel):
		return
	if host._current_reward_menu_kind() != "shop":
		host._shop_checkpoint_panel.visible = false
		return

	var reward_choices: Array = run_state.get_reward_choices()
	var potion_offers: Array = []
	var relic_offers: Array = []
	var market_offers: Array = []
	for reward in reward_choices:
		var reward_dict := Dictionary(reward)
		var reward_type := String(reward_dict.get("reward_type", ""))
		match reward_type:
			"shop_potion":
				potion_offers.append(reward_dict)
			"shop_relic":
				relic_offers.append(reward_dict)
			"shop_card", "shop_remove", "card_upgrade", "racquet_upgrade":
				market_offers.append(reward_dict)

	var theme: Dictionary = host._get_presentation_theme(major_data)
	var payload: Dictionary = checkpoint_pane_presenter.build_shop_payload(run_state, max_potions) if checkpoint_pane_presenter != null else {}
	var accent := Color(theme.get("accent", Color.WHITE))
	var text_color := Color(theme.get("text", Color.WHITE))
	var panel_fill := Color(theme.get("panel", Color(0.12, 0.15, 0.17))).darkened(0.03)
	var alt_fill := Color(theme.get("panel_alt", Color(0.16, 0.19, 0.22)))
	var palette: Dictionary = host.theme_manager.get_palette() if host.theme_manager != null and host.theme_manager.has_method("get_palette") else {}
	var route_fill := Color(palette.get("primary", accent.lightened(0.18)))
	var route_border := route_fill.lightened(0.14)
	var route_text := Color(0.07, 0.09, 0.10)
	host._apply_panel_style(host._shop_checkpoint_panel, panel_fill, accent, {"variant": "primary"})
	if is_instance_valid(host._shop_header_panel):
		host._apply_panel_style(host._shop_header_panel, alt_fill.lightened(0.01), accent, {"variant": "hero", "tint_strength": 0.70})
	host._apply_panel_style(host._shop_prompt_panel, alt_fill.lightened(0.02), accent, {"variant": "primary"})
	host._apply_panel_style(host._shop_ledger_panel, alt_fill.darkened(0.01), accent, {"variant": "secondary"})
	host._apply_panel_style(host._shop_potion_panel, alt_fill.darkened(0.03), accent, {"variant": "secondary"})
	host._apply_panel_style(host._shop_relic_panel, alt_fill.darkened(0.03), accent, {"variant": "secondary"})
	host._apply_panel_style(host._shop_market_panel, alt_fill.darkened(0.05), accent, {"variant": "secondary"})

	host._shop_eyebrow_label.text = String(payload.get("eyebrow", "%s Pro Shop" % run_state.get_major_name()))
	host._shop_question_label.text = String(payload.get("question", "Spend sponsor money before the next round?"))
	host._shop_summary_label.text = String(payload.get("summary", "Tour checkpoint between matches."))
	host._refresh_checkpoint_header_art(
		host._shop_header_art,
		"shop",
		String(payload.get("header_title", run_state.get_major_name() + " Pro Shop")),
		String(payload.get("header_body", "Spend BTC on gear before the next round.")),
		theme
	)
	host._shop_ledger_title_label.text = String(payload.get("ledger_title", "Checkpoint Ledger"))
	host._shop_ledger_body_label.text = String(payload.get("ledger_body", ""))
	host._shop_hint_label.text = String(payload.get("hint", "Potions are for boss pressure swings, relics are permanent, and cards plus frame tuning reshape the whole run."))
	host._shop_leave_button.text = String(payload.get("leave_text", "Leave Shop"))
	if is_instance_valid(host._shop_leave_button_top):
		host._shop_leave_button_top.text = String(payload.get("leave_text", "Leave Shop"))
		host._shop_leave_button_top.tooltip_text = "Return to route select without spending more bitcoin."
	if is_instance_valid(host._shop_header_leave_button):
		host._shop_header_leave_button.visible = true
		host._shop_header_leave_button.text = String(payload.get("leave_text", "Leave Shop"))
		host._shop_header_leave_button.tooltip_text = "Return to route select without spending more bitcoin."

	host._shop_eyebrow_label.add_theme_color_override("font_color", accent)
	host._shop_question_label.add_theme_color_override("font_color", text_color)
	host._shop_summary_label.add_theme_color_override("font_color", text_color)
	host._shop_ledger_title_label.add_theme_color_override("font_color", accent)
	host._shop_ledger_body_label.add_theme_color_override("font_color", text_color)
	host._shop_market_title_label.add_theme_color_override("font_color", accent)
	host._shop_hint_label.add_theme_color_override("font_color", text_color)
	host._apply_button_style(host._shop_leave_button, accent.lightened(0.02), accent.darkened(0.24), Color(0.07, 0.09, 0.10))
	if is_instance_valid(host._shop_leave_button_top):
		host._apply_button_style(host._shop_leave_button_top, route_fill, route_border, route_text)
	if is_instance_valid(host._shop_header_leave_button):
		host._apply_button_style(host._shop_header_leave_button, route_fill, route_border, route_text)

	refresh_shop_offer_sections(host, run_state, potion_offers, relic_offers, theme)
	host._clear_container(host._shop_market_buttons)
	host._shop_market_panel.visible = not market_offers.is_empty()
	if host._shop_market_panel.visible:
		host._shop_market_title_label.text = String(payload.get("market_title", "Card Market and Workshop"))
		for reward in market_offers:
			var tile_payload: Dictionary = reward.duplicate(true)
			match String(reward.get("reward_type", "")):
				"shop_card":
					tile_payload["display_type"] = "BUY"
					tile_payload["display_art"] = "Card Market"
					tile_payload["display_icon"] = "ball"
					tile_payload["display_footer"] = String(reward.get("footer_text", "Costs %d BTC" % int(reward.get("price_btc", 0))))
				"shop_remove":
					tile_payload["display_title"] = String(reward.get("name", "Deck Purge Service"))
					tile_payload["display_description"] = String(reward.get("description", "Pay to remove one card from the deck."))
					tile_payload["display_type"] = "CUT"
					tile_payload["display_art"] = "Deck Surgeon"
					tile_payload["display_icon"] = "bitcoin"
					tile_payload["display_footer"] = String(reward.get("footer_text", ""))
				"card_upgrade":
					tile_payload["display_title"] = String(reward.get("name", "Card Upgrade"))
					tile_payload["display_description"] = String(reward.get("description", "Upgrade one card in the deck."))
					tile_payload["display_type"] = "UPGRADE"
					tile_payload["display_art"] = "Card Lab"
					tile_payload["display_icon"] = "racquet_tune"
					tile_payload["display_footer"] = String(reward.get("footer_text", ""))
				"racquet_upgrade":
					tile_payload["display_title"] = String(reward.get("name", "Racquet Tune"))
					tile_payload["display_description"] = String(reward.get("description", "Upgrade racquet tuning for the run."))
					tile_payload["display_type"] = "TUNE"
					tile_payload["display_art"] = "Frame Bench"
					tile_payload["display_icon"] = "racquet_tune"
					tile_payload["display_footer"] = String(reward.get("footer_text", ""))
			var button = host._make_asset_tile(tile_payload, "reward_card")
			if reward.has("price_btc"):
				button.disabled = int(reward.get("price_btc", 0)) > int(run_state.bitcoin)
			var reward_index: int = int(host._find_reward_choice_index(reward))
			if reward_index >= 0:
				button.pressed.connect(host._on_reward_selected.bind(reward_index))
			else:
				button.disabled = true
			host._shop_market_buttons.add_child(button)
