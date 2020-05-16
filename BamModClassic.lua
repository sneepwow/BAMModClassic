-- BÄM Mod Classic by Sneep <Goon Squad> Herod

BamModClassic_Config = nil

BamModClassic_CritRecord = nil

BamModClassic_Events = {
  EventHandlers = {}
}

local BAMColStr = "|cFFFFFF7FBÄM Mod Classic|r"
BamModClassic_SlashFunctions = {
  SlashFunctions = {},
  SlashHelp = {
    enable = {
      desc = "Enables " .. BAMColStr .. " crit announces.",
      help = "",
      data = nil,
      usage = ""
    },
    disable = {
      desc = "Disables " .. BAMColStr .. " crit announces.",
      help = "",
      data = nil,
      usage = ""
    },
    toggle = {
      desc = "Toggles on/off " .. BAMColStr .. " crit announces.",
      help = "",
      data = nil,
      usage = ""
    },
    message = {
      desc = "Sets the message to send on " .. BAMColStr .. " crit announces.",
      help = "Enter your entire message to send out on a crit. Use the {specifiers} from '|cFFFFFF7F/bam|r specifiers' to swap in data from the attack.",
      data = nil,
      usage = "..."
    },
    channel = {
      desc = "Sets channel to output BÄM Mod crit announces.",
      help = "A valid channel is either one of the following: SELF SAY YELL PARTY RAID or CHANNEL followed by the channel #.",
      data = nil,
      usage = "[SELF|SAY|YELL|PARTY|RAID|CHANNEL] [[Channel #]]"
    },
    specifiers = {
      desc = "Lists the string specifiers you can use in your \'|cFFFFFF7F/bam|r message\' string to swap in data from the attack.",
      help = "",
      data = nil,
      usage = ""
    },
    log = {
      desc = "Prints out the last [[num]] crit messages saved in the log.",
      help = "",
      data = nil,
      usage = "[[num]]"
    },
    help = {
      desc = "Gives more details on " .. BAMColStr .. " usage and slash commands.",
      help = "",
      data = nil,
      usage = ""
    },
  }
}

local BamModClassic_EventData = {
  timestamp = nil,
  target = nil,
  action = nil,
  amount = 0,
  zone = nil
}

local BamModClassic_DefaultConfig = {
  EnableBamMod = true,
  CritString = "BÄM!! [{action} - {amount}]",
  OutputChannel = "YELL",
  OutputChannelNumber = 1,
  MeleeReplaceString = "Melee"
}

local BamModClassic_CritRecord_DefaultConfig = {
  melee = {},
  ranged = {},
  spell = {},
  heal = {},
  pet = {}
}

local BamModClassic_OutputChannels = {
  "SAY",
  "YELL",
  "PARTY",
  "RAID"
}

local BamModClassic_MessageSpecifiers = {
  "{target}",
  "{action}",
  "{amount}", 
  "{overkill}", 
  "{school}", 
  "{resisted}", 
  "{blocked}", 
  "{absorbed}"
}

local BAMLog = {}
local BAMLogMaxCount = 50
local BAMEvents = BamModClassic_Events
local BAMSlash = BamModClassic_SlashFunctions
local playerGUID = UnitGUID("player")
local BAMDebugMode = false
local BAMMsgSpecifiers = {}
local BAMCritRecord_Current = {}

function copy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do res[copy(k)] = copy(v) end
  return res
end

function BAMGenerateMessage(...)
  local arg = {...}
  local generatedMsg = BamModClassic_Config["CritString"]
  -- Replace our message specifiers in our crit strig with our argument values
  for i = 1, #arg do
    local i1, i2 = generatedMsg:find(BamModClassic_MessageSpecifiers[i], nil, true)
    if not (i1 == nil and i2 == nil) then
      generatedMsg = generatedMsg:gsub(BamModClassic_MessageSpecifiers[i], arg[i])
    end
  end
  return generatedMsg
end

