class KFWeap_Netscape extends KFWeap_RifleBase;

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// How many Alt ammo to recharge per second
var float AltFullRechargeSeconds;
var transient float AltRechargePerSecond;
var transient float AltIncrement;
var repnotify byte AltAmmo;

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

	Super.Tick(DeltaTime);
}

// Alt doesn't count as ammo for purposes of inventory management (e.g. switching) 
simulated function bool HasAnyAmmo()
{
	return HasSpareAmmo() || HasAmmo(DEFAULT_FIREMODE);
}

simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if (FireModeNum == ALTFIRE_FIREMODE)
		return false;
	
	return super.ShouldAutoReload(FireModeNum);
}

// Allow reloads for primary weapon to be interupted by firing secondary weapon
simulated function bool CanOverrideMagReload(byte FireModeNum)
{
	if(FireModeNum == ALTFIRE_FIREMODE)
	{
		return true;
	}

	return Super.CanOverrideMagReload(FireModeNum);
}

// Instead of a toggle, immediately fire alternate fire
simulated function AltFireMode()
{
	// LocalPlayer Only
	if ( !Instigator.IsLocallyControlled()  )
	{
		return;
	}

	StartFire(ALTFIRE_FIREMODE);
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

simulated state WeaponSingleFiring
{
	simulated event EndState( Name NextStateName )
	{
		Super.EndState(NextStateName);

		if (WorldInfo.NetMode == NM_Client && bAllowClientAmmoTracking && FireInterval[CurrentFireMode] <= MinFireIntervalToTriggerSync)
		{
			SyncCurrentAmmoCount(CurrentFireMode, AmmoCount[GetAmmoType(CurrentFireMode)]);
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

// Allows weapon to set its own trader stats (can set number of stats, names and values of stats)
static simulated event SetTraderWeaponStats( out array<STraderItemWeaponStats> WeaponStats )
{
	super.SetTraderWeaponStats( WeaponStats );

	WeaponStats.Length = WeaponStats.Length + 1;
	WeaponStats[WeaponStats.Length-1].StatType = TWS_RechargeTime;
	WeaponStats[WeaponStats.Length-1].StatValue = default.AltFullRechargeSeconds;
}

defaultproperties
{
	// Inventory
	InventorySize=6 //7
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Netscape_MAT.UI_WeaponSelect_Netscape'
	AssociatedPerkClasses(0)=class'KFPerk_Commando'
	AssociatedPerkClasses(1)=class'KFPerk_Swat'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
	MeshFOV=90
	MeshIronSightFOV=35 //20
    PlayerIronSightFOV=70

	// Zooming/Position
	//IronSightPosition=(X=15,Y=0.1,Z=-2.4) // old model
	IronSightPosition=(X=15,Y=0,Z=-0.4)
	PlayerViewOffset=(X=6.0,Y=14,Z=-3.5) //z -5.0

	// Content
	PackageKey="Netscape"
	FirstPersonMeshName="WEP_Netscape_MESH.WEP_1stP_Netscape_Rig"
	FirstPersonAnimSetNames(0)="WEP_Netscape_ARCH.Wep_1stP_Netscape_Anim"
	PickupMeshName="WEP_Netscape_MESH.WEP_Netscape_Pickup"
	AttachmentArchetypeName="WEP_Netscape_ARCH.WEP_Netscape_3P"
	MuzzleFlashTemplateName="WEP_Netscape_ARCH.Wep_Netscape_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=30
	SpareAmmoCapacity[0]=360 //390
	InitialSpareMags[0]=3
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=90
	minRecoilPitch=80
	maxRecoilYaw=90
	minRecoilYaw=-90
	RecoilRate=0.09
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=150
	RecoilISMinYawLimit=65385
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.6
	HippedRecoilModifier=1.5 //1.25

	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Netscape'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Netscape'
	InstantHitDamage(DEFAULT_FIREMODE)=50
	FireInterval(DEFAULT_FIREMODE)=+0.08 // 750 RPM
	PenetrationPower(DEFAULT_FIREMODE)=2.0
	Spread(DEFAULT_FIREMODE)=0.007
	FireOffset=(X=30,Y=4.5,Z=-4)

	// ALTFIRE_FIREMODE
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_NetscapeALT'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_NetscapeALT'
	InstantHitDamage(ALTFIRE_FIREMODE)=110 //130
	FireInterval(ALTFIRE_FIREMODE)=0.4 // 70 RPM
	PenetrationPower(ALTFIRE_FIREMODE)=0
	Spread(ALTFIRE_FIREMODE)=0.007

	SelfDamageReductionValue=0.10f; //0.16

	AltAmmo=100
	MagazineCapacity[1]=100
	AmmoCost(ALTFIRE_FIREMODE)=30 //20
	AltFullRechargeSeconds=15
	bCanRefillSecondaryAmmo=false;
    SecondaryAmmoTexture=Texture2D'DROW_MAT.UI_FireModeSelect_Percentage'
	// bAllowClientAmmoTracking=true

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_FNFAl'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Netscape_SND.NS_fire_3p_Cue', FirstPersonCue=SoundCue'WEP_Netscape_SND.NS_fire_1p_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Netscape_SND.NS_ALT_fire_3p_Cue', FirstPersonCue=SoundCue'WEP_Netscape_SND.NS_ALT_fire_1p_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_FNFAL.Play_WEP_FNFAL_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_FNFAL.Play_WEP_FNFAL_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Shooting Animations
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron2
	FireSightedAnims[2]=Shoot_Iron3

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Damage1, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
}