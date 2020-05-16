--local reader = util.copy(data.raw.pump.pump)
--reader.name = "transport-depot-reader"

local writer_sprite = util.copy(data.raw["constant-combinator"]["constant-combinator"])

local writer = util.copy(data.raw.pump.pump)
writer.name = "transport-depot-writer"
writer.localised_name = "Transport depot writer"
writer.energy_source = 
{
  type = "void",
  energy_usage = "0w"
}

writer.glass_pictures = nil
writer.animations = writer_sprite.sprites
writer.fluid_animations = nil
writer.pumping_speed = 0
writer.load_connector_animations = nil
writer.unload_connetor_animations = nil
writer.fluid_wagon_connector_frame_count = 0
writer.collision_box = {{-0.4, -0.4},{0.4, 0.4}}
writer.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
writer.minable.result = "transport-depot-writer"
writer.circuit_connector_sprites =
{
  data.raw.lamp["small-lamp"].circuit_connector_sprites,
  data.raw.lamp["small-lamp"].circuit_connector_sprites,
  data.raw.lamp["small-lamp"].circuit_connector_sprites,
  data.raw.lamp["small-lamp"].circuit_connector_sprites
}
writer.circuit_wire_connection_points = writer_sprite.circuit_wire_connection_points
writer.fluid_box =
{
  pipe_connections = 
  {
    {
      position = {0,1},
      type = "output"
    }
  }
}

local writer_item = 
{
  type = "item",
  name = "transport-depot-writer",
  icon = writer.icon,
  icon_size = writer.icon_size,
  stack_size = 20,
  place_result = "transport-depot-writer"
}

data:extend
{
  writer,
  writer_item
}