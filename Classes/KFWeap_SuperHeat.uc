class KFWeap_SuperHeat extends KFWeap_PistolBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/*
// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;

var transient KFParticleSystemComponent MuzzlePSC;
var ParticleSystem MuzzleEffectOn;

const MuzzleSocketName = 'MuzzleFlash';
*/

// Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion)
var() float SelfDamageReductionValue;

var const float BarrelHeatPerProjectile;
var const float MaxBarrelHeat;
var const float BarrelCooldownRate;
var transient float CurrentBarrelHeat;
var transient float LastBarrelHeat;

var class<KFGFxWorld_MedicOptics> OpticsUIClass;
var KFGFxWorld_MedicOptics OpticsUI;

// The last updated value for our ammo - Used to know when to update our optics ammo
var byte StoredPrimaryAmmo;
var byte StoredSecondaryAmmo;

/*
replication
{
	if (bNetDirty && Role == ROLE_Authority)
		AltAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(AltAmmo))
	{
		AmmoCount[ALTFIRE_FIREMODE] = AltAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartAltRecharge();
}

function StartAltRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedAltRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedAltRechargeTime = AltFullRechargeSeconds;
	    AltRechargePerSecond = MagazineCapacity[ALTFIRE_FIREMODE] / UsedAltRechargeTime;
		AltIncrement = 0;
	}
}

function RechargeAlt(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		AltIncrement += AltRechargePerSecond * DeltaTime;

		if( AltIncrement >= 1.0 && AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
		{
			AmmoCount[ALTFIRE_FIREMODE]++;
			AltIncrement -= 1.0;
			AltAmmo = AmmoCount[ALTFIRE_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartAltRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[ALTFIRE_FIREMODE] < MagazineCapacity[ALTFIRE_FIREMODE] )
	{
        RechargeAlt(DeltaTime);
	}

	if( AltAmmo == 50 )
	{
		MuzzlePSC.SetTemplate(MuzzleEffectOn);
		MuzzlePSC.ActivateSystem();
	}
	else if( AltAmmo == 100 )
	{
		MuzzlePSC.SetTemplate(MuzzleEffectOn);
		MuzzlePSC.ActivateSystem();
	}
	else if( AltAmmo == 150 )
	{
		MuzzlePSC.SetTemplate(MuzzleEffectOn);
		MuzzlePSC.ActivateSystem();
	}

	Super.Tick(DeltaTime);

	CurrentBarrelHeat = fmax(CurrentBarrelHeat - BarrelCooldownRate * DeltaTime, 0.0f);
	ChangeBarrelMaterial();
}

simulated function AttachWeaponTo (SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	super.AttachWeaponTo (MeshCpnt, SocketName);

	if (MuzzlePSC == none)
	{
		MuzzlePSC = new(self) class'KFParticleSystemComponent';
		MuzzlePSC.SetDepthPriorityGroup(SDPG_Foreground);
		MuzzlePSC.SetTickGroup(TG_PostUpdateWork);
		MuzzlePSC.SetFOV(MySkelMesh.FOV);
		
		MySkelMesh.AttachComponentToSocket (MuzzlePSC, MuzzleSocketName);
	}
}

simulated event SetFOV( float NewFOV )
{
	super.SetFOV(NewFOV);

	if (MuzzlePSC != none)
	{
		MuzzlePSC.SetFOV(NewFOV);
	}
}

simulated function DetachWeapon()
{
	if (MuzzlePSC != none)
	{
		MuzzlePSC.DeactivateSystem ();
		MySkelMesh.DetachComponent (MuzzlePSC);
		MuzzlePSC = none;
	}
	
    super.DetachWeapon();
}
*/

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	// Force start with "Glow_Intensity" of 0.0f
	LastBarrelHeat = MaxBarrelHeat;
	ChangeBarrelMaterial();
}

simulated function KFProjectile SpawnProjectile( class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir )
{
    if( CurrentFireMode == DEFAULT_FIREMODE )
    {
		CurrentBarrelHeat = fmin(CurrentBarrelHeat + BarrelHeatPerProjectile, MaxBarrelHeat);
    }

    // if( CurrentFireMode == ALTFIRE_FIREMODE )
    // {
	// 	MuzzlePSC.SetTemplate(MuzzleEffectOn);
	// 	MuzzlePSC.DeactivateSystem();
    // }

    return super.SpawnProjectile( KFProjClass, RealStartLoc, AimDir );
}

