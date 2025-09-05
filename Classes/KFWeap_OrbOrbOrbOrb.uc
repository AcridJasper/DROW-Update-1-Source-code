class KFWeap_OrbOrbOrbOrb extends KFWeap_GrenadeLauncher_Base;

/** List of spawned harpoons (will be detonated oldest to youngest) */
var array<KFProj_KillerSphere_OrbOrbOrbOrb> DeployedHarpoons;
/** Same as DeployedHarpoons.Length, but replicated because harpoons are only tracked on server */
var int NumDeployedHarpoons;

replication
{
	if( bNetDirty )
		NumDeployedHarpoons;
}

/** Overridded to add spawned charge to list of spawned charges */
simulated function Projectile ProjectileFire()
{
	local Projectile P;
	local KFProj_KillerSphere_OrbOrbOrbOrb Harpoon;

	P = super.ProjectileFire();

	Harpoon = KFProj_KillerSphere_OrbOrbOrbOrb(P);
	if (Harpoon != none)
	{
		DeployedHarpoons.AddItem(Harpoon);
		NumDeployedHarpoons = DeployedHarpoons.Length;
		bForceNetUpdate = true;
	}

	return P;
}

	// When shoot, detonate harpoon and replace with new one
	// HarpoonActive();

/*
simulated function HarpoonActive()
{
	if (Role == ROLE_Authority)
	{
		Detonate();
	}
}

// Detonates all the harpoons
simulated function Detonate()
{
	local int i;

	// auto switch weapon when out of ammo and after detonating the last deployed charge
	if (Role == ROLE_Authority)
	{
		for (i = DeployedHarpoons.Length - 1; i >= 0; i--)
		{
			DeployedHarpoons[i].Detonate();
		}

		if (!HasAnyAmmo() && NumDeployedHarpoons == 0)
		{
			if (CanSwitchWeapons())
			{
	            Instigator.Controller.ClientSwitchToBestWeapon(false);
			}
		}
	}
}
*/

// Removes a charge from the list using either an index or an actor and updates NumDeployedHarpoons
function RemoveDeployedHarpoon(optional int HarpoonIndex = INDEX_NONE, optional Actor HarpoonActor)
{
	if (HarpoonIndex == INDEX_NONE)
	{
		if (HarpoonActor != none)
		{
			HarpoonIndex = DeployedHarpoons.Find(HarpoonActor);
		}
	}

	if (HarpoonIndex != INDEX_NONE)
	{
		DeployedHarpoons.Remove(HarpoonIndex, 1);
		NumDeployedHarpoons = DeployedHarpoons.Length;
		bForceNetUpdate = true;
	}
}

/** Returns animation to play based on reload type and status */
simulated function name GetReloadAnimName(bool bTacticalReload)
{
	// magazine relaod
	if (AmmoCount[0] > 0)
	{
		return (bTacticalReload) ? ReloadNonEmptyMagEliteAnim : ReloadNonEmptyMagAnim;
	}
	else
	{
		return (bTacticalReload) ? ReloadEmptyMagEliteAnim : ReloadEmptyMagAnim;
	}
}

// GrenadeLaunchers determine ShouldPlayFireLast based on the spare ammo
// overriding to use the base KFWeapon version since that uses the current ammo in the mag
simulated function bool ShouldPlayFireLast(byte FireModeNum)
{
	return Super(KFWeapon).ShouldPlayFireLast(FireModeNum);
}

// Returns trader filter index based on weapon type (copied from riflebase)
static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

defaultproperties
{
	// Inventory / Grouping
	InventorySize=6 //5 7
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_OrbOrbOrbOrb_MAT.UI_WeaponSelect_OrbOrbOrbOrb'
   	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=75
	MeshIronSightFOV=40
    PlayerIronSightFOV=65

	// Zooming/Position
	PlayerViewOffset=(X=11.0,Y=8,Z=-2)
	IronSightPosition=(X=10,Y=-0.15,Z=-2.2)
	
	// Content
	PackageKey="OrbOrbOrbOrb"
	FirstPersonMeshName="WEP_OrbOrbOrbOrb_MESH.WEP_1stP_OrbOrbOrbOrb_Rig"
	FirstPersonAnimSetNames(0)="WEP_OrbOrbOrbOrb_ARCH.WEP_1stP_OrbOrbOrbOrb_Anim"
	PickupMeshName="WEP_OrbOrbOrbOrb_MESH.WEP_OrbOrbOrbOrb_Pickup"
	AttachmentArchetypeName="WEP_OrbOrbOrbOrb_ARCH.Wep_OrbOrbOrbOrb_3P"
	MuzzleFlashTemplateName="WEP_OrbOrbOrbOrb_ARCH.Wep_OrbOrbOrbOrb_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=1
	SpareAmmoCapacity[0]=1 //4
	InitialSpareMags[0]=1
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// AI warning system
	bWarnAIWhenAiming=true
	AimWarningDelay=(X=0.4f, Y=0.8f)
	AimWarningCooldown=0.0f

	// Recoil
	maxRecoilPitch=500
	minRecoilPitch=400
	maxRecoilYaw=150
	minRecoilYaw=-150
	RecoilRate=0.08
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=1250
	RecoilMinPitchLimit=64785
	RecoilISMaxYawLimit=50
	RecoilISMinYawLimit=65485
	RecoilISMaxPitchLimit=500
	RecoilISMinPitchLimit=65485
	RecoilViewRotationScale=0.6
	IronSightMeshFOVCompensationScale=1.5

	// DEFAULT_FIREMODE (orb)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'DROW_MAT.UI_FireModeSelect_Orb' //orb
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_KillerSphere_OrbOrbOrbOrb'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_ThermiteBoreImpact'
	InstantHitDamage(DEFAULT_FIREMODE)=200
	FireInterval(DEFAULT_FIREMODE)=0.8 // 75 RPM
	Spread(DEFAULT_FIREMODE)=0
	PenetrationPower(DEFAULT_FIREMODE)=0 //40.0
	FireOffset=(X=25,Y=3.0,Z=-2.5)

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_ThermiteBore'
	InstantHitDamage(BASH_FIREMODE)=26

	// Custom animations
	FireSightedAnims=(Shoot_Iron)
	// BonesToLockOnEmpty=(RW_Exhaust, RW_BoltAssembly1, RW_BoltAssembly2, RW_BoltAssembly3)
	bHasFireLastAnims=true

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_Thermite.Play_WEP_Thermite_Thermite_Shoot_3P', FirstPersonCue=AkEvent'WW_WEP_Thermite.Play_WEP_Thermite_Thermite_Shoot_1P')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_Thermite.Play_WEP_Thermite_Dry_Fire'
	EjectedShellForegroundDuration=1.5f

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Medium_Recoil'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.125f), (Stat=EWUS_Weight, Add=1)))
}