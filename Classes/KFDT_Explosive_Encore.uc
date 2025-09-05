class KFDT_Explosive_Encore extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=2000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	KnockdownPower=50
	StumblePower=200

	ModifierPerkList(0)=class'KFPerk_Survivalist'
	WeaponDef=class'KFWeapDef_Encore'
}