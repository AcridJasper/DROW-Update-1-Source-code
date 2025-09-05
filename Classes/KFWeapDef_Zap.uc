class KFWeapDef_Zap extends KFWeaponDefinition
	abstract;

const META_DECOMPILER_VAR_AUTHOR = "Jasper";
const META_DECOMPILER_VAR_COPYRIGHT = "steamcommunity.com/sharedfiles/filedetails/?id=3433020997";
const META_DECOMPILER_EVENT_ONLOAD_MESSAGE = "Can you like... not browse through my files, ok cheers";

DefaultProperties
{
	WeaponClassPath="DROW.KFWeap_Zap"
    ImagePath="WEP_Zap_MAT.UI_WeaponSelect_Zap"

	BuyPrice=1500 //1000
	AmmoPricePerMag=40

	EffectiveRange=70

	UpgradePrice[0]=700
	UpgradePrice[1]=1500

	UpgradeSellPrice[0]=525
	UpgradeSellPrice[1]=1650
}