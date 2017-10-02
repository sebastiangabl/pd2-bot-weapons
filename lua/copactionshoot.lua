local function mean(tbl)
  if not tbl or #tbl == 0 then
    return
  end
  local sum = 0
  for _, v in ipairs(tbl) do
    sum = sum + v
  end
  return sum / #tbl
end

local init_original = CopActionShoot.init
function CopActionShoot:init(action_desc, common_data, ...)
  local result = init_original(self, action_desc, common_data, ...)
  if managers.groupai:state():is_unit_team_AI(self._unit) then
    local w_tweak = self._weap_tweak
    local w_u_tweak = self._w_usage_tweak
    local m4_tweak = tweak_data.weapon.m4_crew
    local m4_u_tweak = common_data.char_tweak.weapon[m4_tweak.usage]
    if not w_tweak.falloff then
      if not CopActionShoot.TEAM_AI_TARGET_DAMAGE then
        -- calculate m4 dps as target dps for other weapons
        local dmg = m4_tweak.DAMAGE
        local mag = m4_tweak.CLIP_AMMO_MAX
        local burst_size = m4_tweak.fire_mode == "auto" and mean(m4_u_tweak.autofire_rounds) or 1
        local shot_delay = m4_tweak.auto.fire_rate
        local burst_delay = m4_tweak.burst_delay
        local reload_time = 2 -- TODO: get actual animation time
        local reload = reload_time / m4_u_tweak.RELOAD_SPEED
        CopActionShoot.TEAM_AI_TARGET_DAMAGE = (dmg * mag) / ((mag / burst_size) * (burst_size - 1) * shot_delay + (mag / burst_size - 1) * burst_delay + reload)
      end
      -- calculate weapon damage based on m4 dps
      local mag = w_tweak.CLIP_AMMO_MAX
      local burst_size = w_tweak.fire_mode == "auto" and mean(w_u_tweak.autofire_rounds) or 1
      local shot_delay = w_tweak.auto.fire_rate
      local burst_delay = w_tweak.burst_delay
      local reload_time = 2 -- TODO: get actual animation time
      local reload = reload_time / w_u_tweak.RELOAD_SPEED
      self._weapon_base._damage = (CopActionShoot.TEAM_AI_TARGET_DAMAGE * ((mag / burst_size) * (burst_size - 1) * shot_delay + (mag / burst_size - 1) * burst_delay + reload)) / mag
      -- customize falloff to allow usage independent single fire rates
      w_tweak.falloff = deep_clone(m4_u_tweak.FALLOFF)
      local recoil = { burst_delay, burst_delay }
      for _, v in ipairs(w_tweak.falloff) do
        v.recoil = recoil
      end
      if con then
        con:print(self._weapon_base._name_id .. ": damage = " .. self._weapon_base._damage .. ", recoil = " .. recoil[1])
      end
    end
    self._falloff = w_tweak.falloff
    self._automatic_weap = w_tweak.fire_mode == "auto" and w_u_tweak.autofire_rounds and true
    self._spread = self._automatic_weap and m4_u_tweak.spread or math.min(m4_u_tweak.spread, 20) - w_tweak.burst_delay * 2
  end
  return result
end
