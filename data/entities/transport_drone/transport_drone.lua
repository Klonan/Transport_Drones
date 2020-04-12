local shared = require("shared")

local name = "transport-drone"


local transport_drone_flags = {"placeable-off-grid", "not-in-kill-statistics"}
local sprite_base = util.copy(data.raw.car.tank)

local make_unit = function(k)

  local sprite_base = util.copy(sprite_base)
  util.recursive_hack_make_hr(sprite_base)
  util.recursive_hack_scale(sprite_base, 0.4 + (math.random()/ 20))
  local shift = {(math.random() - 0.5) / 1.5, (math.random() - 0.5) / 1.5}
  util.recursive_hack_shift(sprite_base, shift)

  local selection_box =
  {
    {
      -0.3 + shift[1],
      -0.3 + shift[2],
    },
    {
      0.3 + shift[1],
      0.3 + shift[2],
    }
  }

  local unit =
  {
    type = "unit",
    name = name.."-"..k,
    localised_name = {name},
    icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
    icon_size = 113,
    icon_mipmaps = 0,
    flags = transport_drone_flags,
    map_color = {b = 0.5, g = 1},
    enemy_map_color = {r = 1},
    max_health = 50,
    radar_range = 1,
    order="i-d",
    subgroup = "transport",
    resistances = 
    {
      {
        type = "acid",
        decrease = 0,
        percent = 90
      }
    },
    healing_per_tick = 0.1,
    --minable = {result = name, mining_time = 2},
    collision_box = {{-0.1, -0.1}, {0.1, 0.1}},
    selection_box = selection_box,
    sticker_box = {shift, shift},
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
                  damage = {amount = 5 , type = util.damage_type("physical")}
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
    not_controllable = true,
    movement_speed = 0.15,
    distance_per_frame = 0.15,
    pollution_to_join_attack = 1000,
    rotation_speed = 1 / (60 * 1 + (math.random() / 20)),
    --corpse = name.." Corpse",
    dying_explosion = "explosion",
    light =
    {
      {
        minimum_darkness = 0.3,
        intensity = 0.4,
        size = 10,
        color = {r=1.0, g=1.0, b=1.0},
        shift = shift
      },
      {
        type = "oriented",
        minimum_darkness = 0.3,
        picture =
        {
          filename = "__core__/graphics/light-cone.png",
          priority = "extra-high",
          flags = { "light" },
          scale = 2,
          width = 200,
          height = 200
        },
        shift = {shift[1], shift[2] -3.5},
        size = 0.5,
        intensity = 0.6,
        color = {r=1.0, g=1.0, b=1.0}
      }
    },
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    working_sound =
    {
      sound = sprite_base.working_sound.sound,
      max_sounds_per_type = 5,
      audible_distance_modifier = 0.7
    },
    run_animation = sprite_base.animation,
    emissions_per_second = shared.drone_pollution_per_second
  }
  data:extend{unit}
end

for k = 1, shared.variation_count do
  make_unit(k)
end


local item =
{
  type = "item",
  name = name,
  localised_name = {name},
  icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
  icon_size = 113,
  flags = {},
  subgroup = "transport-drones",
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
  enabled = false,
  ingredients =
  {
    {"engine-unit", 1},
    {"steel-plate", 5},
    {"iron-gear-wheel", 5},
  },
  energy_required = 2,
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
  item,
  recipe,
  slow_sticker
}
