return(function(Installer)
  local _ENV = (getgenv or getrenv or getfenv)()

  local Settings = Installer.Settings

  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  local VirtualInputManager = game:GetService("VirtualInputManager")
  local VirtualUser = game:GetService("VirtualUser")
  local RunService = game:GetService("RunService")
  local Players = game:GetService("Players")

  local LocalPlayer = Players.LocalPlayer

  local MonsterSpawn = ReplicatedStorage:WaitForChild("MonsterSpawn")
  local ModuleScript = ReplicatedStorage:WaitForChild("ModuleScript")
  local OtherEvent = ReplicatedStorage:WaitForChild("OtherEvent")
  local Monster = workspace:WaitForChild("Monster")

  local Quest_Settings = require(ModuleScript:WaitForChild("Quest_Settings"))
  local Setting = require(ModuleScript:WaitForChild("Setting"))

  local Character = workspace:WaitForChild("Character")
  local NPCs = workspace:WaitForChild("NPCs")
  local Raids = workspace:WaitForChild("Raids")
  local Location = workspace:WaitForChild("Location")

  local EnemyLocation = Location:WaitForChild("Enemy_Location")
  local QuestLocation = Location:WaitForChild("QuestLocaion")

  local PlayerSpecial = LocalPlayer:WaitForChild("PlayerSpecial")
  local Cooldown = LocalPlayer:WaitForChild("Cooldown")
  local Items = LocalPlayer:WaitForChild("Items")
  local Ability = LocalPlayer:WaitForChild("Ability")
  local PlayerData = LocalPlayer:WaitForChild("PlayerData")
  local Level = PlayerData:WaitForChild("Level")

  local sethiddenproperty = sethiddenproperty or (function() end)

  local Insert = table.insert
  local Spawn = task.spawn
  local Wait = task.wait
  local Huge = math.huge

  local SkillDatabase = {}

  local Module = {} do
    Module.__index = Module

    Module.MaxLevel = Setting.Setting.MaxLevel
    Module.PassesPrice = Setting.Setting.Gamepasses_Cost
    Module.BL_Spawns = Setting.Setting.IgnoreSpawnPoints
    Module.PassesId = {}

    Module.WeaponList = {"Fight", "Power", "Weapon"}

    Module.Shop = {
      {"Weapons", {
        {"Katana", "$5.000 Money", {"Weapon_Seller", "Doge"}},
        {"Hanger", "$25.000 Money", {"Weapon_Seller", "Hanger"}},
        {"Flame Katana", "1x Cheems Cola and $50.000", {"Weapon_Seller", "Cheems"}},
        {"Banana", "1x Cat Food and $350.000", {"Weapon_Seller", "Smiling Cat"}},
        {"Bonk", "5x Money Bags and $1.000.000", {"Weapon_Seller", "Meme Man"}},
        {"Pumpkin", "1x Nugget Man and $3.500.000", {"Weapon_Seller", "Gravestone"}},
        {"Popcat", "10.000 Pops Clicker", {"Weapon_Seller", "Ohio Popcat"}}
      }},
      {"Ability", {
        {"Flash Step", "$100.000 Money", {"Ability_Teacher", "Giga Chad"}},
        {"Instinct", "$2.500.000 Money", {"Ability_Teacher", "Nugget Man"}},
        {"Aura", "1x Meme Cube and $10.000.000", {"Ability_Teacher", "Aura Master"}}
      }},
      {"Fighting Style", {
        {"Combat", "$0 Money", {"FightingStyle_Teacher", "Maxwell"}},
        {"Baller", "10x Balls and $10.000.000", {"FightingStyle_Teacher", "Baller"}}
      }}
    }

    function Module:IsAlive(Char)
      local Hum = Char and Char:FindFirstChild("Humanoid")

      return Hum and Hum.Health > 0
    end

    function Module:GetEnemy(EnName)
      if EnName then
        local Enemy = Monster:FindFirstChild(EnName) or MonsterSpawn:FindFirstChild(EnName)

        if self:IsAlive(Enemy) then
          return Enemy
        end
      end

      for _, Enemy in ipairs(Monster:GetChildren()) do
        if (not EnName or Enemy.Name == EnName) and self:IsAlive(Enemy) then
          return Enemy
        end
      end

      return false
    end

    function Module:GoTo(CFrame, Move)
      local Char = LocalPlayer.Character

      return self:IsAlive(Char) and (Move and Char:MoveTo(CFrame.p) or Char:SetPrimaryPartCFrame(CFrame))
    end

    function Module:PlayerClick()
      local Character = LocalPlayer.Character

      if Character then
        if Settings.AutoHaki and not Character:GetAttribute("Using_Aura") and self:AbilityUnlocked("Aura") then
          OtherEvent.MainEvents.Ability:InvokeServer("Aura")
        end

        local Equipped = Character:FindFirstChildOfClass("Tool")

        if Equipped then
          Equipped.Enabled = true
          Equipped:Activate()
        end
      end
    end

    function Module:EquipWeapon()
      local Char, Tool = LocalPlayer.Character, Settings.ToolFarm

      if Tool and self:IsAlive(Char) then
        local charTool = Char:FindFirstChildOfClass("Tool")

        if not charTool or not charTool.ToolTip:find(Tool) then
          for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip:find(Tool) then
              _ENV.EquippedTool = v

              return Char.Humanoid:EquipTool(v)
            end
          end
        end
      end
    end

    function Module:BringMobsTo(EnName, CFrame, BAll)
      for _, Enemy in ipairs(Monster:GetChildren()) do
        if (BAll or Enemy.Name == EnName) and self:IsAlive(Enemy) then
          local PP, Hum = Enemy.PrimaryPart, Enemy.Humanoid

          if PP and (PP.Position - CFrame.p).Magnitude < 500 then
            Hum.WalkSpeed = 0
            Hum:ChangeState(14)

            PP.CFrame = CFrame
            PP.CanCollide = false
            PP.Size = Vector3.new(40, 40, 40)
          end
        end
      end

      return pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", Huge)
    end

    function Module:GetRaidEnemy()
      for _, Enemy in ipairs(Monster:GetChildren()) do
        if Enemy:GetAttribute("Raid_Enemy") and self:IsAlive(Enemy) then
          return Enemy
        end
      end
    end

    function Module:GetRaidMap()
      for _, Map in ipairs(Raids:GetChildren()) do
        if Map.Joiners:FindFirstChild(LocalPlayer.Name) then
          return Map
        end
      end
    end

    function Module:KillEnemy(EnName, ...)
      local Enemy = type(EnName) == "string" and self:GetEnemy(EnName) or EnName
      local PP = Enemy.PrimaryPart

      if PP then
        self:GoTo(PP.CFrame * Settings.FarmCFrame)
        self:EquipWeapon()
        self:UseSkills()

        if not Enemy:FindFirstChild("Reverse_Mark") then
          self:PlayerClick()
        end

        if Settings.BringMobs then
          self:BringMobsTo(EnName, PP.CFrame, ...)
        end

        return true
      end
    end

    function Module:AbilityUnlocked(Ablt)
      return Ability:FindFirstChild(Ablt) and Ability[Ablt].Value
    end

    function Module:CanUseSkill(key)
      for _, v in ipairs(Cooldown:GetChildren()) do
        if v.Name:find("_" .. key) then
          return false
        end
      end

      return true
    end

    function Module:UseSkills()
      if _ENV.AutoSkill then
        for key, Value in pairs(Settings.SkillsSelected) do
          if Value and not SkillDatabase[key] and self:CanUseSkill(key) then
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            VirtualInputManager:SendKeyEvent(false, key, false, game)

            Spawn(function()
              SkillDatabase[key] = true
              Wait(0.5)
              SkillDatabase[key] = false
            end)
          end
        end
      end
    end

    function Module:UnlockedGamepass(GaName)
      return PlayerSpecial[GaName].Value
    end

    function Module:GetNearestList(Distance)
      local List = {}

      for _, plr in ipairs(Players:GetPlayers()) do
        local Char = plr.Character

        if plr ~= LocalPlayer and self:IsAlive(Char) then
          local PP = Char.PrimaryPart

          if PP and LocalPlayer:DistanceFromCharacter(PP.Position) <= Distance then
            Insert(List, Char)
          end
        end
      end

      return List
    end

    Spawn(function()
      for _, Pass in ipairs(require(ModuleScript.Gamepass_Assets)) do
        Module.PassesId[Pass.Asset_Name] = Pass.GamepassId
      end
    end)

    Spawn(function()
      if _ENV.Loaded_HUN then
        return
      end

      _ENV.Loaded_HUN = true

      local Label = LocalPlayer.PlayerGui.MainGui.PlayerName

      local function Update()
        local LevelValue = Level.Value
        local IsMax = LevelValue >= Module.MaxLevel

        Label.Text = ("%s • Lv. %i%s"):format(
          "Anonymous",
          LevelValue,
          IsMax and " (Max)" or ""
        )
      end

      Label:GetPropertyChangedSignal("Text"):Connect(Update)
      Update()
    end)

    Spawn(function()
      if _ENV.Loaded_AimBot then
        return
      end

      _ENV.Loaded_AimBot = true

      local old

      old = hookmetamethod(game, "__namecall", function(self, ...)
        local Method = getnamecallmethod():lower()

        if Method == "fireserver" then
          local Remote = self.Name

          if Remote == "Server_Skills" and Module.AimBot then
            return Module:AimBot(old, self, ...)
          end
        end

        return old(self, ...)
      end)
    end)

    Spawn(function()
      if _ENV.Loaded_NPrf then
        return
      end

      _ENV.Loaded_NPrf = true

      RunService.Stepped:Connect(function()
        local Distance, Nearest = 1000, false

        if _ENV.AimBotPlayers then
          for _, Char in ipairs(Character:GetChildren()) do
            local PP = Char.PrimaryPart

            if Char ~= LocalPlayer.Character and PP and LocalPlayer:DistanceFromCharacter(PP.Position) < Distance then
              Distance, Nearest = LocalPlayer:DistanceFromCharacter(PP.Position), PP
            end
          end
        end

        _ENV.NearestPlayer = Nearest
      end)
    end)

    Spawn(function()
      if _ENV.Loaded_NoStun then
        return
      end

      _ENV.Loaded_NoStun = true

      local UpdateStun = function(Char)
        Char:WaitForChild("Stun"):GetPropertyChangedSignal("Value"):Connect(function()
          if _ENV.NoStun then
            Char.Stun.Value = 0
          end
        end)
      end

      LocalPlayer.CharacterAdded:Connect(UpdateStun)
      UpdateStun(LocalPlayer.Character)
    end)

    Module.Items = (function()
      local Items = {}

      Items.Inventory = LocalPlayer:WaitForChild("Items")
      Items.Folders = {}
      Items.Acessories = {"Nah, I'd Win.", "Sus Pals", "Noob Friend", "Pumpkin Head", "Moai Face", "Egg Doge", "Floppa Hat"}
      Items.Swords = {"Purple Katana", "Yellow Blade", "Popcat", "Pumpkin", "Floppa", "Portal", "Katana"}

      function Items:GetMaterial(MaName)
        return self.Folders.ItemStorage[MaName].Value
      end

      function Items:VerifySword(SwName)
        return self.Folders.Weapon[SwName].Value > 0
      end

      function Items:VerifyAccessory(AcName)
        return self.Folders.Accessory[AcName].Value > 0
      end

      function Items:VerifyFightStyle(FsName)
        return self.Folders.FightingStyle[FsName].Value == true
      end

      function Items:GetUnlocked()
        local Unlocked = {}

        for _, v in (self.Folders.Weapon:GetChildren()) do
          Unlocked[v.Name] = v.Value > 0 or false
        end

        for _, v in (self.Folders.Accessory:GetChildren()) do
          Unlocked[v.Name] = v.Value > 0 or false
        end

        return Unlocked
      end

      function Items:CanRerollAura()
        for _, Color in ipairs(self.Folders.AuraColor:GetChildren()) do
          if not Color.Value then
            return true
          end
        end

        return false
      end

      function Items:EquipSword()
        local Swords = self.Folders.Weapon

        for _, Sword in ipairs(self.Swords) do
          if Swords[Sword].Value > 0 then
            if PlayerData.SwordEquip.Value ~= Sword then
              OtherEvent.ItemEvents.UpdateInventory:InvokeServer("Weapon", {
                SelectedItem = Sword
              })
            end

            return
          end
        end
      end

      function Items:EquipAcessory()
        local Accessories = self.Folders.Accessory

        for _, Acessory in ipairs(self.Acessories) do
          if Accessories[Acessory].Value > 0 then
            if PlayerData.AccessoryEquip.Value ~= Acessory then
              OtherEvent.ItemEvents.UpdateInventory:InvokeServer("Accessory", {
                SelectedItem = Acessory
              })
            end

            return
          end
        end
      end

      for _, Folder in ipairs(Items.Inventory:GetChildren()) do
        Items.Folders[Folder.Name] = Folder
      end

      return Items
    end)()

    Module.Quests = (function()
      local Quests = {}

      Quests.QuestsList = {}
      Quests.QuestsNPCs = {}
      Quests.EnemyList = {}

      function Quests:UpdateQuestsList()
        table.clear(self.QuestsList)

        for Npc, Quest in pairs(Quest_Settings) do
          if QuestLocation:FindFirstChild(Npc) then
            Insert(self.QuestsList, {
              EnemyPos = EnemyLocation[Quest.Target].CFrame,
              QuestPos = QuestLocation[Npc].CFrame,
              SpecialQuest = Quest.Special_Quest,
              RaidBoss = Quest.Raid_Boss,
              Level = Quest.LevelNeed,
              Enemy = Quest.Target,
              NpcName = Npc
            })
          end
        end

        table.sort(self.QuestsList, function(a, b)
          return a.Level > b.Level
        end)

        for _, v in ipairs(self.QuestsList) do
          Insert(self.EnemyList, v.Enemy)
          self.QuestsNPCs[v.Enemy] = v.NpcName
        end
      end

      return Quests
    end)()
  end

  return Module
end)
