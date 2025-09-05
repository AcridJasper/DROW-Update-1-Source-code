class KFProj_Rocket_PyrophobiaDROW extends KFProj_BallisticExplosive
	hidedropdown;

// var float FuseTime;

/** Speed when residual flames are dropped during projectile flight */
var vector SpeedDirectionResidualFlames;
// Amount of residual flames to drop during flight
// This is the max number, if the projectile is interrupted before reaching the max, the left residual numbers will NOT be spawned. This value can NOT be 0 or 1.
var int AmountResidualFlamesDuringFlight;
/** Time delay until starting to drop residual flames during flight (should NOT be greater than Lifespan)*/
var float TimeDelayStartDroppingResidualFlames;
/** Class for spawning residual flames **/
var class<KFProjectile> ResidualFlameProjClass;
/** (Computed) Time between residual flames drops */
var float IntervalDroppingResidualFlames;
/** Same as Lifespan (but using TimeAlive we assure projectile follows same flow as an explosion) */
var float TimeAlive;

// projectile spawning mid air
simulated function PostBeginPlay()
{
	//Subtract a bit (0.005) from TimeAlive to not match last cycle of the timer with time the projectile has to disappear (causing last flame not to drop then)
	//Subtract 1 from AmountResidualFlamesDuringFlight because the first flame will be spawned manually at the start of the timer.
	IntervalDroppingResidualFlames=((TimeAlive - 0.005) - TimeDelayStartDroppingResidualFlames)/(AmountResidualFlamesDuringFlight - 1);
	if (Instigator != none && Instigator.Role == ROLE_Authority)
	{
		SetTimer(TimeDelayStartDroppingResidualFlames, false, nameof(Timer_StartSpawningResidualFlamesDuringFlight));
	}
	SetTimer(TimeAlive, false, nameof(Timer_Shutdown));

	super.PostBeginPlay();

	// if (Role == ROLE_Authority)
	// {
	//    SetTimer(FuseTime, false, 'Timer_Detonate');
	// }
}

/*
// Set the initial velocity and cook time
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
	   SetTimer(FuseTime, false, 'Timer_Detonate');
	}

	AdjustCanDisintigrate();
}
*/

simulated function Init(vector Direction)
{
	super.Init(Direction);
	SpeedDirectionResidualFlames = Velocity/5;
}

// Timer to spawn residual flames while projectile is flying
simulated function Timer_SpawningResidualFlamesDuringFlight()
{
	SpawnResidualFlame(ResidualFlameProjClass, Location, SpeedDirectionResidualFlames);
}

// Timer to act as offset to start spawning residual flames during flight (in order to avoid dropping flames to close to player)
simulated function Timer_StartSpawningResidualFlamesDuringFlight()
{
	SpawnResidualFlame(ResidualFlameProjClass, Location, SpeedDirectionResidualFlames);
	SetTimer(IntervalDroppingResidualFlames, true, nameof(Timer_SpawningResidualFlamesDuringFlight));
}

// Timer until calling Shutdown
simulated function Timer_Shutdown()
{
	Shutdown();
}

simulated protected function StopSimulating()
{
	if (Instigator != none && Instigator.Role == ROLE_Authority)
	{
		ClearTimer(nameof(Timer_SpawningResidualFlamesDuringFlight));
		ClearTimer(nameof(Timer_StartSpawningResidualFlamesDuringFlight));
	}
	ClearTimer(nameof(Timer_Shutdown));

	super.StopSimulating();
}

/*
function Timer_Detonate()
{
	Detonate();
}

simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_Detonate) );
	}
}

function Detonate()
{
	local vector ExplosionNormal;

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}
*/

// Trace down and get the location to spawn the explosion effects and decal
simulated function GetExplodeEffectLocation(out vector HitLocation, out vector HitRotation, out Actor HitActor)
{
    local vector EffectStartTrace, EffectEndTrace;
	local TraceHitInfo HitInfo;

	EffectStartTrace = Location + vect(0,0,1) * 4.f;
	EffectEndTrace = EffectStartTrace - vect(0,0,1) * 32.f;

    // Find where to put the decal
	HitActor = Trace(HitLocation, HitRotation, EffectEndTrace, EffectStartTrace, false,, HitInfo, TRACEFLAG_Bullet);

	// If the locations are zero (probably because this exploded in the air) set defaults
    if (IsZero(HitLocation))
    {
        HitLocation = Location;
    }

	if (IsZero(HitRotation))
    {
        HitRotation = vect(0,0,1);
    }
}

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
    MaxSpeed=2500
	Speed=2500
	TerminalVelocity=2500
	TossZ=0
	GravityScale=1.0
    ArmDistSquared=0

	// FuseTime=5 //10

	TimeAlive=5.5
	LifeSpan=5.7
	TimeDelayStartDroppingResidualFlames=0.3 //0.005 //0.05
	ProjEffectsFadeOutDuration=5.0
	AmountResidualFlamesDuringFlight=12
	SpeedDirectionResidualFlames=(X=0,Y=0,Z=0)
	ResidualFlameProjClass=class'KFProj_Nova_PyrophobiaDROW'

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_Rocket_Projectile_Big_DROW'
	ProjFlightTemplateZedTime=ParticleSystem'DROW_EMIT.FX_Rocket_Projectile_Big_DROW'
	
	bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=4.f
		Radius=1500.f
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
		Damage=200 //90
		DamageRadius=600 //500
		DamageFalloffExponent=2  //3
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_PyrophobiaDROW'

		MomentumTransferScale=0 //50000
		// bIgnoreInstigator=true
		
		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_PyrophobiaDROW_ARCH.PyrophobiaDROW_Explosion'
		ExplosionSound=SoundCue'WEP_NorthFleetDROW_SND.supernova_explosion1_Cue'
		// ExplosionSound=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Explosion'

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