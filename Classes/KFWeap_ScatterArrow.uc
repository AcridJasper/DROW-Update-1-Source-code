class KFWeap_ScatterArrow extends KFWeap_ScopedBase;

var protected const array<vector2D> PelletSpread;

// Disable normal bullet spread
simulated function rotator AddSpread(rotator BaseAim)
{
	return BaseAim; // do nothing
}

// Returns number of projectiles to fire from SpawnProjectile
simulated function byte GetNumProjectilesToFire(byte FireModeNum)
{
	return NumPellets[CurrentFireMode];
}

// Same as AddSpread(), but used with MultiShotSpread
static function rotator AddMultiShotSpread( rotator BaseAim, float CurrentSpread, byte PelletNum )
{
	local vector X, Y, Z;
	local float RandY, RandZ;

	if (CurrentSpread == 0) // 0.3214
	{
		return BaseAim;
	}
	else
	{
        // No randomized spread, it's controlled in PelletSpread down bellow
		GetAxes(BaseAim, X, Y, Z);
		RandY = default.PelletSpread[PelletNum].Y; //* RandRange( 0.5f, 1.5f
		RandZ = default.PelletSpread[PelletNum].X;
		return rotator(X + RandY * CurrentSpread * Y + RandZ * CurrentSpread * Z);
	}
}

// Tight choke skill - remove if you want slugs ("combines" 9 bullets into one)
simulated function KFProjectile SpawnAllProjectiles(class<KFProjectile> KFProjClass, vector RealStartLoc, vector AimDir)
{
	local KFPerk InstigatorPerk;

	if (CurrentFireMode == DEFAULT_FIREMODE)
	{
		InstigatorPerk = GetPerk();
		if (InstigatorPerk != none)
		{
			Spread[CurrentFireMode] = default.Spread[CurrentFireMode] * InstigatorPerk.GetTightChokeModifier();
		}
	}

	return super.SpawnAllProjectiles(KFProjClass, RealStartLoc, AimDir);
}

/** Instead of switch fire mode use as immediate alt fire */
simulated function AltFireMode()
{
	// StartFire - StopFire called from KFPlayerInput
	StartFire(ALTFIRE_FIREMODE);
}

/** Return true if this weapon should play the fire last animation for this shoot animation */
simulated function bool ShouldPlayFireLast(byte FireModeNum)
{
    if( SpareAmmoCount[GetAmmoType(FireModeNum)] == 0 )
    {
        return true;
    }

    return false;
}

/** Returns animation to play based on reload type and status */
simulated function name GetReloadAnimName( bool bTacticalReload )
{
	if ( AmmoCount[0] > 0 )
	{
		// Disable half-reloads for now.  This can happen if server gets out
		// of sync, but choosing the wrong animation will just make it worse!
		`warn("Grenade launcher reloading with non-empty mag");
	}

	return bTacticalReload ? ReloadEmptyMagEliteAnim : ReloadEmptyMagAnim;
}

/** Returns trader filter index based on weapon type (copied from riflebase) */
static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

defaultproperties
{
	// Inventory
	InventorySize=5 //6
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_ScatterArrow_MAT.UI_WeaponSelect_ScatterArrow'
   	AssociatedPerkClasses(0)=class'KFPerk_Sharpshooter'
   	// AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=70
	MeshIronSightFOV=62 //52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=1,Y=8,Z=-5)
	IronSightPosition=(X=-13,Y=0,Z=-0.061)

    // 2D scene capture
	Begin Object Name=SceneCapture2DComponent0
	   TextureTarget=TextureRenderTarget2D'Wep_Mat_Lib.WEP_ScopeLense_Target'
	   FieldOfView=18.5 // "2.0X" = 37(our real world FOV determinant)/2.0
	End Object

	ScopedSensitivityMod=12.0
	ScopeLenseMICTemplate=MaterialInstanceConstant'WEP_ScatterArrow_MAT.WEP_1P_ScatterArrow_Reticle_MAT'
	ScopeMICIndex=1

	// Content
	PackageKey="ScatterArrow"
	FirstPersonMeshName="WEP_ScatterArrow_MESH.Wep_1stP_ScatterArrow_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_HRG_Crossboom_ANIM.Wep_1stP_HRG_Crossboom_Anim"
	PickupMeshName="WEP_ScatterArrow_MESH.Wep_ScatterArrow_Pickup"
	AttachmentArchetypeName="WEP_ScatterArrow_ARCH.Wep_ScatterArrow_3P"
	MuzzleFlashTemplateName="WEP_ScatterArrow_ARCH.Wep_ScatterArrow_MuzzleFlash"

	// AI warning system
	bWarnAIWhenAiming=true
    MaxAIWarningDistSQ=4000000
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=30
	InitialSpareMags[0]=11
	AmmoPickupScale[0]=4.0 // 4 arrows
	bCanBeReloaded=true
	bReloadFromMagazine=true // reloading from mag is one step, while NOT reloading from mag is multi-step (open bolt, load ammo, close bolt) and not applicable for bow
	// Just like the launchers, this weapon has mag size of 1 and force reload which
	// causes significant ammo sync issues.  This fix is far from perfect, but it helps.
	bAllowClientAmmoTracking=true

	// Recoil
	maxRecoilPitch=200
	minRecoilPitch=150
	maxRecoilYaw=100
	minRecoilYaw=-100
	RecoilRate=0.06
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460

	// DEFAULT_FIREMODE (Custom spread shot)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletArrow'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bolt_ShotgunArrow'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Piercing_ScatterArrow'
	InstantHitDamage(DEFAULT_FIREMODE)=85 //95 115
	PenetrationPower(DEFAULT_FIREMODE)=6.0
	FireInterval(DEFAULT_FIREMODE)=0.3 // For this weapon, this is not the fire rate, but the time when the auto reload anim kicks in
	FireOffset=(X=25,Y=3.0,Z=-4.0)

	Spread(DEFAULT_FIREMODE)=0.1f
	NumPellets(DEFAULT_FIREMODE)=5
	PelletSpread(0)=(X=0.0f,Y=0.0f) //middle
	PelletSpread(1)=(X=0.2f,Y=0.2f)
	PelletSpread(2)=(X=0.2f,Y=-0.2f)
	PelletSpread(3)=(X=-0.2f,Y=0.2f)
	PelletSpread(4)=(X=-0.2f,Y=-0.2f)

	// ALT_FIREMODE (On impact spawns 5 arrows that bounce 4 times)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletArrow'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFireAndReload
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bolt_ScatterArrow'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Piercing_ScatterArrow'
	InstantHitDamage(ALTFIRE_FIREMODE)=225 //70
	PenetrationPower(ALTFIRE_FIREMODE)=0
	FireInterval(ALTFIRE_FIREMODE)=0.3 // For this weapon, this is not the fire rate, but the time when the auto reload anim kicks in
	Spread(ALTFIRE_FIREMODE)=0.007 //0.007
	NumPellets(ALTFIRE_FIREMODE)=1

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_Fire_1P')
	WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_Fire_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_HRG_Crossboom.Play_WEP_HRG_Crossboom_DryFire'

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HRG_Crossboom'
	InstantHitDamage(BASH_FIREMODE)=26

	// Custom animations
	FireSightedAnims=(Shoot_Iron, Shoot_Iron2, Shoot_Iron3)
	BonesToLockOnEmpty=(RW_Cable_Parent)

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.15f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.4f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Weight, Add=2)))
}