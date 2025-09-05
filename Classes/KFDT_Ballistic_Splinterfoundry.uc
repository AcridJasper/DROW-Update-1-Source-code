class KFDT_Ballistic_Splinterfoundry extends KFDT_Ballistic_Shotgun
	abstract
	hidedropdown;

// Allows the damage type to customize exactly which hit zones it can dismember
static simulated function bool CanDismemberHitZone( name InHitZoneName )
{
	if( super.CanDismemberHitZone( InHitZoneName ) )
	{
		return true;
	}

	switch ( InHitZoneName )
	{
		case 'lupperarm':
		case 'rupperarm':
		case 'chest':
		case 'heart':
	 		return true;
	}

	return false;
}

defaultproperties
{
	BloodSpread=0.4
	BloodScale=0.6

	KDamageImpulse=900
	KDeathUpKick=-500
	KDeathVel=350

    KnockdownPower=4
	StumblePower=12
	GunHitPower=18

	ModifierPerkList(0)=class'KFPerk_Support'
	WeaponDef=class'KFWeapDef_Splinterfoundry'
}