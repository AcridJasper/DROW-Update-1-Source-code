class KFWeap_EntryPortal extends KFWeap_GrenadeLauncher_Base;

// var() float ZEDSpawntimeFP;

// var transient bool bTurretReadyToUse;
// var transient byte NumDeployedTurrets;
// var transient KFPlayerController KFPC;

var transient KFParticleSystemComponent FirePSC;
var const ParticleSystem FireFXTemplate;

/* Light that is applied to the blade and the bone to attach to*/
var PointLightComponent IdleLight;
var Name LightAttachBone;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// Ironsights Audio
var AkComponent       IronsightsComponent;
var AkEvent           IronsightsZoomInSound;
var AkEvent           IronsightsZoomOutSound;

var AkEvent AmbientSoundPlayEvent;
var AkEvent	AmbientSoundStopEvent;

// How many Alt ammo to recharge per second
var float AmmoFullRechargeSeconds;
var transient float AmmoRechargePerSecond;
var transient float AmmoIncrement;
var repnotify byte FakeAmmo;

//, NumDeployedTurrets, bTurretReadyToUse;
replication
{
	if (bNetDirty && Role == ROLE_Authority)
		FakeAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(FakeAmmo))
	{
		AmmoCount[DEFAULT_FIREMODE] = FakeAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAmmoRecharge();
}

/*
simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if (Role == ROLE_Authority)
	{
		KFPC = KFPlayerController(Instigator.Controller);
		NumDeployedTurrets = KFPC.DeployedTurrets.Length;
	}
}
*/

function StartAmmoRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedAmmoRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedAmmoRechargeTime = AmmoFullRechargeSeconds;
	    AmmoRechargePerSecond = MagazineCapacity[DEFAULT_FIREMODE] / UsedAmmoRechargeTime;
		AmmoIncrement = 0;
	}
}

function RechargeAmmo(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		AmmoIncrement += AmmoRechargePerSecond * DeltaTime;

		if( AmmoIncrement >= 1.0 && AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
		{
			AmmoCount[DEFAULT_FIREMODE]++;
			AmmoIncrement -= 1.0;
			FakeAmmo = AmmoCount[DEFAULT_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartAmmoRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
	{
        RechargeAmmo(DeltaTime);
	}
	
	Super.Tick(DeltaTime);
}

// Alt doesn't count as ammo for purposes of inventory management (e.g. switching) 
simulated function bool HasAnyAmmo()
{
	return HasSpareAmmo() || HasAmmo(ALTFIRE_FIREMODE);
}

simulated function string GetSpecialAmmoForHUD()
{
	return int(FakeAmmo)$"%";
}

simulated function bool CanBuyAmmo()
{
	return false;
}

simulated state WeaponEquipping
{
	// when picked up, start the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		ActivatePSC(FirePSC, FireFXTemplate, 'FireFX');

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundPlayEvent);
			}
		}

		if (MySkelMesh != none)
		{
			MySkelMesh.AttachComponentToSocket(IdleLight, LightAttachBone);
			IdleLight.SetEnabled(true);
		}
	}
}

simulated function ActivatePSC(out KFParticleSystemComponent OutPSC, ParticleSystem ParticleEffect, name SocketName)
{
	if (MySkelMesh != none)
	{
		MySkelMesh.AttachComponentToSocket(OutPSC, SocketName);
		OutPSC.SetFOV(MySkelMesh.FOV);
	}
	else
	{
		AttachComponent(OutPSC);
	}

	OutPSC.ActivateSystem();

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(ParticleEffect);
		// OutPSC.SetAbsolute(false, false, false);
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
	}
}

simulated state Inactive
{
	// when dropped, destroyed, etc, play the stop on the persistent sound
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		if (FirePSC != none)
		{
			FirePSC.DeactivateSystem();
		}

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
			}
		}

		IdleLight.SetEnabled(false);
	}
}

simulated state WeaponPuttingDown
{
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;

		super.BeginState(PreviousStateName);

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
			}
		}
	}
}

simulated state WeaponAbortEquip
{
	simulated event BeginState(Name PreviousStateName)
	{
		local KFPawn InstigatorPawn;
		
		super.BeginState(PreviousStateName);

		if (Instigator != none)
		{
			InstigatorPawn = KFPawn(Instigator);
			if (InstigatorPawn != none)
			{
				InstigatorPawn.PlayWeaponSoundEvent(AmbientSoundStopEvent);
			}
		}
	}
}

simulated function ZoomIn(bool bAnimateTransition, float ZoomTimeToGo)
{
    super.ZoomIn(bAnimateTransition, ZoomTimeToGo);

    if (IronsightsZoomInSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomInSound, false);
    }
}

