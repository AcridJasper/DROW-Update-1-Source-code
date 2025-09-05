class KFWeap_Bouncer extends KFWeapon;

/** Reduction for the amount of damage dealt to the weapon owner (including damage by the explosion) */
var() float SelfDamageReductionValue;

// How many DEF ammo to recharge per second
var float DEFFullRechargeSeconds;
var transient float DEFRechargePerSecond;
var transient float DEFIncrement;
var repnotify byte DEFAmmo;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		DEFAmmo;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == nameof(DEFAmmo))
	{
		AmmoCount[DEFAULT_FIREMODE] = DEFAmmo;
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	StartDEFRecharge();
}

function StartDEFRecharge()
{
	// local KFPerk InstigatorPerk;
	local float UsedDEFRechargeTime;

	// begin ammo recharge on server
	if( Role == ROLE_Authority )
	{
		UsedDEFRechargeTime = DEFFullRechargeSeconds;
	    DEFRechargePerSecond = MagazineCapacity[DEFAULT_FIREMODE] / UsedDEFRechargeTime;
		DEFIncrement = 0;
	}
}

function RechargeDEF(float DeltaTime)
{
	if ( Role == ROLE_Authority )
	{
		DEFIncrement += DEFRechargePerSecond * DeltaTime;

		if( DEFIncrement >= 1.0 && AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
		{
			AmmoCount[DEFAULT_FIREMODE]++;
			DEFIncrement -= 1.0;
			DEFAmmo = AmmoCount[DEFAULT_FIREMODE];
		}
	}
}

// Overridden to call StartHealRecharge on server
function GivenTo( Pawn thisPawn, optional bool bDoNotActivate )
{
	super.GivenTo( thisPawn, bDoNotActivate );

	if( Role == ROLE_Authority && !thisPawn.IsLocallyControlled() )
	{
		StartDEFRecharge();
	}
}

simulated event Tick( FLOAT DeltaTime )
{
    if( AmmoCount[DEFAULT_FIREMODE] < MagazineCapacity[DEFAULT_FIREMODE] )
	{
        RechargeDEF(DeltaTime);
	}

	Super.Tick(DeltaTime);
}

simulated function bool ShouldAutoReload(byte FireModeNum)
{
	if (FireModeNum == DEFAULT_FIREMODE)
		return false;
	
	return super.ShouldAutoReload(FireModeNum);
}

simulated function string GetSpecialAmmoForHUD()
{
	return int(DEFAmmo)$"%";
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

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Explosive;
}

defaultproperties
{
    // Inventory
	InventorySize=4 //8
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Bouncer_MAT.UI_WeaponSelect_Bouncer'
   	AssociatedPerkClasses(0)=class'KFPerk_Demolitionist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

    // FOV
    Meshfov=80
	MeshIronSightFOV=65 //52
    PlayerIronSightFOV=50 //80

   	// Zooming/Position
	PlayerViewOffset=(X=0.0,Y=12,Z=-1)
	IronSightPosition=(X=0,Y=0,Z=0)
	
	// Content
	PackageKey="Bouncer"
	FirstPersonMeshName="WEP_Bouncer_MESH.Wep_1stP_Bouncer_Rig"
	FirstPersonAnimSetNames(0)="WEP_Bouncer_ARCH.Wep_1stP_Bouncer_Anim"
	PickupMeshName="WEP_Bouncer_MESH.Wep_Bouncer_Pickup"
	AttachmentArchetypeName="WEP_Bouncer_ARCH.Wep_Bouncer_3P"
	MuzzleFlashTemplateName="WEP_Bouncer_ARCH.Wep_Bouncer_MuzzleFlash"

	// Controls the rotation when Hans(the bastard) grabs you
	QuickWeaponDownRotation=(Pitch=-19192,Yaw=-11500,Roll=16384) // (Pitch=-19192,Yaw=-11000,Roll=16384)

	// Ammo
	SpareAmmoCapacity[0]=0
	InitialSpareMags[0]=0
	AmmoPickupScale[0]=0
	bCanBeReloaded=false
	bReloadFromMagazine=false

	// Recoil
	maxRecoilPitch=150
	minRecoilPitch=115
	maxRecoilYaw=115
	minRecoilYaw=-115
	RecoilRate=0.085
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	RecoilViewRotationScale=0.25
	IronSightMeshFOVCompensationScale=1.5
    HippedRecoilModifier=1.5

	// DEFAULT_FIREMODE (Explosive bouncing fuze bomb that spawns dropplet bombs)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Grenade'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
    WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Shell_Bouncer'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_BludgeonShell_Bouncer'
	FireInterval(DEFAULT_FIREMODE)=0.8 //100 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=140
	Spread(DEFAULT_FIREMODE)=0.0
	PenetrationPower(DEFAULT_FIREMODE)=0.0;
	FireOffset=(X=30,Y=4.5,Z=-5)

	DEFAmmo=100
	MagazineCapacity[0]=100
	AmmoCost(DEFAULT_FIREMODE)=50
	DEFFullRechargeSeconds=10 //10 15
	// bAllowClientAmmoTracking=true

	SelfDamageReductionValue=0.10f; //0.16

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_Mine_Reconstructor'
	InstantHitDamage(BASH_FIREMODE)=26

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_BallisticBouncer.Play_WEP_HRG_BallisticBouncer_3P_Shoot', FirstPersonCue=AkEvent'WW_WEP_HRG_BallisticBouncer.Play_WEP_HRG_BallisticBouncer_1P_Shoot')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_BallisticBouncer.Play_WEP_HRG_BallisticBouncer_3P_Shoot', FirstPersonCue=AkEvent'WW_WEP_HRG_BallisticBouncer.Play_WEP_HRG_BallisticBouncer_1P_Shoot')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_Flamethrower.Play_WEP_SA_Flamethrower_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_Flamethrower.Play_WEP_SA_Flamethrower_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	FireAnim=Shoot
	FireSightedAnims[0]=Shoot_Iron
	FireSightedAnims[1]=Shoot_Iron
	FireSightedAnims[2]=Shoot_Iron

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Weak_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.3f), (Stat=EWUS_Weight, Add=2)))
}