class KFProj_Rocket_Zap extends KFProjectile; //KFProj_BallisticExplosive

var int MaxNumberOfZedsZapped;
var int MaxDistanceToBeZapped;
var float ZapInterval;
var int ZapDamage;
var float TimeToZap;

var ParticleSystem BeamPSCTemplate;
var ParticleSystem oPawnPSCEffect;

var string EmitterPoolClassPath;
var EmitterPool vBeamEffects;

struct BeamZapInfo
{
	var ParticleSystemComponent oBeam;
	var KFPawn_Monster oAttachedZed;
	var Actor oSourceActor;
	var float oControlTime;
};

var array<BeamZapInfo> CurrentZapBeams;

// var bool ImpactEffectTriggered;

var AkComponent ZapSFXComponent;
var() AkEvent ZapSFX;

var Controller oOriginalOwnerController;
var Pawn oOriginalInstigator;

// Fuze time when sticked
var() float SecondsBeforeDetonation;
var() bool bIsProjActive;

// Dynamic light for blinking
var PointLightComponent BlinkLightComp;

simulated event PreBeginPlay()
{
	local class<EmitterPool> PoolClass;
	
    super.PreBeginPlay();

    bIsAIProjectile = InstigatorController == none || !InstigatorController.bIsPlayer;
	oOriginalOwnerController = InstigatorController;
	oOriginalInstigator = Instigator;
	PoolClass = class<EmitterPool>(DynamicLoadObject(EmitterPoolClassPath, class'Class'));
	if (PoolClass != None)
	{
		vBeamEffects = Spawn(PoolClass, self,, vect(0,0,0), rot(0,0,0));
	}
}

simulated function NotifyStick()
{
    SetTimer(SecondsBeforeDetonation, false, nameof(Timer_Detonate));
}

function Timer_Detonate()
{
	Detonate();
}

// Called when the owning instigator controller has left a game
simulated function OnInstigatorControllerLeft()
{
	if( WorldInfo.NetMode != NM_Client )
	{
		SetTimer( 1.f + Rand(5) + fRand(), false, nameOf(Timer_Detonate) ); //Destory
	}
}

function Detonate()
{
	local vector ExplosionNormal;

	BlinkLightComp.SetEnabled( false ); //disable blinking lights
	StickHelper.UnPin();

	ExplosionNormal = vect(0,0,1) >> Rotation;
	Explode(Location, ExplosionNormal);
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	StickHelper.UnPin();
	super.Explode(HitLocation, HitNormal);
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
			StickHelper.TryStick(HitNormal, HitLocation, HitActor);
		}
	}
}

function Init(vector Direction)
{
    if( LifeSpan == default.LifeSpan && WorldInfo.TimeDilation < 1.f )
    {
        LifeSpan /= WorldInfo.TimeDilation;
    }

    super.Init( Direction );
}

simulated function bool ZapFunction(Actor _TouchActor)
{
	local vector BeamEndPoint;
	local KFPawn_Monster oMonsterPawn;
	local int iZapped;
	local ParticleSystemComponent BeamPSC;
	foreach WorldInfo.AllPawns( class'KFPawn_Monster', oMonsterPawn )
	{
		if( oMonsterPawn.IsAliveAndWell() && oMonsterPawn != _TouchActor)
		{
			//`Warn("PAWN CHECK IN: "$oMonsterPawn.Location$"");
			//`Warn(VSizeSQ(oMonsterPawn.Location - _TouchActor.Location));
			if( VSizeSQ(oMonsterPawn.Location - _TouchActor.Location) < Square(MaxDistanceToBeZapped) )
			{
				if(FastTrace(_TouchActor.Location, oMonsterPawn.Location, vect(0,0,0)) == false)
				{
					continue;
				}

				if(WorldInfo.NetMode != NM_DedicatedServer)
				{
					BeamPSC = vBeamEffects.SpawnEmitter(BeamPSCTemplate, _TouchActor.Location, _TouchActor.Rotation);

					BeamEndPoint = oMonsterPawn.Mesh.GetBoneLocation('Spine1');
					if(BeamEndPoint == vect(0,0,0)) BeamEndPoint = oMonsterPawn.Location;

					BeamPSC.SetBeamSourcePoint(0, _TouchActor.Location, 0);
					BeamPSC.SetBeamTargetPoint(0, BeamEndPoint, 0);
					
					BeamPSC.SetAbsolute(false, false, false);
					BeamPSC.bUpdateComponentInTick = true;
					BeamPSC.SetActive(true);

					StoreBeam(BeamPSC, oMonsterPawn);
					ZapSFXComponent.PlayEvent(ZapSFX, true);
				}

				if(WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_StandAlone ||  WorldInfo.NetMode == NM_ListenServer)
				{
					ChainedZapDamageFunction(oMonsterPawn, _TouchActor);
				}

				++iZapped;
			}
		}

		if(iZapped >= MaxNumberOfZedsZapped) break;
	}
	if(iZapped > 0) 
		return true;
	else
		return false;
}

