class KFDT_Bludgeon_CrowbarDROW_Light extends KFDT_Bludgeon
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=1250
	KDeathUpKick=500
	KDeathVel=250

	StunPower=45 //50 75
	StumblePower=80
	MeleeHitPower=80

	WeaponDef=class'KFWeapDef_CrowbarDROW'
	ModifierPerkList(0)=class'KFPerk_Berserker'	
}