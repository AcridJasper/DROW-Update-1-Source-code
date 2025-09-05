class KFDT_Ballistic_EncoreImpact extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=2000
	KDeathUpKick=750
	KDeathVel=350

	KnockdownPower=55
	StumblePower=140
	GunHitPower=175

	WeaponDef=class'KFWeapDef_Encore'

	ModifierPerkList(0)=class'KFPerk_Survivalist'
}