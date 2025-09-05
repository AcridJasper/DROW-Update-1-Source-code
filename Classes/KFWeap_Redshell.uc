class KFWeap_Redshell extends KFWeap_GrenadeLauncher_Base;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

// Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion)
var() float SelfDamageReductionValue;

var float LastFireInterval;

// var int DoshCost;
// var transient KFPlayerReplicationInfo KFPRI;
// var transient bool bIsBeingDropped;

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

//Overriden to use instant hit vfx. Basically, calculate the hit location so vfx can play
simulated function Projectile ProjectileFire()
{
	local vector		StartTrace, EndTrace, RealStartLoc, AimDir;
	local ImpactInfo	TestImpact;
	local vector DirA, DirB;
	local Quat Q;
	local class<KFProjectile> MyProjectileClass;

    MyProjectileClass = GetKFProjectileClass();

	// This is where we would start an instant trace. (what CalcWeaponFire uses)
	StartTrace = GetSafeStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));

	// this is the location where the projectile is spawned.
	RealStartLoc = GetPhysicalFireStartLoc(AimDir);

	// if projectile is spawned at different location of crosshair,
	// then simulate an instant trace where crosshair is aiming at, Get hit info.
	EndTrace = StartTrace + AimDir * GetTraceRange();
	TestImpact = CalcWeaponFire( StartTrace, EndTrace );

	// Set flash location to trigger client side effects.  Bypass Weapon.SetFlashLocation since
	// that function is not marked as simulated and we want instant client feedback.
	// ProjectileFire/IncrementFlashCount has the right idea:
	//	1) Call IncrementFlashCount on Server & Local
	//	2) Replicate FlashCount if ( !bNetOwner )
	//	3) Call WeaponFired() once on local player
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
			// Store the original aim direction without correction
            DirB = AimDir;

			// Then we realign projectile aim direction to match where the crosshair did hit.
			AimDir = Normal(TestImpact.HitLocation - RealStartLoc);

            // Store the desired corrected aim direction
    		DirA = AimDir;

    		// Clamp the maximum aim adjustment for the AimDir so you don't get wierd
    		// cases where the projectiles velocity is going WAY off of where you
    		// are aiming. This can happen if you are really close to what you are
    		// shooting - Ramm
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

simulated function float GetFireInterval(byte FireModeNum)
{
	if (FireModeNum == DEFAULT_FIREMODE && AmmoCount[FireModeNum] == 0)
	{
		return LastFireInterval;
	}

	return super.GetFireInterval(FireModeNum);
}

/*
simulated function Activate()
{
	local KFPawn KFP;

	super.Activate();

	if (KFPRI == none)
	{
		KFP = KFPawn(Instigator);
		if (KFP != none)
		{
			KFPRI = KFPlayerReplicationInfo(KFP.PlayerReplicationInfo);
		}
	}
}

simulated function bool HasAnyAmmo()
{
    return bIsBeingDropped ? AmmoCount[0] > 0 : (AmmoCount[0] > 0 || KFPRI.Score >= DoshCost);
}

/. Returns true if weapon can potentially be reloaded
simulated function bool CanReload(optional byte FireModeNum)
{
	return KFPRI.Score >= DoshCost && AmmoCount[FireModeNum] < MagazineCapacity[FireModeNum];
}

// Performs actual ammo reloading
simulated function PerformReload(optional byte FireModeNum)
{
	local int ReloadAmount;
	local int AmmoType;

	AmmoType = GetAmmoType(FireModeNum);

	if ( bInfiniteSpareAmmo )
	{
		AmmoCount[AmmoType] = MagazineCapacity[AmmoType];
		ReloadAmountLeft = 0;
		return;
	}

	if ( (Role == ROLE_Authority && !bAllowClientAmmoTracking) || (Instigator.IsLocallyControlled() && bAllowClientAmmoTracking) )
	{
		ReloadAmount = Min(MagazineCapacity[0] - AmmoCount[0], KFPRI.Score / DoshCost);
		AmmoCount[AmmoType] = Min(AmmoCount[AmmoType] + ReloadAmount, MagazineCapacity[AmmoType]);
		KFPRI.AddDosh(-ReloadAmount * DoshCost);
	}

	ReloadAmountLeft = 0;
	ShotsHit = 0;
}

function int AddAmmo(int Amount)
{
	return 0;
}

simulated function bool CanBuyAmmo()
{
	return false;
}

static simulated event bool UsesAmmo()
{
    return true;
}

// Overriden to deactivate low ammo dialogue
simulated state Reloading
{
	simulated function EndState(Name NextStateName)
	{
		local int ActualReloadAmount;
		ClearZedTimeResist();
		ClearTimer(nameof(ReloadStatusTimer));
		ClearTimer(nameof(ReloadAmmoTimer));
		ClearPendingFire(RELOAD_FIREMODE);

		if ( bAllowClientAmmoTracking && Role < ROLE_Authority )
		{
			// Get how much total ammo was reloaded on the client side over the entire course of the reload.
			ActualReloadAmount = InitialReloadAmount - ReloadAmountLeft;
			// Sync spare ammo counts using initial spare ammo, and how much ammo has been reloaded since reload began.
			ServerSyncReload(InitialReloadSpareAmmo - ActualReloadAmount);
		}

		CheckBoltLockPostReload();
		NotifyEndState();

		CurrentFireMode = DEFAULT_FIREMODE;

		ReloadStatus = RS_None;
	}
}

// Drop this item out in to the world
function DropFrom(vector StartLocation, vector StartVelocity)
{
	bIsBeingDropped=true;
	super.DropFrom(StartLocation, StartVelocity);
}

function SetOriginalValuesFromPickup( KFWeapon PickedUpWeapon )
{
	local KFPawn KFP;

	bIsBeingDropped=false;
	// Reset the replication info
	KFP = KFPawn(Instigator);
	if (KFP != none)
	{
		KFPRI = KFPlayerReplicationInfo(KFP.PlayerReplicationInfo);
	}

	super.SetOriginalValuesFromPickup(PickedUpWeapon);
}
*/