simulated function ZoomOut( bool bAnimateTransition, float ZoomTimeToGo )
{
	super.ZoomOut( bAnimateTransition, ZoomTimeToGo );

    if (IronsightsZoomOutSound != none && Instigator != none && Instigator.IsLocallyControlled())
    {
        IronsightsComponent.PlayEvent(IronsightsZoomOutSound, false);
    }
}

// Overriden to use instant hit vfx.Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

	// SetTimer(ZEDSpawntimeFP, false, nameof(Timer_SpawnFriendlyFP));

    MyProjectileClass = GetKFProjectileClass();

	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	if( Instigator != None )
	{
		Instigator.SetFlashLocation( Self, CurrentFireMode, TestImpact.HitLocation );
	}

	if( Role == ROLE_Authority || (MyProjectileClass.default.bUseClientSideHitDetection
        && MyProjectileClass.default.bNoReplicationToInstigator && Instigator != none
        && Instigator.IsLocallyControlled()) )
	{

		if( StartTrace != RealStartLoc )
		{	
            DirB = AimDir;

			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

    		DirA = AimDir;

    		if ( (DirA dot DirB) < MaxAimAdjust_Cos )
    		{
    			Q = QuatFromAxisAndAngle(Normal(DirB cross DirA), MaxAimAdjust_Angle);
    			AimDir = QuatRotateVector(Q,DirB);
    		}
		}

		return SpawnAllProjectiles(MyProjectileClass, RealStartLoc, AimDir);
	}

	return None;
}

/*
function Timer_SpawnFriendlyFP()
{
	SpawnFriendlyAI();
}

simulated function SpawnFriendlyAI()
{
	local Hell Zed;

	if (Role == ROLE_Authority )
	{
		Zed = Spawn(class'Hell');

		Detonate(); // kill pawn if we spawn again
	
		if ( Zed != None )
		{
			Zed.OwnerWeapon = self;
			Zed.SetPhysics(PHYS_Falling);
			Zed.UpdateInstigator(Instigator);
			Zed.SetTurretState(ETS_None);
	
			if (KFPC != none)
			{
				KFPC.DeployedTurrets.AddItem( Zed );
				NumDeployedTurrets = KFPC.DeployedTurrets.Length;
			}
	
			bTurretReadyToUse = false;
			bForceNetUpdate = true;
	
			Zed.SpawnDefaultController();
			if( KFAIController(Zed.Controller) != none )
			{
				KFAIController( Zed.Controller ).SetTeam(0); //Set ZED to Human team (255 is ZED Team - 128 Neutral Team)
			}
		}
	}
}

simulated function Detonate(optional bool bKeepTurret = false)
{
	local int i;
	local array<Actor> TurretsCopy;

	// auto switch weapon when out of ammo and after detonating the last deployed turret
	if( Role == ROLE_Authority )
	{
		TurretsCopy = KFPC.DeployedTurrets;
		for (i = 0; i < TurretsCopy.Length; i++)
		{
			if (bKeepTurret && i == 0)
			{
				continue;
			}

			if (Hell(TurretsCopy[i]) != none)
			{
				Hell(TurretsCopy[i]).SetTurretState(ETS_Detonate);
			}
		}

		KFPC.DeployedTurrets.Remove(bKeepTurret ? 1 : 0, KFPC.DeployedTurrets.Length);

		SetReadyToUse(true);
	}
}

// Removes a turret from the list using either an index or an actor and updates NumDeployedTurrets
function RemoveDeployedTurret( optional int Index = INDEX_NONE, optional Actor TurretActor )
{
	if( Index == INDEX_NONE )
	{
		if( TurretActor != none )
		{
			Index = KFPC.DeployedTurrets.Find( TurretActor );
		}
	}

	if( Index != INDEX_NONE )
	{
		KFPC.DeployedTurrets.Remove( Index, 1 );
		NumDeployedTurrets = KFPC.DeployedTurrets.Length;
		bForceNetUpdate = true;
	}
}

function SetReadyToUse(bool bReady)
{
	if (bTurretReadyToUse != bReady)
	{
		bTurretReadyToUse = bReady;
		bNetDirty = true;
	}
}
*/

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AmmoFullRechargeSeconds;
}

// Returns trader filter index based on weapon type (copied from riflebase)
static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
	super.AdjustDamage(InDamage, DamageType, DamageCauser);

	if (Instigator != none && DamageCauser.Instigator == Instigator)
	{
		InDamage *= SelfDamageReductionValue;
	}
}

