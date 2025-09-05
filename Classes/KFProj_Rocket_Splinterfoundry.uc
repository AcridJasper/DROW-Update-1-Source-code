class KFProj_Rocket_Splinterfoundry extends KFProj_BallisticExplosive;

var() float SecondsBeforeDetonation;

var float WaveRadius;
var protected transient bool bRadialBubble;

// Our intended target actor 
var private KFPawn LockedTarget;
// How much 'stickyness' when seeking toward our target. Determines how accurate rocket is
var const float SeekStrength;

replication
{
	if( bNetInitial )
		LockedTarget;
}

function Init(vector Direction)
{
    super.Init( Direction );
    
	bRadialBubble = true;
}

// Set the initial velocity and cook time
simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		SetTimer(SecondsBeforeDetonation, false, 'Timer_Detonate');
	}

	bRadialBubble = true;

	AdjustCanDisintigrate();
}

// Explode after a certain amount of time
function Timer_Detonate()
{
	Detonate();
}

// Called when the owning instigator controller has left a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_Detonate) );

		bRadialBubble = false;
	}
}

function Detonate()
{
	local vector ExplosionNormal;

	bRadialBubble = false;

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}

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

function SetLockedTarget( KFPawn NewTarget )
{
	LockedTarget = NewTarget;
}

simulated event Tick( float DeltaTime )
{
	local vector TargetImpactPos, DirToTarget;

	local KFPawn_Monster Victim;
	local TraceHitInfo   HitInfo;
	local float Radius;

	// super.Tick( DeltaTime );

	// Skip the first frame, then start seeking
	if( !bHasExploded
		&& LockedTarget != none
		&& Physics == PHYS_Projectile
		&& Velocity != vect(0,0,0)
		&& LockedTarget.IsAliveAndWell()
		&& `TimeSince(CreationTime) > 0.08f ) //0.03
	{
		// Grab our desired relative impact location from the weapon class
		TargetImpactPos = class'KFWeap_Splinterfoundry'.static.GetLockedTargetLoc( LockedTarget );

		// Seek towards target
		Speed = VSize( Velocity );
		DirToTarget = Normal( TargetImpactPos - Location );
		Velocity = Normal( Velocity + (DirToTarget * (SeekStrength * DeltaTime)) ) * Speed;

		// Aim rotation towards velocity every frame
		SetRotation( rotator(Velocity) );
	}

	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		if(bRadialBubble)
		{
			Radius = WaveRadius;
			// DrawDebugSphere(Location, Radius, 100, 255, 100, 0, false);
			foreach CollidingActors(class'KFPawn_Monster', Victim, Radius, Location, true,, HitInfo)
			{
				if(Victim.IsAliveAndWell())
				{
					Detonate();
				}
			}
		}
	}
}

simulated protected function StopFlightEffects()
{
	Super.StopFlightEffects();
	
	bRadialBubble = false;
}

simulated function bool AllowNuke()
{
    return false;
}

simulated protected function PrepareExplosionTemplate()
{
	super.PrepareExplosionTemplate();

	// Since bIgnoreInstigator is transient, its value must be defined here
	ExplosionTemplate.bIgnoreInstigator = true;
}

defaultproperties
{
	Physics=PHYS_Projectile
	MaxSpeed=6000 //4000
	Speed=6000
	TerminalVelocity=6000
	TossZ=0
   	GravityScale=1.0
    ArmDistSquared=0

	WaveRadius=150 //175
	bRadialBubble=false

	SecondsBeforeDetonation=0.5 //0.4
    SeekStrength=10000.0f  // 9500.0f

	bWarnAIWhenFired=true

	ProjFlightTemplate=ParticleSystem'WEP_ZEDMKIII_EMIT.FX_ZEDMKIII_Rocket'
	ProjFlightTemplateZedTime=ParticleSystem'WEP_ZEDMKIII_EMIT.FX_ZEDMKIII_Rocket_ZED_TIME'

   	// bCanDisintegrate=false
	ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

	AmbientSoundPlayEvent=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Rocket_LP'
  	AmbientSoundStopEvent=AkEvent'WW_WEP_ZEDMKIII.Stop_WEP_ZEDMKIII_Rocket_LP'
  	
	// Grenade explosion light
	Begin Object Class=PointLightComponent Name=ExplosionPointLight
	    LightColor=(R=252,G=218,B=171,A=255)
		Brightness=0.5f
		Radius=600.f
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
		Damage=45 //50
      	DamageRadius=800 //300
		DamageFalloffExponent=1.0f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Splinterfoundry'

		MomentumTransferScale=10000
		bIgnoreInstigator=true

		// Damage Effects
		KnockDownStrength=150
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionSound=AkEvent'WW_WEP_HRG_Stunner.Play_WEP_HRG_Stunner_Alt_Fire_Explosion'
		ExplosionEffects=KFImpactEffectInfo'WEP_Splinterfoundry_ARCH.WEB_SplinterFoundry_Explosion'

      	// Dynamic Light
      	ExploLight=ExplosionPointLight
      	ExploLightStartFadeOutTime=0.0
      	ExploLightFadeOutTime=0.3

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=300
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}