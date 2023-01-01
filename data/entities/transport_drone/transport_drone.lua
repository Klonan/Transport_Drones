local affected_by_tiles = true

local util = require "__Transport_Drones__/data/tf_util/tf_util"

local fuel = settings.startup["fuel-fluid"].value
if not data.raw.fluid[fuel] then
  log("Bad name for fuel fluid. reverting to something else...")

  fuel = "petroleum-gas"
  if not data.raw.fluid[fuel] then
    fuel = nil
    for k, fluid in pairs (data.raw.fluid) do
      if fluid.fuel_value then
        fuel = fluid.name
        break
      end
    end
  end

  if not fuel then
    local index, fluid = next(data.raw.fluid)
    if fluid then
      fuel = fluid.name
    end
  end
end

local shared = require("shared")

local name = "transport-drone"


local transport_drone_flags = {"placeable-off-grid", "not-in-kill-statistics"}
local sprite_base = util.copy(data.raw.car.tank)

local empty_truck = function(shift)
  assert(shift)
  return
  {
    layers =
    {
      {
        filename = util.path("data/entities/transport_drone/trailer_base.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/trailer_base_shadow.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5,
        draw_as_shadow = true
      },
      {
        filename = util.path("data/entities/transport_drone/player_mask.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = true,
        scale = 0.5
      }
    }
  }

end

local box_variant = 0
local full_truck = function(shift)
  box_variant = box_variant + 1
  return
  {
    layers =
    {
      {
        filename = util.path("data/entities/transport_drone/truck_boxes_variation_"..(box_variant % 5)..".png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/truck_boxes_variation_"..(box_variant % 5).."_shadow.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5,
        draw_as_shadow = true
      },
      {
        filename = util.path("data/entities/transport_drone/player_mask.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = true,
        scale = 0.5
      }
    }
  }

end

local ore_variant = 0
local ore_truck = function(shift, tint)
  ore_variant = ore_variant + 1
  return
  {
    layers =
    {
      {
        filename = util.path("data/entities/transport_drone/trailer_base.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/player_mask.png"),
        frame_count = 1,
        direction_count = 36,
        repeat_count = 1,
        line_length = 10,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = true,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/ore_mask_variation_"..((ore_variant + math.random(4)) % 5)..".png"),
        frame_count = 1,
        direction_count = 36,
        repeat_count = 1,
        line_length = 10,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = false,
        tint = tint,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/ore_mask_variation_"..((ore_variant) % 5)..".png"),
        frame_count = 1,
        direction_count = 36,
        repeat_count = 1,
        line_length = 10,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = false,
        tint = tint,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/trailer_base_shadow.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5,
        draw_as_shadow = true
      }
    }
  }

end

local fluid_truck = function(shift, tint)

  return
  {
    layers =
    {
      {
        filename = util.path("data/entities/transport_drone/fluid_base.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/fluid_base_shadow.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        scale = 0.5,
        draw_as_shadow = true
      },
      {
        filename = util.path("data/entities/transport_drone/player_mask.png"),
        frame_count = 1,
        direction_count = 36,
        line_length = 10,
        repeat_count = 1,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = true,
        scale = 0.5
      },
      {
        filename = util.path("data/entities/transport_drone/fluid_mask.png"),
        frame_count = 1,
        direction_count = 36,
        repeat_count = 1,
        line_length = 10,
        width = 192,
        height = 192,
        shift = shift,
        apply_runtime_tint = false,
        tint = tint,
        scale = 0.5
      }
    }
  }

end




local make_unit = function(k)

  local shift = {(math.random() - 0.5) / 1.5, (math.random() - 0.5) / 1.5}
  --local sprite_base = util.copy(sprite_base)
  --util.recursive_hack_make_hr(sprite_base)
  --util.recursive_hack_scale(sprite_base, 0.4 + (math.random()/ 20))
  --util.recursive_hack_shift(sprite_base, shift)

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

  local darkness = 0.3  + math.random() / 5

  local unit =
  {
    type = "unit",
    name = name.."-"..k,
    localised_name = {name},
    icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
    icon_size = 112,
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
    collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
    selection_box = selection_box,
    sticker_box = {shift, shift},
    collision_mask = shared.drone_collision_mask,
    max_pursue_distance = 64,
    min_persue_time = (60 * 15),
    --sticker_box = {{-0.2, -0.2}, {0.2, 0.2}},
    distraction_cooldown = (15),
    move_while_shooting = true,
    can_open_gates = true,
    ai_settings =
    {
      do_separation = false
    },
    attack_parameters =
    {
      type = "projectile",
      ammo_category = "bullet",
      warmup = 0,
      cooldown = 2 ^ 30,
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
                  damage = {amount = 10 , type = util.damage_type("physical")}
                }
              }
            }
          }
        }
      },
      animation = full_truck(shift)
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
        minimum_darkness = darkness,
        intensity = 0.4,
        size = 10,
        color = {r=1.0, g=1.0, b=1.0},
        shift = shift
      },
      {
        type = "oriented",
        minimum_darkness = darkness,
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
    --run_animation = empty_truck(shift),
    run_animation = full_truck(shift),
    affected_by_tiles = affected_by_tiles,
    emissions_per_second = shared.drone_pollution_per_second
  }
  data:extend{unit}