defaultproperties
{
	// Inventory
	InventoryGroup=IG_Primary
	GroupPriority=21 // funny number
	InventorySize=4 //6 7
	WeaponSelectTexture=Texture2D'WEP_EntryPortal_MAT.UI_WeaponSelect_EntryPortal'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
	MeshFOV=86
	MeshIronSightFOV=65
	PlayerIronSightFOV=70
	PlayerSprintFOV=95

	// Zooming/Position
	PlayerViewOffset=(X=20.0,Y=5,Z=-5)
	IronSightPosition=(X=0,Y=-0.065,Z=0)
	FastZoomOutTime=0.2

	// Content
	PackageKey="EntryPortal"
	FirstPersonMeshName="WEP_EntryPortal_MESH.Wep_1stP_EntryPortal_Rig"
	FirstPersonAnimSetNames(0)="WEP_EntryPortal_ARCH.Wep_1stP_EntryPortal_Anim"
	PickupMeshName="WEP_EntryPortal_MESH.Wep_EntryPortal_Pickup"
	AttachmentArchetypeName="WEP_EntryPortal_ARCH.WEP_EntryPortal_3P"
	MuzzleFlashTemplateName="WEP_EntryPortal_ARCH.Wep_EntryPortal_MuzzleFlash"

	// Ammo
	AmmoFullRechargeSeconds=50 //25
	FakeAmmo=100
	MagazineCapacity[0]=100
	SpareAmmoCapacity[0]=0
	InitialSpareMags[0]=0
	AmmoPickupScale[0]=0.0
	bCanBeReloaded=false
	bReloadFromMagazine=false
	ForceReloadTime=0.4f

	// Recoil
	maxRecoilPitch=900
	minRecoilPitch=775
	maxRecoilYaw=500
	minRecoilYaw=-500
	RecoilRate=0.085
	RecoilBlendOutRatio=0.35
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1500
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485
	RecoilViewRotationScale=0.8
	FallingRecoilModifier=1.5
	HippedRecoilModifier=1.25

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_HighExplosive_EntryPortal'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Seeker6Impact'
	FireInterval(DEFAULT_FIREMODE)=0.8 // 75 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=200 //125
	Spread(DEFAULT_FIREMODE)=0.025
	AmmoCost(DEFAULT_FIREMODE)=100
	FireOffset=(X=20,Y=4.0,Z=-3)

	// bTurretReadyToUse=true
	// ZEDSpawntimeFP=7.0

	SelfDamageReductionValue=0.08f; //0.16

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Seeker6'
	InstantHitDamage(BASH_FIREMODE)=29

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Blunderbuss.Play_WEP_Blunderbuss_Fire_3P_01', FirstPersonCue=AkEvent'WW_WEP_Blunderbuss.Play_WEP_Blunderbuss_Alt_Fire_1P_01')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Blunderbuss.Play_WEP_Blunderbuss_Fire_3P_01', FirstPersonCue=AkEvent'WW_WEP_Blunderbuss.Play_WEP_Blunderbuss_Alt_Fire_1P_01')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_DryFire'

	//Ambient Sounds
    AmbientSoundPlayEvent=AkEvent'WW_ENV_BurningParis.Play_ENV_Paris_Underground_LP_01'
    AmbientSoundStopEvent=AkEvent'WW_ENV_BurningParis.Stop_ENV_Paris_Underground_LP_01'

	FireFXTemplate=ParticleSystem'DROW_EMIT.FX_EntryPortal_FireFX'
	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	FirePSC=BasePSC0

    // Audio
    Begin Object Class=AkComponent name=IronsightsComponent0
        bForceOcclusionUpdateInterval=true
		OcclusionUpdateInterval=0.f // never update occlusion for footsteps
		bStopWhenOwnerDestroyed=true
    End Object
    IronsightsComponent=IronsightsComponent0
    Components.Add(IronsightsComponent0)
    IronsightsZoomInSound=AkEvent'WW_WEP_Seeker_6.Play_Seeker_6_Iron_In'
    IronsightsZoomOutSound=AkEvent'WW_WEP_Seeker_6.Play_Seeker_6_Iron_In_Out'
    
    Begin Object Class=PointLightComponent Name=IdlePointLight
		LightColor=(R=250,G=150,B=85,A=255)
		Brightness=0.125f
		FalloffExponent=4.f
		Radius=250.f
		CastShadows=False
		CastStaticShadows=FALSE
		CastDynamicShadows=TRUE
		bCastPerObjectShadows=false
		LightingChannels=(Indoor=TRUE,Outdoor=TRUE,bInitialized=TRUE)
	End Object
	IdleLight=IdlePointLight
	LightAttachBone=FireFX

	// Animation
	bHasFireLastAnims=true
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3)

	//BonesToLockOnEmpty=(RW_Grenade1)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	AssociatedPerkClasses(0)=none

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
}