//Reduce the damage received and apply it to the shield
function AdjustDamage(out int InDamage, class<DamageType> DamageType, Actor DamageCauser)
{
    super.AdjustDamage(InDamage, DamageType, DamageCauser);

    if (Instigator != none && DamageCauser.Instigator == Instigator)
    {
        InDamage *= SelfDamageReductionValue;
    }
}

static simulated event EFilterTypeUI GetAltTraderFilter()
{
	return FT_Flame;
}

defaultproperties
{
	// Inventory / Grouping
	InventorySize=7 //10 12
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Redshell_MAT.UI_WeaponSelect_Redshell'
   	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=60 //70
	MeshIronSightFOV=60 //27
    PlayerIronSightFOV=70
    
	// Zooming/Position
	PlayerViewOffset=(X=15.0,Y=11.5,Z=-4)
	IronSightPosition=(X=0,Y=8,Z=0)

	// Content
	PackageKey="Redshell"
	FirstPersonMeshName="WEP_Redshell_MESH.Wep_1stP_Redshell_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_M99_ANIM.Wep_1stP_M99_Anim"
	PickupMeshName="WEP_Redshell_MESH.Wep_Redshell_Pickup"
	AttachmentArchetypeName="WEP_Redshell_ARCH.Wep_Redshell_3P"
	MuzzleFlashTemplateName="WEP_Redshell_ARCH.Wep_Redshell_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=15 //10 20
	InitialSpareMags[0]=4 //5
	AmmoPickupScale[0]=2.0
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// AI warning system
	bWarnAIWhenAiming=true
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f
	
	// Recoil
	maxRecoilPitch=800
	minRecoilPitch=775
	maxRecoilYaw=500
	minRecoilYaw=-500
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.8
	FallingRecoilModifier=1.0
	HippedRecoilModifier=2.0 //3.0

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Grenade'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_HighExplosive_Redshell'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_RedShell_Impact'
	InstantHitDamage(DEFAULT_FIREMODE)=100 //180
	FireInterval(DEFAULT_FIREMODE)=0.8 // 75 RPM //0.2
	PenetrationPower(DEFAULT_FIREMODE)=0
	Spread(DEFAULT_FIREMODE)=0
	FireOffset=(X=30,Y=3.0,Z=-2.5)
	ForceReloadTimeOnEmpty=0.5
	LastFireInterval=0.3

	// DoshCost=2000 //2500 5000
	// bUsesSecondaryAmmoAltHUD=true
	// bAllowClientAmmoTracking=false
	// bIsBeingDropped=false

	SelfDamageReductionValue=0.06f;
	
	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_M99'
	InstantHitDamage(BASH_FIREMODE)=30

	// Fire Effects
	//WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_M99.Play_WEP_M99_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_M99.Play_WEP_M99_Fire_1P_Single')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Redshell_SND.Redshell_Fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Redshell_SND.Redshell_Fire_1P_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_M99.Play_WEP_M99_DryFire'

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.LaserSight_WithAttachment_1P'
	
	bHasFireLastAnims=true
	FireLastAnim=Shoot
	FireLastSightedAnim=Shoot_Iron

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
}