end

for k = 1, shared.variation_count do
  make_unit(k)
end

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


local get_item = function(entity)
  if entity.minable.result then
    return entity.minable.result or entity.minable.result[1]
  end

  if entity.minable.results then
    for k, result in pairs (entity.minable.results) do
      local name = result.name or result[1]
      return name
    end
  end
end

local make_ore_truck = function(resource, item_name)

  local map_color = resource.map_color
  local r, g, b = map_color[1] or map_color.r or 0, map_color[2] or map_color.g or 0, map_color[3] or map_color.b or 0
  r = (r + 0.5) / 1.5
  g = (g + 0.5) / 1.5
  b = (b + 0.5) / 1.5
  local color = {r, g, b, 1}

  for k = 1, shared.special_variation_count do
    local shift = {(math.random() - 0.5) / 1.5, (math.random() - 0.5) / 1.5}

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

    local darkness = 0.3  + math.random() / 5

    local unit =
    {
      type = "unit",
      name = name.."-"..item_name.."-"..k,
      localised_name = {name},
      icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
      icon_size = 112,
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
      collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
      selection_box = selection_box,
      sticker_box = {shift, shift},
      collision_mask = shared.drone_collision_mask,
      max_pursue_distance = 64,
      min_persue_time = (60 * 15),
      --sticker_box = {{-0.2, -0.2}, {0.2, 0.2}},
      distraction_cooldown = (15),
      move_while_shooting = true,
      can_open_gates = true,
      ai_settings =
      {
        do_separation = false
      },
      attack_parameters =
      {
        type = "projectile",
        ammo_category = "bullet",
        warmup = 0,
        cooldown = 2 ^ 30,
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
                    damage = {amount = 10 , type = util.damage_type("physical")}
                  }
                }
              }
            }
          }
        },
        animation = ore_truck(shift, color)
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
          minimum_darkness = darkness,
          intensity = 0.4,
          size = 10,
          color = {r=1.0, g=1.0, b=1.0},
          shift = shift
        },
        {
          type = "oriented",
          minimum_darkness = darkness,
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
      --run_animation = empty_truck(shift),
      run_animation = ore_truck(shift, color),
    affected_by_tiles = affected_by_tiles,
      emissions_per_second = shared.drone_pollution_per_second
    }
    data:extend{unit}

  end
end

local resources = data.raw.resource

for k, resource in pairs (resources) do
  local item_name = get_item(resource)
  if item_name then
    make_ore_truck(resource, item_name)
  end
end


