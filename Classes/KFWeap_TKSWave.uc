class KFWeap_TKSWave extends KFWeap_ShotgunBase;

var(Spread) const float SpreadWidthDegrees;
var(Spread) const float SpreadWidthDegreesAlt;

var transient float StartingPelletPosition;
var transient float StartingPelletPositionAlt;

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();

    Spread[DEFAULT_FIREMODE] = SpreadWidthDegrees * DegToRad / NumPellets[DEFAULT_FIREMODE];
    Spread[ALTFIRE_FIREMODE] = SpreadWidthDegreesAlt * DegToRad / NumPellets[ALTFIRE_FIREMODE];

    StartingPelletPosition = -SpreadWidthDegrees * DegToRad / 2.0f;
    StartingPelletPositionAlt = -SpreadWidthDegreesAlt * DegToRad / 2.0f;
}

/** Returns number of projectiles to fire from SpawnProjectile */
simulated function byte GetNumProjectilesToFire(byte FireModeNum)
{
	return NumPellets[CurrentFireMode];
}

simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local int ProjectilesToFire, i;
    local float InitialOffset;

	ProjectilesToFire = GetNumProjectilesToFire(CurrentFireMode);
	if (CurrentFireMode == GRENADE_FIREMODE || ProjectilesToFire <= 1)
	{
		return SpawnProjectile(KFProjClass, RealStartLoc, AimDir);
	}

    InitialOffset = CurrentFireMode == DEFAULT_FIREMODE ? StartingPelletPosition : StartingPelletPositionAlt;

	for (i = 0; i < ProjectilesToFire; i++)
	{
		SpawnProjectile(KFProjClass, RealStartLoc, CalculateSpread(InitialOffset, Spread[CurrentFireMode], i, CurrentFireMode == ALTFIRE_FIREMODE));
	}
	
	return None;
}

simulated function vector CalculateSpread(float InitialOffset, float CurrentSpread, byte PelletNum, bool bHorizontal)
{
    local Vector X, Y, Z, POVLoc;
    local Quat R;
	local rotator POVRot;

	if (Instigator != None && Instigator.Controller != none)
	{
		Instigator.Controller.GetPlayerViewPoint(POVLoc, POVRot);
	}

    GetAxes(POVRot, X, Y, Z);

    R = QuatFromAxisAndAngle(bHorizontal ? Y : Z, InitialOffset + CurrentSpread * PelletNum);
    return QuatRotateVector(R, vector(POVRot));
}

// Returns animation to play based on reload type and status (reloads both shells after third shot)
simulated function name GetReloadAnimName(bool bTacticalReload)
{
	if ( AmmoCount[0] < 99 ) //3
	{
		return (bTacticalReload) ? ReloadEmptyMagEliteAnim : ReloadEmptyMagAnim; //empty
	}
	else
	{
		return (bTacticalReload) ? ReloadNonEmptyMagEliteAnim : ReloadNonEmptyMagAnim; //half
	}
}

/** Returns trader filter index based on weapon type */
static simulated event EFilterTypeUI GetTraderFilter()
{
	return FT_Projectile;
}

defaultproperties
{
	// Inventory
	InventorySize=4
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_TKSWave_MAT.UI_WeaponSelect_TKSWave'
	AssociatedPerkClasses(0)=class'KFPerk_Support'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=75
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=4.0,Y=7.0,Z=-5.0)
	IronSightPosition=(X=3,Y=0,Z=-2.1)

	// Content
	PackageKey="TKSWave"
	FirstPersonMeshName="WEP_TKSWave_MESH.Wep_1stP_TKSWave_Rig"
	FirstPersonAnimSetNames(0)="WEP_FlakCannonDROW_ARCH.Wep_1stP_FlakCannonDROW_Anim"
	PickupMeshName="WEP_TKSWave_MESH.Wep_TKSWave_Pickup"
	AttachmentArchetypeName="WEP_TKSWave_ARCH.Wep_TKSWave_3P"
	MuzzleFlashTemplateName="WEP_TKSWave_ARCH.Wep_TKSWave_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=4
	SpareAmmoCapacity[0]=84 //92
	InitialSpareMags[0]=11
	AmmoPickupScale[0]=3.0
	bCanBeReloaded=true
	bReloadFromMagazine=true
	bNoMagazine=true

	// Recoil
	maxRecoilPitch=500 //900
	minRecoilPitch=480 //775
	maxRecoilYaw=150 //500
	minRecoilYaw=-150 //-500
	RecoilRate=0.085
	RecoilBlendOutRatio=1.1
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
	HippedRecoilModifier=1.20 //1.25

	// DEFAULT_FIREMODE (Fires horizontal spread of bullets)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'DROW_MAT.UI_FireModeSelect_Orb' //ui_firemodes_tex.UI_FireModeSelect_ShotgunSingle
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_TKSWave'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_TKSWave'
	FireInterval(DEFAULT_FIREMODE)=0.25 // 240 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=50 //40
	PenetrationPower(DEFAULT_FIREMODE)=14
	NumPellets(DEFAULT_FIREMODE)=8
	Spread(DEFAULT_FIREMODE)=0
	AmmoCost(ALTFIRE_FIREMODE)=1
	FireOffset=(X=25,Y=3.5,Z=-4)
	// ForceReloadTimeOnEmpty=0.3

    SpreadWidthDegrees=6.0f
    SpreadWidthDegreesAlt=6.0f

    StartingPelletPosition=0.0f
    StartingPelletPositionAlt=0.0f

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_DBShotgun'
	InstantHitDamage(BASH_FIREMODE)=24

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_Shotgun.Play_SA_WEP_DoubleBarrel_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Animations
	FireAnim=Shoot_Single
	FireSightedAnims[0]=Shoot_Iron_Single
    bHasFireLastAnims=false

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.05f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.1f), (Stat=EWUS_Weight, Add=2)))
	WeaponUpgrades[3]=(Stats=((Stat=EWUS_Damage0, Scale=1.15f), (Stat=EWUS_Weight, Add=3)))
}