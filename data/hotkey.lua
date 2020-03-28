local hotkey =
{
  type = "custom-input",
  name = "follow-drone",
  localised_named = {"follow-drone"},
  linked_game_control = "toggle-driving",
  key_sequence = "return",
  enabled_while_in_cutscene = true
}

data:extend{hotkey}