local make_fluid_truck = function(fluid)

  local r, g, b = fluid.base_color[1] or fluid.base_color.r or 0, fluid.base_color[2] or fluid.base_color.g or 0, fluid.base_color[3] or fluid.base_color.b or 0
  r = (r + 0.8) / 2
  g = (g + 0.8) / 2
  b = (b + 0.8) / 2
  local color = {r, g, b, 1}

  for k = 1, shared.special_variation_count do
    local shift = {(math.random() - 0.5) / 1.5, (math.random() - 0.5) / 1.5}

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

    local darkness = 0.3  + math.random() / 5

    local unit =
    {
      type = "unit",
      name = name.."-"..fluid.name.."-"..k,
      localised_name = {name},
      icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
      icon_size = 112,
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
      collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
      selection_box = selection_box,
      sticker_box = {shift, shift},
      collision_mask = shared.drone_collision_mask,
      max_pursue_distance = 64,
      min_persue_time = (60 * 15),
      --sticker_box = {{-0.2, -0.2}, {0.2, 0.2}},
      distraction_cooldown = (15),
      move_while_shooting = true,
      can_open_gates = true,
      ai_settings =
      {
        do_separation = false
      },
      attack_parameters =
      {
        type = "projectile",
        ammo_category = "bullet",
        warmup = 0,
        cooldown = 2 ^ 30,
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
                    damage = {amount = 10 , type = util.damage_type("physical")}
                  }
                }
              }
            }
          }
        },
        animation = fluid_truck(shift, color)
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
          minimum_darkness = darkness,
          intensity = 0.4,
          size = 10,
          color = {r=1.0, g=1.0, b=1.0},
          shift = shift
        },
        {
          type = "oriented",
          minimum_darkness = darkness,
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
      --run_animation = fluid_truck(shift, {0,0,0, 0.5}),
      run_animation = fluid_truck(shift, color),
    affected_by_tiles = affected_by_tiles,
      emissions_per_second = shared.drone_pollution_per_second
    }
    data:extend{unit}

  end
end

for k, fluid in pairs (data.raw.fluid) do
  make_fluid_truck(fluid)
end


data:extend
{
  slow_sticker
}

local sprite_switch_hack_proxy =
{
  type = "simple-entity",
  name = "sprite-switch-proxy",
  picture = util.empty_sprite(),
  flags = {"placeable-off-grid", "not-in-kill-statistics"},
  selectable_in_game = false,
  collision_mask = {},
  max_health = 1
}

local make_fuel_truck = function(fluid)

  local r, g, b = fluid.base_color[1] or fluid.base_color.r, fluid.base_color[2] or fluid.base_color.g, fluid.base_color[3] or fluid.base_color.b
  r = (r + 0.8) / 2
  g = (g + 0.8) / 2
  b = (b + 0.8) / 2
  local color = {r, g, b, 1}

  for k = 1, shared.special_variation_count do
    local shift = {(math.random() - 0.5) / 1.5, (math.random() - 0.5) / 1.5}

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

    local darkness = 0.3  + math.random() / 5

    local unit =
    {
      type = "unit",
      name = name.."-fuel-truck-"..k,
      localised_name = {name},
      icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
      icon_size = 112,
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
      collision_box = {{-0.01, -0.01}, {0.01, 0.01}},
      selection_box = selection_box,
      sticker_box = {shift, shift},
      collision_mask = shared.drone_collision_mask,
      max_pursue_distance = 64,
      min_persue_time = (60 * 15),
      --sticker_box = {{-0.2, -0.2}, {0.2, 0.2}},
      distraction_cooldown = (15),
      move_while_shooting = true,
      can_open_gates = true,
      ai_settings =
      {
        do_separation = false
      },
      attack_parameters =
      {
        type = "projectile",
        ammo_category = "bullet",
        warmup = 0,
        cooldown = 2 ^ 30,
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
                    damage = {amount = 10 , type = util.damage_type("physical")}
                  }
                }
              }
            }
          }
        },
        animation = fluid_truck(shift, {0,0,0, 0.5}),
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
          minimum_darkness = darkness,
          intensity = 0.4,
          size = 10,
          color = {r=1.0, g=1.0, b=1.0},
          shift = shift
        },
        {
          type = "oriented",
          minimum_darkness = darkness,
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
      run_animation = fluid_truck(shift, color),
    affected_by_tiles = affected_by_tiles,
      emissions_per_second = shared.drone_pollution_per_second
    }
    data:extend{unit}

  end
end

for k = 1, shared.special_variation_count do
  make_fuel_truck(data.raw.fluid[fuel])
end

data:extend{sprite_switch_hack_proxy}
