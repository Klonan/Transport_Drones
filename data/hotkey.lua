local hotkeys =
{
  {
    type = "custom-input",
    name = "follow-drone",
    localised_named = {"follow-drone"},
    linked_game_control = "toggle-driving",
    key_sequence = "return",
    enabled_while_in_cutscene = true
  },
  {
    type = "custom-input",
    name = "transport-drones-gui",
    localised_named = {"transport-drones-gui"},
    key_sequence = "ALT + T",
    action = "lua",
  },
}

data:extend(hotkeys)