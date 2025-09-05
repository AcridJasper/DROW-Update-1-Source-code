class KFDT_Ballistic_SkyKiller extends KFDT_Ballistic_Rifle
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

    KnockdownPower=20
	StunPower=15 //40 //8
	StumblePower=0
	GunHitPower=90 //100

	WeaponDef=class'KFWeapDef_SkyKiller'
	ModifierPerkList(0)=class'KFPerk_Sharpshooter'
	ModifierPerkList(1)=class'KFPerk_Survivalist'
}