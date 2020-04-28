--Shared data interface between data and script, notably prototype names.

local data = {}

data.tile_collision_mask = {"object-layer"}
data.drone_collision_mask = {"ground-tile", "water-tile", "not-colliding-with-itself", "colliding-with-tiles-only", "consider-tile-transitions"}
--data.drone_collision_mask = {"ground-tile", "water-tile", "not-colliding-with-itself", "colliding-with-tiles-only"}
--data.drone_collision_mask = {"ground-tile", "water-tile"}
data.variation_count = 50
data.transport_speed_technology = "transport-drone-speed"
data.transport_capacity_technology = "transport-drone-capacity"
data.transport_system_technology = "transport-system"

data.fuel_fluid = settings.startup["fuel-fluid"].value
data.fuel_amount_per_drone = settings.startup["fuel-amount-per-drone"].value
data.fuel_consumption_per_meter = settings.startup["fuel-consumption-per-meter"].value
data.drone_fluid_capacity = settings.startup["drone-fluid-capacity"].value
data.drone_pollution_per_second = settings.startup["drone-pollution-per-second"].value

return data