simulated function StoreBeam(ParticleSystemComponent Beam, KFPawn_Monster Monster)
{
	local BeamZapInfo BeamInfo;
	BeamInfo.oBeam = Beam;
	BeamInfo.oAttachedZed = Monster;
	BeamInfo.oSourceActor = self;
	BeamInfo.oControlTime = ZapInterval;
	CurrentZapBeams.AddItem(BeamInfo);
}

function ChainedZapDamageFunction(Actor _TouchActor, Actor _OriginActor)
{
	//local float DistToHitActor;
	local vector Momentum;
	local TraceHitInfo HitInfo;
	local Pawn TouchPawn;
	local int TotalDamage;
 
	if (_OriginActor != none)
	{
		Momentum = _TouchActor.Location - _OriginActor.Location;
	}

	//DistToHitActor = VSize(Momentum);
	//Momentum *= (MomentumScale / DistToHitActor);
	if (ZapDamage > 0)
	{
		TouchPawn = Pawn(_TouchActor);
		// Let script know that we hit something
		if (TouchPawn != none)
		{
			ProcessDirectImpact();
		}
		//`Warn("["$WorldInfo.TimeSeconds$"] Damaging "$_TouchActor.Name$" for "$ZapDamage$", Dist: "$VSize(_TouchActor.Location - _OriginActor.Location));
		
		TotalDamage = ZapDamage * UpgradeDamageMod;
		_TouchActor.TakeDamage(TotalDamage, oOriginalOwnerController, _TouchActor.Location, Momentum, class'KFDT_EMP_Zap', HitInfo, self);
	}
}

// Notification that a direct impact has occurred
event ProcessDirectImpact()
{
    local KFPlayerController KFPC;

    KFPC = KFPlayerController(oOriginalOwnerController);

    if( KFPC != none )
    {
        KFPC.AddShotsHit(1);
    }
}

simulated event Tick( float DeltaTime )
{
	Local int i;
	local vector BeamEndPoint;

	/*//cylinders debug
	local vector A, B;
	A = Location + (vect(0.0f,0.0f,20.0f) * 1);
	B = Location + (vect(0.0f,0.0f,-20.0f) * 1);
	DrawDebugCylinder( A, B, 40, 10, 255, 255, 0, true); // SLOW! Use for debugging only!
	*/
	
	if(CurrentZapBeams.length > 0)
	{
		for(i=0 ; i<CurrentZapBeams.length ; i++)
		{
			CurrentZapBeams[i].oControlTime -= DeltaTime;
			if(CurrentZapBeams[i].oControlTime > 0 && CurrentZapBeams[i].oAttachedZed.IsAliveAndWell())
			{
				BeamEndPoint = CurrentZapBeams[i].oAttachedZed.Mesh.GetBoneLocation('Spine1');
				if(BeamEndPoint == vect(0,0,0)) BeamEndPoint = CurrentZapBeams[i].oAttachedZed.Location;

				CurrentZapBeams[i].oBeam.SetBeamSourcePoint(0, CurrentZapBeams[i].oSourceActor.Location, 0);
				CurrentZapBeams[i].oBeam.SetBeamTargetPoint(0, BeamEndPoint, 0);
			}
			else
			{
				CurrentZapBeams[i].oBeam.DeactivateSystem();
				CurrentZapBeams.RemoveItem(CurrentZapBeams[i]);
				i--;
			}
		}
	}

	TimeToZap += DeltaTime;
	//`Warn(TimeToZap);
	//`Warn(TimeToZap > ZapInterval);
	if(TimeToZap > ZapInterval)
	{
		if(ZapFunction(self))
		{
			TimeToZap = 0;
		}
	}

	super.Tick(DeltaTime);

	StickHelper.Tick(DeltaTime);

    if (bIsProjActive)
    {
	    StickHelper.Tick(DeltaTime);
    }

	if (!IsZero(Velocity))
	{
		SetRelativeRotation(rotator(Velocity));
	}
}

