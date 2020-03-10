local name = "transport-drone"

local sprite_base = util.copy(data.raw.car.tank)

util.recursive_hack_make_hr(sprite_base)
util.recursive_hack_scale(sprite_base, 0.4)

local transport_drone_flags = {"placeable-off-grid"}

local attack_range = 36
local unit =
{
  type = "unit",
  name = name,
  localised_name = {name},
  icon = sprite_base.icon,
  icon_size = sprite_base.icon_size,
  flags = transport_drone_flags,
  map_color = {b = 0.5, g = 1},
  enemy_map_color = {r = 1},
  max_health = 50,
  radar_range = 1,
  order="i-d",
  subgroup = "transport",
  healing_per_tick = 0.1,
  --minable = {result = name, mining_time = 2},
  collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
  selection_box = {{-0.3, -0.3}, {0.3, 0.3}},
  collision_mask = shared.drone_collision_mask,
  max_pursue_distance = 64,
  min_persue_time = (60 * 15),
  --sticker_box = {{-0.2, -0.2}, {0.2, 0.2}},
  distraction_cooldown = (15),
  move_while_shooting = false,
  can_open_gates = true,
  ai_settings =
  {
    do_separation = false
  },
  attack_parameters =
  {
    type = "projectile",
    ammo_category = "bullet",
    warmup = math.floor(19 * 1),
    cooldown = math.floor((26 - 19) * 1),
    range = 0.5,
    ammo_type =
    {
      category = util.ammo_category("transport-drone"),
      target_type = "entity",
      action =
      {
        type = "direct",
        action_delivery =
        {
          {
            type = "instant",
            target_effects =
            {
              {
                type = "damage",
                damage = {amount = shared.mining_damage , type = util.damage_type("physical")}
              }
            }
          }
        }
      }
    },
    animation = sprite_base.animation
  },
  vision_distance = 40,
  has_belt_immunity = true,
  movement_speed = 0.15,
  distance_per_frame = 0.15,
  pollution_to_join_attack = 1000,
  rotation_speed = 1 / (60 * 1),
  --corpse = name.." Corpse",
  dying_explosion = "explosion",
  vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
  working_sound =
  {
    sound = sprite_base.working_sound.sound
  },
  run_animation = sprite_base.animation
}


local item =
{
  type = "item",
  name = name,
  localised_name = {name},
  icon = unit.icon,
  icon_size = unit.icon_size,
  flags = {},
  subgroup = "transport",
  order = "e-"..name,
  stack_size = 10,
  --place_result = name
}

local recipe =
{
  type = "recipe",
  name = name,
  localised_name = {name},
  --category = "transport",
  enabled = true,
  ingredients =
  {
    {"engine-unit", 10},
    {"steel-plate", 20},
    {"explosives", 20},
    {"rocket-fuel", 5}
  },
  energy_required = 45,
  result = name
}

local slow_sticker =
{
  type = "sticker",
  name = "drone-slowdown-sticker",
  --icon = "__base__/graphics/icons/slowdown-sticker.png",
  flags = {},
  animation =
  {
    filename = "__base__/graphics/entity/slowdown-sticker/slowdown-sticker.png",
    priority = "extra-high",
    width = 1,
    height = 1,
    frame_count = 1,
    animation_speed = 1
  },
  duration_in_ticks = 1 * 60,
  target_movement_modifier = 1,
  target_movement_modifier_from = -0.1,
  target_movement_modifier_to = 1
}


data:extend
{
  unit,
  item,
  recipe,
  slow_sticker
}
