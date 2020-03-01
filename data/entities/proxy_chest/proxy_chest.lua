local proxy_chest = util.copy(data.raw.container["iron-chest"])
proxy_chest.name = shared.proxy_chest_name
proxy_chest.order = shared.proxy_chest_name
proxy_chest.inventory_size = 10
proxy_chest.collision_box = nil
proxy_chest.next_upgrade = nil
data:extend
{
  proxy_chest
}
