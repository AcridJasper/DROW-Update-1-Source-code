class KFProj_Rocket_NukemDROW extends KFProj_BallisticExplosive;

/*
// Explosion actor class to use for ground fire
var const protected class<KFExplosionActorLingering> GroundFireExplosionActorClass;
// Explosion template to use for ground fire
var KFGameExplosion GroundFireExplosionTemplate;

// How long the ground fire should stick around
var const protected float BurnDuration;
// How often, in seconds, we should apply burn
var const protected float BurnDamageInterval;

var bool bSpawnGroundFire;
var bool bAltGroundFire;
var KFImpactEffectInfo AltGroundFire;

replication
{
	if (bNetInitial)
		bSpawnGroundFire;
}

simulated function PostBeginPlay()
{
	local KFWeap_NukemDROW Cannon;
	local KFPlayerReplicationInfo InstigatorPRI;

	if(Role == ROLE_Authority)
	{
		Cannon = KFWeap_NukemDROW(Owner);
		if (Cannon != none)
		{
			bSpawnGroundFire = true;
		}
	}

	if(Instigator != none)
	{
		if (AltGroundFire != none)
		{
			InstigatorPRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);
			if (InstigatorPRI != none)
			{
				bAltGroundFire = InstigatorPRI.bSplashActive;
			}
		}
		else
		{
			bAltGroundFire = false;
		}
	}

	Super.PostBeginPlay();
}

simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFExplosionActorLingering GFExplosionActor;
	local vector GroundExplosionHitNormal;

	if (bHasDisintegrated)
	{
		return;
	}

	if (!bHasExploded && bSpawnGroundFire)
	{
		if (bAltGroundFire && AltGroundFire != none)
		{
			GroundFireExplosionTemplate.ExplosionEffects = AltGroundFire;
		}

		GroundExplosionHitNormal = HitNormal;

		// Spawn our explosion and set up its parameters
		GFExplosionActor = Spawn(GroundFireExplosionActorClass, self, , HitLocation + (HitNormal * 32.f), rotator(HitNormal));
		if (GFExplosionActor != None)
		{
			GFExplosionActor.Instigator = Instigator;
			GFExplosionActor.InstigatorController = InstigatorController;

			// These are needed for the decal tracing later in GameExplosionActor.Explode()
			GroundFireExplosionTemplate.HitLocation = HitLocation;
			GroundFireExplosionTemplate.HitNormal = GroundExplosionHitNormal;

			// Apply explosion direction
			if (GroundFireExplosionTemplate.bDirectionalExplosion)
			{
				GroundExplosionHitNormal = GetExplosionDirection(GroundExplosionHitNormal);
			}

			// Set our duration
			GFExplosionActor.MaxTime = BurnDuration;
			// Set our burn interval
			GFExplosionActor.Interval = BurnDamageInterval;
			// Boom
			GFExplosionActor.Explode(GroundFireExplosionTemplate, GroundExplosionHitNormal);
		}
	}

	super.TriggerExplosion(HitLocation, HitNormal, HitActor);
}
*/

/*
// Overridden to adjust particle system for different surface orientations (wall, ceiling) and nudge location
simulated protected function PrepareExplosionActor(GameExplosionActor GEA)
{
	local KFExplosion_NukemDROW_GroundFire KFEM;
	local vector ExplosionDir;

	super.PrepareExplosionActor( GEA );

	// KFProjectile::Explode gives GEA a "nudged" location of 32 units, but it's too much, so use a smaller nudge
	GEA.SetLocation( Location + vector(GEA.Rotation) * 10 );

	KFEM = KFExplosion_NukemDROW_GroundFire( GEA );
	if( KFEM != none )
	{
		ExplosionDir = vector( KFEM.Rotation );

		if( ExplosionDir.Z < -0.95 )
		{
			// ceiling
			KFEM.LoopingParticleEffect = KFEM.default.LoopingParticleEffectCeiling;
		}
		else if( ExplosionDir.Z < 0.05 )
		{
			// wall
			KFEM.LoopingParticleEffect = KFEM.default.LoopingParticleEffectWall;
		}
		// else floor
	}
}
*/

/*
// Touching
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	if (ClassIsChildOf(Other.class, class'KFPawn'))
	{
		bSpawnGroundFire = false;
	}

	super.ProcessTouch(Other, HitLocation, HitNormal);
}
*/

simulated event Tick( float DeltaTime )
{
	super.Tick( DeltaTime );

	if( !bHasExploded && Physics == PHYS_Falling )
	{
		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}
}

// simulated function bool AllowNuke()
// {
//     return false;
// }

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
	Physics=PHYS_Falling
    MaxSpeed=2800 //2600
	Speed=2800
	TerminalVelocity=2800
	TossZ=150
	GravityScale=1.0
    ArmDistSquared=0

	// Ground fire
	// BurnDuration=6.f
	// BurnDamageInterval=1.0f //0.5f
	// GroundFireExplosionActorClass=class'KFExplosion_NukemDROW_GroundFire'
	// AltGroundFire=KFImpactEffectInfo'WEP_NukemDROW_ARCH.NukemDROW_GroundFire_Alt'

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_Rocket_Projectile_Big_DROW'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_Rocket_Projectile_Big_DROW'
	
	bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=2500.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// explosion (causes DoT)
	Begin Object Class=KFGameExplosion Name=ExploTemplate0
		Damage=700 //800 900
		DamageRadius=1100 //950
		DamageFalloffExponent=2  //3
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_NukemDROW'

		MomentumTransferScale=50000
		// bIgnoreInstigator=true
		
		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_NukemDROW_ARCH.NukemDROW_Explosion'
		ExplosionSound=AkEvent'WW_ENV_Outpost.Play_Outpost_OBJ_EndCinematic_EXP_Large'

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

/*
	// Ground fire light
	Begin Object Class=PointLightComponent Name=FlamePointLight
		LightColor=(R=245,G=190,B=140,A=255)
		Brightness=4.f
		Radius=500.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		bEnabled=FALSE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object

	// ground fire (causes DoT if zed is in radius)
	Begin Object Class=KFGameExplosion Name=ExploTemplate1
		Damage=30 //10
		DamageRadius=600
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Fire_DoT_NukemDROW'

		// Don't burn the guy that tossed it, it's just too much damage with multiple fires, its almost guaranteed to kill the guy that tossed it
        bIgnoreInstigator=true
		MomentumTransferScale=1

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=0
		ExplosionEffects=KFImpactEffectInfo'wep_molotov_arch.Molotov_GroundFire'

		// bDirectionalExplosion=true

		// Dynamic Light
        ExploLight=FlamePointLight
        ExploLightStartFadeOutTime=1.5f
        ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=none
	End Object
	GroundFireExplosionTemplate=ExploTemplate1
*/

}