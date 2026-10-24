-- Component for view/copy code buttons in lobby
function MP.UI.create_lobby_code_buttons(text_scale)
	return {
		n = G.UIT.C,
		config = {
			align = "cm",
		},
		nodes = {
			UIBox_button({
				button = "view_code",
				colour = G.C.PALE_GREEN,
				minw = 2.15,
				minh = 0.65,
				label = { localize("b_view_code") },
				scale = text_scale * 1.2,
			}),
			MP.UI.create_spacer(0.1, true),
			UIBox_button({
				button = "copy_to_clipboard",
				colour = G.C.PERISHABLE,
				minw = 2.15,
				minh = 0.65,
				label = { localize("b_copy_code") },
				scale = text_scale,
			}),
			MP.STEAM_P2P and MP.UI.create_spacer(0.1, true) or nil,
			MP.STEAM_P2P and UIBox_button({
				button = "mp3p_steam_invite",
				colour = G.C.BLUE,
				minw = 2.15,
				minh = 0.65,
				label = { "Invite Steam friend" },
				scale = text_scale,
			}) or nil,
		},
	}
end

-- 3P fork: opens the Steam overlay invite dialog for the P2P lobby
function G.FUNCS.mp3p_steam_invite(e)
	if MP.STEAM_P2P and not MP.STEAM_P2P.invite() then
		sendWarnMessage("Steam invite: no Steam lobby yet (still creating?)", "MULTIPLAYER")
	end
end
