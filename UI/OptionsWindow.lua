BamModClassic_OptionsWindow = CreateFrame("Frame", "BamModClassic Options", UIParent)

function BamModClassic_OptionsWindow:Initialize()
  self.Header = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Header:SetPoint("TOPLEFT", 10, -10)
  self.Header:SetText("BÄM Mod Classic Options")
  
  self.cbEnableBamMod = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbEnableBamMod:SetPoint("LEFT", self, "TOPLEFT", 15, -50)
  self.fsEnableBamMod = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsEnableBamMod:SetPoint("LEFT", self, "TOPLEFT", 45, -50)
  self.fsEnableBamMod:SetText("Enable BÄM Mod announcing critical hits.")
  
  self:LoadOptions()
end

function BamModClassic_OptionsWindow:LoadOptions()
  self.cbEnableBamMod:SetChecked(BamModClassic_Config["EnableBamMod"])
end

function BamModClassic_OptionsWindow:SaveOptions()
  BamModClassic_Config["EnableBamMod"] = self.cbEnableBamMod:GetChecked()
end

BamModClassic_OptionsWindow.name = "BÄM Mod Classic"
BamModClassic_OptionsWindow.cancel = function() BamModClassic_OptionsWindow:LoadOptions() end
BamModClassic_OptionsWindow.default = function() print("Not implemented.") end
BamModClassic_OptionsWindow.okay = function() BamModClassic_OptionsWindow:SaveOptions() end
InterfaceOptions_AddCategory(BamModClassic_OptionsWindow)