simulated function ChangeBarrelMaterial()
{
	local int i;

    if( CurrentBarrelHeat != LastBarrelHeat )
    {
    	for( i = 0; i < WeaponMICs.Length; ++i )
    	{
    		if( WeaponMICs[i] != none )
    		{
				WeaponMICs[i].SetScalarParameterValue('Barrel_intensity', CurrentBarrelHeat);
				LastBarrelHeat = CurrentBarrelHeat; 
			}
		}
    }
}

simulated function Tick(float Delta)
{
	if (Instigator != none && Instigator.weapon == self)
	{
		UpdateOpticsUI();
	}

	Super.Tick(Delta);

	CurrentBarrelHeat = fmax(CurrentBarrelHeat - BarrelCooldownRate * Delta, 0.0f);
	ChangeBarrelMaterial();
}

/*
simulated function AltFireMode()
{
	if ( !Instigator.IsLocallyControlled() )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
}
*/

// Get our optics movie from the inventory once our InvManager is created
reliable client function ClientWeaponSet(bool bOptionalSet, optional bool bDoNotActivate)
{
	local KFInventoryManager KFIM;

	super.ClientWeaponSet(bOptionalSet, bDoNotActivate);

	if (OpticsUI == none && OpticsUIClass != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			//Create the screen's UI piece
			OpticsUI = KFGFxWorld_MedicOptics(KFIM.GetOpticsUIMovie(OpticsUIClass));
		}
	}
}

// Update our displayed ammo count if it's changed
simulated function UpdateOpticsUI(optional bool bForceUpdate)
{
	if (OpticsUI != none && OpticsUI.OpticsContainer != none)
	{
		if (AmmoCount[DEFAULT_FIREMODE] != StoredPrimaryAmmo || bForceUpdate)
		{
			StoredPrimaryAmmo = AmmoCount[DEFAULT_FIREMODE];
			OpticsUI.SetPrimaryAmmo(StoredPrimaryAmmo);
		}

		if (AmmoCount[ALTFIRE_FIREMODE] != StoredSecondaryAmmo || bForceUpdate)
		{
			StoredSecondaryAmmo = AmmoCount[ALTFIRE_FIREMODE];
			OpticsUI.SetHealerCharge(StoredSecondaryAmmo);
		}

		if(OpticsUI.MinPercentPerShot != AmmoCost[ALTFIRE_FIREMODE])
		{
			OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE] );
		}
	}
}

function ItemRemovedFromInvManager()
{
	local KFInventoryManager KFIM;
	local KFWeap_MedicBase KFW;

	Super.ItemRemovedFromInvManager();

	if (OpticsUI != none)
	{
		KFIM = KFInventoryManager(InvManager);
		if (KFIM != none)
		{
			// @todo future implementation will have optics in base weapon class
			foreach KFIM.InventoryActors(class'KFWeap_MedicBase', KFW)
			{
				if( KFW.OpticsUI.Class == OpticsUI.class)
				{
					// A different weapon is still using this optics class
					return;
				}
			}

			//Create the screen's UI piece
			KFIM.RemoveOpticsUIMovie(OpticsUI.class);

			OpticsUI.Close();
			OpticsUI = none;
		}
	}
}

// Unpause our optics movie and reinitialize our ammo when we equip the weapon
simulated function AttachWeaponTo(SkeletalMeshComponent MeshCpnt, optional Name SocketName)
{
	super.AttachWeaponTo(MeshCpnt, SocketName);

	if (OpticsUI != none)
	{
		OpticsUI.SetPause(false);
		OpticsUI.ClearLockOn();
		UpdateOpticsUI(true);
		OpticsUI.SetShotPercentCost( AmmoCost[ALTFIRE_FIREMODE]);
	}
}