simulated protected function DeferredDestroy(float DelaySec)
{
	Super.DeferredDestroy(DelaySec);
	FinalEffectHandling();
}

simulated function Destroyed()
{	
	BlinkLightComp.SetEnabled( false );
	FinalEffectHandling();
	Super.Destroyed();
}

simulated function FinalEffectHandling()
{
	Local int i;

	if(CurrentZapBeams.length > 0)
	{
		for(i=0 ; i<CurrentZapBeams.length ; i++)
		{
			CurrentZapBeams[i].oBeam.DeactivateSystem();
		}
	}
}

/*
// Explode this Projectile
simulated function TriggerExplosion(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	// If there is an explosion template do the parent version
	if ( ExplosionTemplate != None )
	{
		Super.TriggerExplosion(HitLocation, HitNormal, HitActor);
		return;
	}

	// otherwise use the ImpactEffectManager for material based effects
	// ProcessEffect(HitLocation, HitNormal, HitActor);
}
*/

/*
simulated function ProcessEffect(Vector HitLocation, Vector HitNormal, Actor HitActor)
{
	local KFPawn OtherPawn;

	if( ImpactEffectTriggered || WorldInfo.NetMode == NM_DedicatedServer )
	{
		return;
	}
	
	// otherwise use the ImpactEffectManager for material based effects
	if ( Instigator != None )
	{
        `ImpactEffectManager.PlayImpactEffects(HitLocation, Instigator,, ImpactEffects);
	}
	else if( oOriginalInstigator != none )
	{
        `ImpactEffectManager.PlayImpactEffects(HitLocation, oOriginalInstigator,, ImpactEffects);
	}
	else
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ImpactEffects.DefaultImpactEffect.ParticleTemplate, Location, Rotation);
	}

	if(HitActor != none)
	{
		OtherPawn = KFPawn(HitActor);
		ImpactEffectTriggered = OtherPawn != none ? false : true;
	}
}
*/

// Damage without stopping the projectile (see also Weapon.PassThroughDamage)
simulated function bool PassThroughDamage(Actor HitActor)
{
    // Don't stop this projectile for interactive foliage
	if ( !HitActor.bBlockActors && HitActor.IsA('InteractiveFoliageActor') )
	{
		return true;
	}

	return FALSE;
}

