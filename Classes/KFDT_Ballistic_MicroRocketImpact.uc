class KFDT_Ballistic_MicroRocketImpact extends KFDT_Ballistic_Shell
	abstract
	hidedropdown;

defaultproperties
{
	KDamageImpulse=3000
	KDeathUpKick=1000
	KDeathVel=500

	KnockdownPower=40
	StumblePower=70
	GunHitPower=55

	// ModifierPerkList(0)=class'KFPerk_Demolitionist'
	// WeaponDef=class'KFWeapDef_Seeker6'
}