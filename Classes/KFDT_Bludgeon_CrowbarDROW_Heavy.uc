class KFDT_Bludgeon_CrowbarDROW_Heavy extends KFDT_Bludgeon
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=1500
	KDeathUpKick=800
	KDeathVel=400

	KnockdownPower=0
	StunPower=100 //75
	StumblePower=120
	MeleeHitPower=120

	WeaponDef=class'KFWeapDef_CrowbarDROW'
	ModifierPerkList(0)=class'KFPerk_Berserker'
}