defaultproperties
{
	Physics=PHYS_Projectile
    MaxSpeed=6500 //7500
	Speed=6500
	TossZ=0
	GravityScale=1.0
    MomentumTransfer=20000
	LifeSpan=15 //7.0
	PostExplosionLifetime=1

	ProjFlightTemplate=ParticleSystem'DROW_EMIT.FX_Zap_Rocket'
	// ImpactEffects=KFImpactEffectInfo'WEP_HRG_ArcGenerator_ARCH.Wep_HRG_ArcGenerator_Alt_Impact'
    // ImpactEffectTriggered=false;
    bCanDisintegrate=false
	// ProjDisintegrateTemplate=ParticleSystem'ZED_Siren_EMIT.FX_Siren_grenade_disable_01'

    // ********************* General settings *********************
    
	bWarnAIWhenFired=true

    bCanBeDamaged=false
	bIgnoreFoliageTouch=true

	bBlockedByInstigator=false
	bAlwaysReplicateExplosion=true

	bNetTemporary=false
	NetPriority=5
	NetUpdateFrequency=200

	bNoReplicationToInstigator=false
	bUseClientSideHitDetection=true
	bUpdateSimulatedPosition=true
	bSyncToOriginalLocation=true
	bSyncToThirdPersonMuzzleLocation=true

    // ********************* Collisions *********************

    // bCollideActors=true
    bCollideComplex=true

	Begin Object Name=CollisionCylinder
		BlockNonZeroExtent=false
		// for siren scream
		CollideActors=true
	End Object

	// Begin Object Name=CollisionCylinder
	// 	CollisionRadius=1 //10
	// 	CollisionHeight=1 //10
	// 	BlockNonZeroExtent=true
	// 	// for siren scream
	// 	CollideActors=true
	// End Object
	// ExtraLineCollisionOffsets.Add((Y=-1)) //-10
 	// ExtraLineCollisionOffsets.Add((Y=1)) //10
  	// // Since we're still using an extent cylinder, we need a line at 0
  	// ExtraLineCollisionOffsets.Add(())

    // ********************* Zapper *********************	

	MaxNumberOfZedsZapped=1 //3
	MaxDistanceToBeZapped=300 //250
	ZapInterval=0.4
	ZapDamage=15 //18
	TimeToZap=100 //80

	EmitterPoolClassPath="Engine.EmitterPool"
    BeamPSCTemplate = ParticleSystem'WEP_HRG_ArcGenerator_EMIT.FX_Beam_Test_2'

    Begin Object Class=AkComponent name=ZapOneShotSFX
    	BoneName=dummy // need bone name so it doesn't interfere with default PlaySoundBase functionality
    	bStopWhenOwnerDestroyed=true
    End Object
    ZapSFXComponent=ZapOneShotSFX
    Components.Add(ZapOneShotSFX)
    ZapSFX=AkEvent'ww_wep_hrg_energy.Play_WEP_HRG_Energy_1P_Shoot'

    // ********************* Sticking *********************

    SecondsBeforeDetonation=7.0f //5.0f
    bIsProjActive=true

	bCanStick=true
	bCanPin=false
	Begin Object Class=KFProjectileStickHelper_Zap Name=StickHelper0 //Class=KFProjectileStickHelper Name=StickHelper0
	End Object
	StickHelper=StickHelper0
	PinBoneIdx=INDEX_None

    // ********************* Ambient *********************

    // bAutoStartAmbientSound=true
	// bAmbientSoundZedTimeOnly=false
	// bImportantAmbientSound=true
	// bStopAmbientSoundOnExplode=true

	// AmbientSoundPlayEvent=AkEvent'WW_WEP_HRG_ArcGenerator.Play_HRG_ArcGenerator_AltFire_Loop'
  	// AmbientSoundStopEvent=None

    // ********************* Explosion *********************

	// Blinking point light
	Begin Object Class=PointLightComponent Name=BlinkPointLight
	    LightColor=(R=255,G=63,B=63,A=255)
		Brightness=4.f
		Radius=300.f
		FalloffExponent=10.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=False
		bCastPerObjectShadows=false
		bEnabled=TRUE
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
		Translation=(X=5,Z=0)

		// light anim
        AnimationType=2 // LightAnim_Blink ?
        AnimationFrequency=3.f
        MinBrightness=1.0f
        MaxBrightness=2.0f
	End Object
	BlinkLightComp=BlinkPointLight
	Components.Add(BlinkPointLight)

	ExplosionActorClass=class'KFExplosionActor'

	// explosion light
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
		Damage=50 //60
	    DamageRadius=300 //200
		DamageFalloffExponent=1.f
		DamageDelay=0.f
		MyDamageType=class'KFDT_Explosive_Zap'

		// Damage Effects
		KnockDownStrength=0
		FractureMeshRadius=200.0
		FracturePartVel=500.0
		ExplosionEffects=KFImpactEffectInfo'WEP_ZEDMKIII_ARCH.FX_ZEDMKIII_Explosion'
		ExplosionSound=AkEvent'WW_WEP_ZEDMKIII.Play_WEP_ZEDMKIII_Explosion'

        // Dynamic Light
        ExploLight=ExplosionPointLight
        ExploLightStartFadeOutTime=0.0
        ExploLightFadeOutTime=0.2

		// Camera Shake
		CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Light_Explosion_Rumble'
		CamShakeInnerRadius=0
		CamShakeOuterRadius=200
		CamShakeFalloff=1.5f
		bOrientCameraShakeTowardsEpicenter=true
	End Object
	ExplosionTemplate=ExploTemplate0
}