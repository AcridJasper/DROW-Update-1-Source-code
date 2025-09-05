class KFProj_Rocket_GalvanizedCypressThree extends KFProj_BallisticExplosive
	hidedropdown;

// Last hit normal from Touch() or HitWall()
// var vector LastHitNormal;

/*
// (Computed) Last Velocity from Explode()
var vector LastVelocity;
// Residual / splash flame chance
var float ResidualFlameChance;
// Number of lingering flames to spawn when projectile hits environment or a pawn before reaching max
var() int AmountResidualFlamesInExplosion;
// Magnitude to multiply velocity computed for residual flames in explosion
var float MagnitudeVelocityResidualFlamesInExplosion;
// Offset added to the final velocity computed for residual flames in explosion
var vector OffsetVelocityInExplosion;
// Class for spawning residual flames 
var class<KFProjectile> ResidualFlameProjClass;

// Cone Angle to determine residual flame directions
var float ResidualFlameHalfConeAngle;
// Impulse modiffier apply to residual forces
var float ResidualFlameForceMultiplier;
*/

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
		&& `TimeSince(CreationTime) > 0.06f ) //0.03
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_GalvanizedCypressThree'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

/*
// Destory this Projectile
// simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
// {
// 	LastVelocity = Velocity;
// 	Super.ProcessTouch(Other, HitLocation, HitNormal);
// }

simulated function Explode (vector HitLocation, vector HitNormal)
{
	LastVelocity = Velocity;
	super.Explode (HitLocation, HitNormal);
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local bool bDoExplosion;

    // Spawn projectiles
    if(Role < Role_Authority)
    {
        return;
    }

	if (bHasDisintegrated)
	{
		return;
	}

	bDoExplosion = !bHasExploded && Instigator.Role == ROLE_Authority;

	if (bDoExplosion && Physics == PHYS_Projectile && FRand() < ResidualFlameChance)
	{
		SpawnResidualFlames(HitLocation, HitNormal, LastVelocity);
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}

function SpawnResidualFlames(vector HitLocation, vector HitNormal, vector HitVelocity)
{
	local int i;
	local vector HitVelDir;
	local float HitVelMag;
	local vector SpawnLoc, SpawnVel;

	HitVelMag = VSize( HitVelocity );
	HitVelDir = Normal( HitVelocity );

	SpawnLoc = HitLocation + (HitNormal * 10.f);

	for( i = 0; i < AmountResidualFlamesInExplosion; ++i )
	{
		SpawnVel = CalculateResidualFlameVelocity( HitNormal, HitVelDir, HitVelMag );
		SpawnVel = SpawnVel + OffsetVelocityInExplosion;
		SpawnResidualFlame( ResidualFlameProjClass, SpawnLoc, SpawnVel );
	}
}
*/

/*
simulated protected function StopSimulating()
{
	local vector HitVelDir;
	local float HitVelMag;
	local vector SpawnLoc, FlameSpawnVel;

	HitVelMag = VSize (Velocity)*MagnitudeVelocityResidualFlamesInExplosion;
	HitVelDir = Normal (Velocity);

	SpawnLoc = HitLocation + (HitNormal * 10.f);

	// Can use physics mode as a way of doing this only once
	for( i = 0; i < AmountResidualFlamesInExplosion; ++i && Role == ROLE_Authority && Physics == PHYS_Projectile && FRand() < ResidualFlameChance )
	{
		// FlameSpawnVel = 0.25f * CalculateResidualFlameVelocity( LastHitNormal, Normal( Velocity ), VSize( Velocity ) );
		// SpawnResidualFlame( class'KFProj_Orb_GalvanizedCypressThree', Location + (LastHitNormal * 10.f), FlameSpawnVel );
		// FlameSpawnVel = CalculateResidualFlameVelocity( LastHitNormal, Normal( Velocity ), VSize( Velocity ) );
		
		SpawnVel = CalculateResidualFlameVelocity( HitNormal, HitVelDir, HitVelMag);
		FlameSpawnVel = FlameSpawnVel + OffsetVelocityInExplosion;
		SpawnResidualFlame( ResidualFlameProjClass, SpawnLoc, FlameSpawnVel );
	}

	Super.StopSimulating();
}
*/

// function vector CalculateResidualFlameVelocity( vector HitNormal, vector HitVelDir, float HitVelMag )
// {
//     local vector SpawnDir;

//     // apply some spread
//     SpawnDir = VRandCone( HitNormal, ResidualFlameHalfConeAngle * DegToRad );

//     return SpawnDir * ResidualFlameForceMultiplier;
// }

/*
simulated function SyncOriginalLocation()
{
	local Actor HitActor;
	local vector HitLocation, HitNormal;
	local TraceHitInfo HitInfo;

	if (Role < ROLE_Authority && Instigator != none && Instigator.IsLocallyControlled())
	{
		HitActor = Trace(HitLocation, HitNormal, OriginalLocation, Location,,, HitInfo, TRACEFLAG_Bullet);
		if (HitActor != none)
		{
			Explode(HitLocation, HitNormal);
		}
	}

    Super.SyncOriginalLocation();
}
*/

simulated function bool AllowNuke()
{
    return false;
}

/*
simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}
*/

defaultproperties
{
	Physics=PHYS_Projectile
	MaxSpeed=6000 //4000
	Speed=6000
	TerminalVelocity=6000
	TossZ=150
   	GravityScale=0.0
    ArmDistSquared=0

    SeekStrength=85000.0f //228000.0f

	bWarnAIWhenFired=true

	// ResidualFlameChance=0.1 //0.33
	// AmountResidualFlamesInExplosion=3
	// MagnitudeVelocityResidualFlamesInExplosion=1 //0.5 25
	// ResidualFlameHalfConeAngle=35
	// ResidualFlameForceMultiplier=500f;
	// OffsetVelocityInExplosion=(X=0,Y=0,Z=600) //1000
	// ResidualFlameProjClass=class'KFProj_Orb_GalvanizedCypressThree'

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_GalvanizedCypressThree_Rocket'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_GalvanizedCypressThree_Rocket'

   	bCanDisintegrate=true
	ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	AmbientSoundPlayEvent=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Rocket_LP'
  	AmbientSoundStopEvent=AkEvent'WW_WEP_ZEDMKIII.Stop_WEP_ZEDMKIII_Rocket_LP'
  	
	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=1000.f
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
		Damage=60 //80 //140
      	DamageRadius=300 //350
		DamageFalloffExponent=2.5f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_GalvanizedCypressThree'

		MomentumTransferScale=10000
		// bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_ZEDMKIII_ARCH.FX_ZEDMKIII_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

      	// Dynamic Light
      	ExploLight=ExplosionPointLight
      	ExploLightStartFadeOutTime=0.0
      	ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=400
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}