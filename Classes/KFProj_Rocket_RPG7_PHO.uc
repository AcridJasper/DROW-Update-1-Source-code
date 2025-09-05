class KFProj_Rocket_RPG7_PHO extends KFProj_BallisticExplosive;

// Our intended target actor
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
	if( bNetInitial )
		LockedTarget;
}

function SetLockedTarget( KFPawn NewTarget )
{
	LockedTarget = NewTarget;
}

simulated event Tick( float DeltaTime )
{
	local vector TargetImpactPos, DirToTarget;

	super.Tick( DeltaTime );

	// Skip the first frame, then start seeking
	if( !bHasExploded
		&& LockedTarget != none
		&& Physics == PHYS_Projectile
		&& Velocity != vect(0,0,0)
		&& LockedTarget.IsAliveAndWell()
		&& `TimeSince(CreationTime) > 0.15f ) //0.03
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_RPG7_PHO'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

defaultproperties
{
	Physics=PHYS_Projectile
	Speed=6000 //8500
	MaxSpeed=6000
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=50000.0
    ArmDistSquared=150000 // 4 meters
	
    SeekStrength=90000.0f  // 228000.0f

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_Rocket7_Projectile_DROW'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_Rocket7_Projectile_DROW'
	ProjDudTemplate=ParticleSystem'WEP_RPG7_EMIT.FX_RPG7_Projectile_Dud'
	GrenadeBounceEffectInfo=KFImpactEffectInfo'WEP_RPG7_ARCH.RPG7_Projectile_Impacts'
    ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	AmbientSoundPlayEvent=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Projectile_Loop'
  	AmbientSoundStopEvent=AkEvent'WW_WEP_SA_RPG7.Stop_WEP_SA_RPG7_Projectile_Loop'

  	AltExploEffects=KFImpactEffectInfo'WEP_RPG7_ARCH.RPG7_Explosion_Concussive_Force'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=2000.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=800 //750
		DamageRadius=700 //400
		DamageFalloffExponent=2 //3
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_RPG7'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_RPG7_ARCH.RPG7_Explosion'
		ExplosionSound=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=200
		CamShakeOuterRadius=900
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}