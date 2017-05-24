dofile(ModPath .. "lua/botweapons.lua")

local init_original = WeaponTweakData.init
function WeaponTweakData:init(...)
  init_original(self, ...)
  
  BotWeapons:log("Setting up weapons")
  
  -- copy animations from usage
  for k, v in pairs(self) do
    if type(v) == "table" and k:match("_crew$") then
      if v.usage then
        v.anim = v.usage
      end
    end
  end
  
  -- fix stuff
  self.judge_crew.is_shotgun = true
  self.judge_crew.usage = "mossberg"
  self.m14_crew.usage = "m14"
  self.rota_crew.usage = "mossberg"
  self.m37_crew.usage = "r870"
  self.m37_crew.anim = "r870"
  self.g22c_crew.auto = nil
  self.usp_crew.auto = nil
  self.tecci_crew.auto = { fire_rate = 0.09 }
  self.desertfox_crew.auto = { fire_rate = 1 }
  
  local m4_dps = self.m4_crew.DAMAGE / self.m4_crew.auto.fire_rate

  for k, v in pairs(self) do
    if type(v) == "table" and k:match("_crew$") then
      -- fix auto akimbo fire rates
      if k:match("^x_") and self[k:gsub("^x_", "")] then
        v.auto = self[k:gsub("^x_", "")].auto or v.auto
        if v.auto and v.auto.fire_rate then
          BotWeapons:log("Change " .. k .. " usage from \"" .. v.usage .. "\" to \"akimbo_auto\"", v.usage ~= "akimbo_auto")
          v.usage = "akimbo_auto"
        end 
      end
      -- fix shotguns
      if v.is_shotgun and v.usage ~= "r870" and v.usage ~= "mossberg" and v.usage ~= "saiga" then
        v.usage = "r870"
      end
    
      -- fix auto damage
      if v.auto and v.auto.fire_rate and not v.is_shotgun then
        if v.CLIP_AMMO_MAX >= 100 then
          BotWeapons:log("Change " .. k .. " usage from \"" .. v.usage .. "\" to \"lmg\"", v.usage ~= "lmg")
          v.usage = "lmg"
        elseif v.usage == "beretta92" or v.usage == "c45" then
          BotWeapons:log("Change " .. k .. " usage from \"" .. v.usage .. "\" to \"glock18\"", v.usage ~= "glock18")
          v.usage = "glock18"
        end
        v.DAMAGE = m4_dps * v.auto.fire_rate
      end
      -- fix pistol damage
      if v.usage == "beretta92" or v.usage == "c45" or v.usage == "raging_bull" then
        if v.CLIP_AMMO_MAX <= 6 then
          BotWeapons:log("Change " .. k .. " usage from \"" .. v.usage .. "\" to \"raging_bull\"", v.usage ~= "raging_bull")
          v.usage = "raging_bull"
        end
        v.DAMAGE = v.usage == "raging_bull" and 7 or 3
      end
      -- fix akimbo pistol damage
      if v.usage == "akimbo_pistol" then
        if self[k:gsub("^x_", "")] and (self[k:gsub("^x_", "")].CLIP_AMMO_MAX <= 6 or self[k:gsub("^x_", "")].usage == "raging_bull") then
          BotWeapons:log("Change " .. k .. " usage from \"" .. v.usage .. "\" to \"akimbo_deagle\"", v.usage ~= "akimbo_deagle")
          v.usage = "akimbo_deagle"
        end
        v.DAMAGE = v.usage == "akimbo_deagle" and 4 or 1.5
      end
      -- fix sniper damage
      if v.usage == "rifle" then
        v.DAMAGE = 15
      end
      -- fix shotgun damage
      if v.usage == "r870" then
        if v.CLIP_AMMO_MAX <= 2 or v.auto and v.auto.fire_rate and v.auto.fire_rate < 0.33 and v.is_shotgun then
          BotWeapons:log("Change " .. k .. " usage from \"" .. v.usage .. "\" to \"mossberg\"", v.usage ~= "mossberg")
          v.usage = "mossberg"
        else
          v.DAMAGE = 10
        end
      end
      -- fix auto shotgun damage
      if v.usage == "mossberg" then
        v.DAMAGE = v.CLIP_AMMO_MAX > 2 and 6 or 10
      end
      if v.usage == "saiga" then
        v.DAMAGE = 4
      end
      -- fix m14 damage
      if v.usage == "m14" then
        v.DAMAGE = 4
      end
      
    end
  end
end