// Pause the optics movie once we unequip the weapon so it's not playing in the background
simulated function DetachWeapon()
{
	local Pawn OwnerPawn;
	super.DetachWeapon();

	OwnerPawn = Pawn(Owner);
	if( OwnerPawn != none && OwnerPawn.Weapon == self )
	{
		if (OpticsUI != none)
		{
			OpticsUI.SetPause();
		}
	}
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

simulated function PlayFiringSound( byte FireModeNum )
{
    local byte UsedFireModeNum;

	MakeNoise(1.0,'PlayerFiring'); // AI

	if (MedicComp != none && FireModeNum == ALTFIRE_FIREMODE)
	{
		MedicComp.PlayFiringSound();
	}
	else
	if ( !bPlayingLoopingFireSnd )
	{
		UsedFireModeNum = FireModeNum;

		// Use the single fire sound if we're in zed time and want to play single fire sounds
		if( FireModeNum < bLoopingFireSnd.Length && bLoopingFireSnd[FireModeNum] && ShouldForceSingleFireSound() )
        {
            UsedFireModeNum = SingleFireSoundIndex;
        }

        if ( UsedFireModeNum < WeaponFireSound.Length )
		{
			WeaponPlayFireSound(WeaponFireSound[UsedFireModeNum].DefaultCue, WeaponFireSound[UsedFireModeNum].FirstPersonCue);
		}
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

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
    // FOV
	MeshFOV=86
	MeshIronSightFOV=77
    PlayerIronSightFOV=77

	// Zooming/Position
	PlayerViewOffset=(X=14.0,Y=10,Z=-4)
	IronSightPosition=(X=11,Y=0,Z=0)

	// Content
	PackageKey="SuperHeat"
	FirstPersonMeshName="WEP_SuperHeat_MESH.Wep_1stP_SuperHeat_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_Deagle_ANIM.Wep_1st_Deagle_Anim"
	PickupMeshName="WEP_SuperHeat_MESH.Wep_SuperHeat_Pickup"
	AttachmentArchetypeName="WEP_SuperHeat_ARCH.WEP_SuperHeat_3P"
	MuzzleFlashTemplateName="WEP_Deagle_ARCH.Wep_Deagle_MuzzleFlash"

    OpticsUIClass=class'KFGFxWorld_MedicOptics'

	// Ammo
	MagazineCapacity[0]=7
	SpareAmmoCapacity[0]=105
	InitialSpareMags[0]=5
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=550
	minRecoilPitch=450
	maxRecoilYaw=140
	minRecoilYaw=-140
	RecoilRate=0.07
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1250
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485

	// DEFAULT_FIREMODE (Shoots small explosive novas)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile //EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_SuperHeat'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_SuperHeat'
	FireInterval(DEFAULT_FIREMODE)=+0.2
	InstantHitDamage(DEFAULT_FIREMODE)=91 //100
	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0.01
	FireOffset=(X=20,Y=4.0,Z=-3)

	// Heat
	MaxBarrelHeat=4.0f
	BarrelHeatPerProjectile=0.25f
	BarrelCooldownRate=0.2f
	CurrentBarrelHeat=0.0f
	LastBarrelHeat=0.0f

	// bIgnoreInstigator=true doesn't work, neither does bIgnoreSelfInflictedScale=true
    SelfDamageReductionValue=0; //26

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

/*
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile //EWFT_InstantHit
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_SuperHeat'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_SuperHeat'
	FireInterval(ALTFIRE_FIREMODE)=0.8 // 75 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=91 //100
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=0.01
	AmmoCost(ALTFIRE_FIREMODE)=50

	AltAmmo=100
	MagazineCapacity[1]=100
	AltFullRechargeSeconds=10
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'DTest_MAT.UI_FireModeSelect_PercentageT'
    
	MuzzleEffectOn=ParticleSystem'DROW_EMIT.FX_SuperHeat_Lens'
*/

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Deagle'
	InstantHitDamage(BASH_FIREMODE)=22

	// Fire Effects
	//WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Fire_Single_M', FirstPersonCue=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Fire_Single_S')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_SuperHeat_SND.superheat_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_SuperHeat_SND.superheat_fire_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_SuperHeat_SND.superheat_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_SuperHeat_SND.superheat_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_DesertEagle.Play_WEP_SA_DesertEagle_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Inventory
	InventorySize=4 //3
	GroupPriority=21 // funny number
	bCanThrow=true
	bDropOnDeath=true
	WeaponSelectTexture=Texture2D'WEP_SuperHeat_MAT.UI_WeaponSelect_SuperHeat'
	bIsBackupWeapon=false
	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'
	AssociatedPerkClasses(1)=class'KFPerk_Firebug'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	IdleFidgetAnims=(Guncheck_v1, Guncheck_v2, Guncheck_v3, Guncheck_v4)

	bHasFireLastAnims=true
	BonesToLockOnEmpty=(RW_Slide, RW_Bullets1)

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Medium_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.4f), (Stat=EWUS_Weight, Add=2)))
}