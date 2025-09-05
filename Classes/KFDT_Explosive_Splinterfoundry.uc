class KFDT_Explosive_Splinterfoundry extends KFDT_Explosive
	abstract
	hidedropdown;

defaultproperties
{
	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=3000 //5000 //20000
	GibImpulseScale=0.15
	KDeathUpKick=1000
	KDeathVel=300

	StunPower=200
	StumblePower=50

	ModifierPerkList(0)=class'KFPerk_Support'	
	WeaponDef=class'KFWeapDef_Splinterfoundry'
}