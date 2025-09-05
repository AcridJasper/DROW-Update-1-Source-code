class KFDT_Ballistic_TKSWave extends KFDT_Ballistic_Shotgun
	abstract
	hidedropdown;

var ParticleSystem ForceImpactEffect;
var AkEvent ForceImpactSound;

static function PlayImpactHitEffects( KFPawn P, vector HitLocation, vector HitDirection, byte HitZoneIndex, optional Pawn HitInstigator )
{
	local KFSkinTypeEffects SkinType;

	if ( P.CharacterArch != None && default.EffectGroup < FXG_Max )
	{
		SkinType = P.GetHitZoneSkinTypeEffects( HitZoneIndex );

		if (SkinType != none)
		{
			SkinType.PlayImpactParticleEffect(P, HitLocation, HitDirection, HitZoneIndex, default.EffectGroup, default.ForceImpactEffect);
			SkinType.PlayTakeHitSound(P, HitLocation, HitInstigator, default.EffectGroup, default.ForceImpactSound);
		}
	}
}

/** Allows the damage type to customize exactly which hit zones it can dismember */
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

	KDamageImpulse=3500
	KDeathUpKick=800 //600
	KDeathVel=650 //450
	//KDamageImpulse=160 //600 //350
	GibImpulseScale=1.0
	//KDeathUpKick=250 //350
	//KDeathVel=15 //20 

    StumblePower=35  //8
	GunHitPower=45
	
	ForceImpactEffect=ParticleSystem'DROW_EMIT.FX_TKSWave_Impact_Zed'
	ForceImpactSound=AkEvent'WW_WEP_HVStormCannon.Play_WEP_HVStormCannon_Impact'

	WeaponDef=class'KFWeapDef_TKSWave'
	ModifierPerkList(0)=class'KFPerk_Support'
}