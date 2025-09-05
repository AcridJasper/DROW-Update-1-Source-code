class KFDT_Explosive_Netscape extends KFDT_Explosive
	abstract
	hidedropdown;

// Damage type to use for the damage over time effect
var class<KFDamageType> DoTDamageType;

/** Called when damage is dealt to apply additional damage type (e.g. Damage Over Time) */
static function ApplySecondaryDamage(KFPawn Victim, int DamageTaken, optional Controller InstigatedBy)
{
    if (Victim.Controller == InstigatedBy)
	{
        return;
	}

	if (default.DoTDamageType.default.DoT_Type != DOT_None)
	{
		Victim.ApplyDamageOverTime(DamageTaken, InstigatedBy, default.DoTDamageType);
	}
}

defaultproperties
{
	ObliterationHealthThreshold=-500
	ObliterationDamageThreshold=500

	bShouldSpawnPersistentBlood=true

	// physics impact
	RadialDamageImpulse=2500//10000
	GibImpulseScale=0.15
	KDeathUpKick=1500//2000
	KDeathVel=500

	KnockdownPower=5
	StumblePower=25

    DoTDamageType=class'KFDT_Bleeding_DoT_Netscape_Explosive'

	ModifierPerkList(0)=class'KFPerk_Commando'
	ModifierPerkList(1)=class'KFPerk_Swat'
	
	WeaponDef=class'KFWeapDef_Netscape'
}