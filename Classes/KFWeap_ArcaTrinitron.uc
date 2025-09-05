class KFWeap_ArcaTrinitron extends KFWeapon; //KFWeap_ShotgunBase

struct WeaponFireSoundInfo
{
	var() SoundCue	DefaultCue;
	var() SoundCue	FirstPersonCue;
};

var(Sounds) array<WeaponFireSoundInfo> WeaponFireSound;

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

// Returns trader filter index based on weapon type (copied from riflebase)
static simulated event EFilterTypeUI GetTraderFilter()
{
    return FT_Projectile;
}

defaultproperties
{
	// Inventory
	InventorySize=5
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_ArcaTrinitron_MAT.UI_WeaponSelect_ArcaTrinitron'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
    MeshFOV=75
	MeshIronSightFOV=52
    PlayerIronSightFOV=70

	// Zooming/Position
	PlayerViewOffset=(X=20,Y=7.6,Z=-3.0)
	IronSightPosition=(X=6.0,Y=0,Z=-2.3)

	// Content
	PackageKey="ArcaTrinitron"
	FirstPersonMeshName="WEP_ArcaTrinitron_MESH.Wep_1stP_ArcaTrinitron_Rig"
	FirstPersonAnimSetNames(0)="WEP_ArcaTrinitron_ARCH.Wep_1stP_ArcaTrinitron_Anim"
	PickupMeshName="WEP_ArcaTrinitron_MESH.Wep_ArcaTrinitron_Pickup"
	AttachmentArchetypeName="WEP_ArcaTrinitron_ARCH.Wep_ArcaTrinitron_3P"
	MuzzleFlashTemplateName="WEP_ArcaTrinitron_ARCH.Wep_ArcaTrinitron_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=10
	SpareAmmoCapacity[0]=70 //80
	InitialSpareMags[0]=1
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=900
	minRecoilPitch=775
	maxRecoilYaw=500
	minRecoilYaw=-500
	RecoilRate=0.085
	RecoilBlendOutRatio=1.1 //0.35
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
	FireModeIconPaths(DEFAULT_FIREMODE)="ui_firemodes_tex.UI_FireModeSelect_Grenade"
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_ArcaTrinitron'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_ArcaTrinitron'
	InstantHitDamage(DEFAULT_FIREMODE)=250 //300
	PenetrationPower(DEFAULT_FIREMODE)=40.0
	PenetrationDamageReductionCurve(DEFAULT_FIREMODE)=(Points=((InVal=0.f,OutVal=0.f),(InVal=2.f, OutVal=2.f)))
	FireInterval(DEFAULT_FIREMODE)=0.8 // 75 RPM
	Spread(DEFAULT_FIREMODE)=0.015
	NumPellets(DEFAULT_FIREMODE)=1
	FireOffset=(X=30,Y=3,Z=-3)

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_HZ12'
	InstantHitDamage(BASH_FIREMODE)=25

	// Fire Effects
	//WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HZ12.Play_WEP_HZ12_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HZ12.Play_WEP_HZ12_Fire_1P')
    //WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_HZ12.Play_WEP_HZ12_Fire_3P', FirstPersonCue=AkEvent'WW_WEP_HZ12.Play_WEP_HZ12_Fire_1P')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_ArcaTrinitron_SND.arca_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_ArcaTrinitron_SND.arca_fire_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_ArcaTrinitron_SND.arca_fire_3P_Cue', FirstPersonCue=SoundCue'WEP_ArcaTrinitron_SND.arca_fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_M4.Play_WEP_SA_M4_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_M4.Play_WEP_SA_M4_Handling_DryFire'

	// Attachments
	bHasIronSights=true
	bHasFlashlight=true

	// Animation
	bHasFireLastAnims=true

	AssociatedPerkClasses(0)=class'KFPerk_Support'

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.35f), (Stat=EWUS_Weight, Add=2)))
}