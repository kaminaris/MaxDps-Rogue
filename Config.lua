local _, addonTable = ...;
local StdUi = LibStub('StdUi');

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Rogue = addonTable.Rogue;

local defaultOptions = {
	outlawMarkedAsCooldown = false,
};

function Rogue:GetConfig()
	local config = {
		layoutConfig = { padding = { top = 30 } },
		database     = self.db,
		rows         = {
			[1] = {
				outlaw = {
					type = 'header',
					label = 'Outlaw options'
				}
			},
			[2] = {
				outlawMarkedAsCooldown = {
					type   = 'checkbox',
					label  = 'Marked for Death as cooldown',
					column = 12
				},
			},
		},
	};

	return config;
end


function Rogue:InitializeDatabase()
	if self.db then return end;

	if not MaxDpsRogueOptions then
		MaxDpsRogueOptions = defaultOptions;
	end

	self.db = MaxDpsRogueOptions;
end

function Rogue:CreateConfig()
	if self.optionsFrame then
		return;
	end

	local optionsFrame = StdUi:PanelWithTitle(nil, 100, 100, 'Rogue Options');
	self.optionsFrame = optionsFrame;
	optionsFrame:Hide();
	optionsFrame.name = 'Rogue';
	optionsFrame.parent = 'MaxDps';

	StdUi:BuildWindow(self.optionsFrame, self:GetConfig());

	StdUi:EasyLayout(optionsFrame, { padding = { top = 40 } });

	optionsFrame:SetScript('OnShow', function(of)
		of:DoLayout();
	end);

	InterfaceOptions_AddCategory(optionsFrame);
	InterfaceCategoryList_Update();
	InterfaceOptionsOptionsFrame_RefreshCategories();
	InterfaceAddOnsList_Update();
end