function BAMLogMessage(msg)
  hours,minutes = GetGameTime()
  if (#BAMLog == BAMLogMaxCount) then
    table.remove(BAMLog, 1)
  end
  local channel = BamModClassic_Config["OutputChannel"]
  if ("channel" == "CHANNEL") then
    channel = BamModClassic_Config["OutputChannelNumber"]
  end
  logMessage = "[" .. hours .. ":" .. minutes .. "][" .. channel .. "]: " .. msg
  if (BAMDebugMode == true) then
    print("BAM Mod Logging: " .. logMessage)
  end
  table.insert(BAMLog, logMessage)
end

function BAMParseMessageForSpecifiers(msg)
  local foundSpecifiers = {}
  for i = 1, #BamModClassic_MessageSpecifiers do
    table.insert(foundSpecifiers, "")
    local i1, i2 = msg:find(BamModClassic_MessageSpecifiers[i], nil, true)
    if not (i1 == nil and i2 == nil) then
      foundSpecifiers[i] = BamModClassic_MessageSpecifiers[i]
    end
  end
  --for i = 1, #foundSpecifiers do
    --print(i .. " " .. foundSpecifiers[i])
  --end
  return foundSpecifiers
end

function BAMFormatCritRecord(critData)
  if (critData == nil) then return nil end
  return "[" .. critData["timestamp"] .. "]: |cFFFF0000" .. critData["amount"] .. "|r crit with " .. critData["action"] .. " on " .. critData["target"] .. " in " .. critData["zone"]
end

function BAMFillEventData(data_table, timestamp, target, action, amount, zone)
  data_table["timestamp"] = timestamp
  data_table["target"] = target
  data_table["action"] = action
  data_table["amount"] = amount
  data_table["zone"] = zone
end

function BAMRecordCrit(critData, eventType)
  if (BamModClassic_CritRecord_DefaultConfig[eventType] == nil) then return end

  if (BamModClassic_CritRecord_DefaultConfig[eventType]["amount"] == nil or BamModClassic_CritRecord_DefaultConfig[eventType]["amount"] < critData["amount"]) then
    BamModClassic_CritRecord_DefaultConfig[eventType] = copy(critData)
    print(BAMColStr .. " |cFFFF0000NEW|r Crit Record!! [" .. string.upper(eventType) .. "] " .. BAMFormatCritRecord(critData)) 
  end 
end

function BAMEvents:OnEvent(_, event, ...)
  if self.EventHandlers[event] then
    self.EventHandlers[event](self, ...)
  end
end

function BAMEvents.EventHandlers.ADDON_LOADED(self, addonName, ...)
  if addonName ~= "BamModClassic" then return end

  -- Check if we already have a table saved globally
  if type(_G["BAMMODCLASSIC_CONFIG"]) ~= "table" then
    _G["BAMMODCLASSIC_CONFIG"] = copy(BamModClassic_DefaultConfig)
  end

  if type(_G["BAMMODCLASSIC_CRITRECORD"]) ~= "table" then
    _G["BAMMODCLASSIC_CRITRECORD"] = copy(BamModClassic_CritRecord_DefaultConfig)
  end

  BamModClassic_Config = _G["BAMMODCLASSIC_CONFIG"]
  BamModClassic_CritRecord = _G["BAMMODCLASSIC_CRITRECORD"]

  -- Add arguments from default config we're missing in our config
  for i,v in pairs(BamModClassic_DefaultConfig) do
    if BamModClassic_Config[i] == nil then
      BamModClassic_Config[i] = BamModClassic_DefaultConfig[i]
    end
  end

  for i,v in pairs(BamModClassic_CritRecord_DefaultConfig) do
    if BamModClassic_CritRecord[i] == nil then
      BamModClassic_CritRecord[i] = copy(BamModClassic_EventData)
    end
  end

  -- Remove arguments from our config that no longer exists in the default config
  for i,v in pairs(BamModClassic_Config) do
    if BamModClassic_DefaultConfig[i] == nil then
      BamModClassic_Config[i] = nil
    end
  end

  BAMCritRecord_Current = copy(BamModClassic_EventData)
  --BAMMsgSpecifiers = BAMParseMessageForSpecifiers(BamModClassic_Config["CritString"])
  BAMSetSlashCommandData()
  BamModClassic_OptionsWindow:Initialize()
end

function BAMEvents.EventHandlers.COMBAT_LOG_EVENT_UNFILTERED(self)
  if (BamModClassic_Config["EnableBamMod"] == true) then
    local timestamp, subevent, hideCaster, sourceGuid, sourceName, sourceFlags, sourceRaidFlags, destGuid, destName, destFlags, destRaidflags = CombatLogGetCurrentEventInfo()

    if (sourceGuid == playerGUID) then
      local spellId, spellName, spellSchool
      local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offhand

      if (subevent == "SWING_DAMAGE") then
        amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offhand = select(12, CombatLogGetCurrentEventInfo())
      elseif (subevent == "SPELL_DAMAGE" or subevent == "SPELL_HEAL" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE") then
        spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offhand = select(12, CombatLogGetCurrentEventInfo())
      end

      if (critical == true or BAMDebugMode == true) and (subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_HEAL" or subevent == "RANGE_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE") then
        local action = (spellName) or BamModClassic_Config["MeleeReplaceString"]
        chatMessage = BAMGenerateMessage(destName, action, amount, overkill, school, resisted, blocked, absorbed)
        if (BamModClassic_Config["OutputChannel"] == "SELF") then
          print(BAMColStr .. " Crit: " .. chatMessage)
        elseif (BamModClassic_Config["OutputChannel"] == "CHANNEL") then
          SendChatMessage(chatMessage, BamModClassic_Config["OutputChannel"], nil, BamModClassic_Config["OutputChannelNumber"])
        else
          --SendChatMessage(chatMessage, BamModClassic_Config["OutputChannel"], nil)
          BAMSlash.SlashFunctions.testmsg("")
        end
        BAMLogMessage(chatMessage)
        local ts = date('%Y-%m-%d %H:%M:%S')
        local event = ""
        if (subevent == "SWING_DAMAGE") then event = "melee"
        elseif (subevent == "RANGE_DAMAGE") then event = "ranged" 
        elseif (subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE") then event = "spell" action = '[' .. action .. ']'
        elseif (subevent == "SPELL_HEAL") then event = "heal" action = '[' .. action .. ']' end
        BAMFillEventData(BAMCritRecord_Current, ts, destName, action, amount, GetZoneText())
        BAMRecordCrit(BAMCritRecord_Current, event)
      end
    end
  end
end

-- elseif (sourceFlags == 0x00001111) or (sourceFlags == 0x00002111) then -- Check if source is our pet or minion

function BAMSlash.SlashFunctions.enable(splitCmds)
  print(BAMColStr .. " enabled")
  BamModClassic_Config["EnableBamMod"] = true
end

function BAMSlash.SlashFunctions.disable(splitCmds)
  print(BAMColStr .. " disabled")
  BamModClassic_Config["EnableBamMod"] = false
end

function BAMSlash.SlashFunctions.toggle(splitCmds)
  if (BamModClassic_Config["EnableBamMod"] == true) then
    BAMSlash.SlashFunctions.disable(splitCmds)
  else
    BAMSlash.SlashFunctions.enable(splitCmds)
  end
end

function BAMSlash.SlashFunctions.message(splitCmds)
  if (#splitCmds == 1) then
    print(BAMColStr .. " current crit message: " .. BamModClassic_Config["CritString"])
    return
  end

  local assembledString = ""
  for i,v in pairs(splitCmds) do
    if (i ~= 1) then
      assembledString = assembledString .. v .. " "
    end
  end
  assembledString = assembledString:sub(1, -2) -- Remove trailing space
  print("Setting " .. BAMColStr .. " crit announce message to \'" .. assembledString .. '\'')
  BamModClassic_Config["CritString"] = assembledString
  --BAMMsgSpecifiers = BAMParseMessageForSpecifiers(BamModClassic_Config["CritString"])
end

function BAMSlash.SlashFunctions.channel(splitCmds)
  local function BAMChannelError(error)
    print(BAMColStr .. " Error: " .. error)
    print("    /bam channel " .. BamModClassic_SlashFunctions.SlashHelp.channel.usage)
    print(BamModClassic_SlashFunctions.SlashHelp.channel.desc)
    print(BamModClassic_SlashFunctions.SlashHelp.channel.help)
  end
  if (#splitCmds < 2 or (splitCmds[2] == "channel" and #splitCmds < 3)) then
      BAMChannelError("missing channel argument")
    return
  end

  local channelStr = ""
  local channel = splitCmds[2]:upper()

  if (channel ~= "CHANNEL" and channel ~= "SELF" and channel ~= "SAY" and channel ~= "YELL" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "WHISPER") then
    return BAMChannelError("channel \'" .. channel .. "\' is not a valid option.")
  end

  BamModClassic_Config["OutputChannel"] = channel
  if (splitCmds[2] == "channel") then
    BamModClassic_Config["OutputChannelNumber"] = splitCmds[3]
    channelStr = splitCmds[3]
  end
  print(BAMColStr .. " output channel set to " .. BamModClassic_Config["OutputChannel"] .. " " .. channelStr)
end

function BAMSlash.SlashFunctions.specifiers(splitCmds)
  print("List of string specifiers: " .. BAMGetSpecifiers())
end

function BAMSlash.SlashFunctions.help(splitCmds)
  print(BAMColStr .. " list of slash commands:")
  for i, v in pairs(BamModClassic_SlashFunctions.SlashHelp) do
    print("  |cFFFFFF7F/bam|r " .. i .. " " .. v.usage .. "  " .. v.desc)
  end
end

function BAMSlash.SlashFunctions.debug(splitCmds)
  if (BAMDebugMode == true) then
    print(BAMColStr .. " debug mode off")
    BAMDebugMode = false
  else
    print(BAMColStr .. " debug mode on")
    BAMDebugMode = true
  end
end

function BAMSlash.SlashFunctions.log(splitCmds)
  local printCount = 0;
  local numToPrint = 5
  if (#splitCmds > 1) then
    numToPrint = tonumber(splitCmds[2])
    if not numToPrint then
      numToPrint = 5
    end
  end
  if (numToPrint > BAMLogMaxCount) then
    numToPrint = BAMLogMaxCount
  end
  if (numToPrint > #BAMLog) then
    numToPrint = #BAMLog
  end
  if (numToPrint == 0) then
    print(BAMColStr .. " Log: No entries in log to print.")
    return 
  end
  print(BAMColStr .. " Log [" .. numToPrint .. "]:")
  while (printCount <= numToPrint and printCount < BAMLogMaxCount and printCount < #BAMLog) do
    if (BAMLog[#BAMLog - printCount] ~= nil) then
      print("  " .. BAMLog[#BAMLog - printCount])
    end
    printCount = printCount + 1
  end
end

function BAMSlash.SlashFunctions.test(splitCmds)
  print(BAMColStr .. " Message test:")
  local bamMsg = BAMGenerateMessage("Sneep", "Melee", "250", "0", "Physical", "0", "0", "0")
  BAMLogMessage(bamMsg)
  print("[" .. BamModClassic_Config["OutputChannel"] .. "]: " .. bamMsg)
  BAMFillEventData(BAMCritRecord_Current, "2013-12-25 22:09:51", "Arthas", "Melee", 250, GetZoneText())
  BAMRecordCrit(BAMCritRecord_Current, "melee")
  BamModClassic_CritRecord_DefaultConfig["melee"]["amount"] = 1
end

function BAMSlash.SlashFunctions.testmsg(splitCmds)
  print(BAMColStr .. " test message:")
  local bamMsg = BAMGenerateMessage("Sneep", "Melee", "250", "0", "Physical", "0", "0", "0")
  SendChatMessage(bamMsg, "SAY", nil)
end

function BAMSlash.SlashFunctions.parse(splitCmds)
  print(BAMColStr .. " Parse test:")
  BAMMsgSpecifiers = BAMParseMessageForSpecifiers(BamModClassic_Config["CritString"])
end

-- Get Data String functions
function BAMGetToggle()
  if (BamModClassic_Config["EnableBamMod"] == true) then
    return "enabled"
  else
    return "disabled"
  end
end

function BAMGetChannel()
  if (BamModClassic_Config["OutputChannel"] == "CHANNEL") then
    return BamModClassic_Config["OutputChannelNumber"]
  else
    return BamModClassic_Config["OutputChannel"]
  end
end

function BAMGetMessage()
  return BamModClassic_Config["CritString"]
end

function BAMGetSpecifiers()
  specifierStr = ""
  for i, v in pairs(BamModClassic_MessageSpecifiers) do
    specifierStr = specifierStr .. v .. " "
  end
  return specifierStr
end

function BAMGetLogCount()
  return #BAMLog
end

function BAMSetSlashCommandData()
  BamModClassic_SlashFunctions.SlashHelp['toggle']['data'] = BAMGetToggle()
  BamModClassic_SlashFunctions.SlashHelp['channel']['data'] = BAMGetChannel()
  BamModClassic_SlashFunctions.SlashHelp['message']['data'] = BAMGetMessage()
  BamModClassic_SlashFunctions.SlashHelp['log']['data'] = BAMGetLogCount()
end

-- Register each event for which we have an event handler.
BAMEvents.Frame = CreateFrame("Frame")
for eventName,_ in pairs(BAMEvents.EventHandlers) do
  BAMEvents.Frame:RegisterEvent(eventName)
end
BAMEvents.Frame:SetScript("OnEvent", function(_, event, ...) BAMEvents:OnEvent(_, event, ...) end)

SLASH_BAM1 = "/bam"
SlashCmdList["BAM"] = function(inArgs)
  if (inArgs:len() ~= 0) then
    splitCmds = {}
    local subStrCount = 0
    local isMessageCommand = false
    -- Split commands by whitespace
    for substring in inArgs:gmatch("%S+") do
      if (subStrCount == 0) then
        if (substring:lower() == "message") then
          isMessageCommand = true
        end
      end

      -- Make every argument lowercase unless we're looking at a message command
      if (isMessageCommand == false and subStrCount > 0) then
        table.insert(splitCmds, substring:lower())
      else
        table.insert(splitCmds, substring)
      end
    end

    -- Call function that matches first argument and pass the split command arguments
    for i,v in pairs(splitCmds) do
      if (BAMSlash.SlashFunctions[v] ~= nil) then
        BAMSlash.SlashFunctions[v](splitCmds)
        return
      end
    end
    print("No command matches \'|cFFFFFF7F/bam|r " .. inArgs .. "\'")
  end
  print(BAMColStr .. " slash commands:")
  for i,v in pairs(BamModClassic_SlashFunctions.SlashHelp) do
    local slashCommandStr = "  |cFFFFFF7F/bam|r " .. i
    if (v["data"] ~= nil) then
      slashCommandStr = slashCommandStr .. " (|cFFFFFF7F" .. v["data"] .. "|r)"
    end
    slashCommandStr = slashCommandStr .. ": " .. v["desc"]
    print(slashCommandStr)
  end
end
