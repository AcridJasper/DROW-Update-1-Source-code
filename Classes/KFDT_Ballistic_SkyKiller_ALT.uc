class KFDT_Ballistic_SkyKiller_ALT extends KFDT_Ballistic_Rifle
	abstract
	hidedropdown;

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
	KDamageImpulse=2250
	KDeathUpKick=-400
	KDeathVel=250

    KnockdownPower=5
	StunPower=20
	StumblePower=20
	GunHitPower=125

	WeaponDef=class'KFWeapDef_SkyKiller'
	ModifierPerkList(0)=class'KFPerk_Sharpshooter'
}