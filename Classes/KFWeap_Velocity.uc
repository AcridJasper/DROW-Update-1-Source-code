class KFWeap_Velocity extends KFWeap_SMGBase;

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

defaultproperties
{
	// Inventory
	InventorySize=5
	GroupPriority=21 // funny number
	WeaponSelectTexture=Texture2D'WEP_Velocity_MAT.UI_WeaponSelect_Velocity'
	AssociatedPerkClasses(0)=class'KFPerk_Swat'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Rare_DROW' // Loot beam fx (no offset)

	// FOV
	MeshFOV=81
	MeshIronSightFOV=55
	PlayerIronSightFOV=70

	// Zooming/Position
	IronSightPosition=(X=5,Y=-0.1,Z=-0.1)
	PlayerViewOffset=(X=18.5f,Y=10.25f,Z=-4.0f)

	// Content
	PackageKey="Velocity"
	FirstPersonMeshName="WEP_Velocity_MESH.Wep_1stP_Velocity_Rig"
	FirstPersonAnimSetNames(0)="wep_1p_mp7_anim.wep_1p_mp7_anim"
	PickupMeshName="WEP_Velocity_MESH.Wep_Velocity_Pickup"
	AttachmentArchetypeName="WEP_Velocity_ARCH.WEP_Velocity_Trail_3P"
	MuzzleFlashTemplateName="WEP_Velocity_ARCH.Wep_Velocity_MuzzleFlash"

	// Ammo
	MagazineCapacity[0]=30
	SpareAmmoCapacity[0]=390
	InitialSpareMags[0]=3
	AmmoPickupScale[0]=2
	bCanBeReloaded=true
	bReloadFromMagazine=true

	// Recoil
	maxRecoilPitch=50
	minRecoilPitch=40
	maxRecoilYaw=80
	minRecoilYaw=-80
	RecoilRate=0.06
	RecoilMaxYawLimit=500
	RecoilMinYawLimit=65035
	RecoilMaxPitchLimit=900
	RecoilMinPitchLimit=65035
	RecoilISMaxYawLimit=75
	RecoilISMinYawLimit=65460
	RecoilISMaxPitchLimit=375
	RecoilISMinPitchLimit=65460
	IronSightMeshFOVCompensationScale=1.5
	WalkingRecoilModifier=1.1
	JoggingRecoilModifier=1.2

	// DEFAULT_FIREMODE (Freezing bullets)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletAuto'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Velocity'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_Velocity'
	FireInterval(DEFAULT_FIREMODE)=+.075 // 800 RPM +.067 // 900 RPM //+.063 // 950 RPM
	InstantHitDamage(DEFAULT_FIREMODE)=32
	Spread(DEFAULT_FIREMODE)=0.016
	FireOffset=(X=30,Y=4.5,Z=-5)

	// ALT_FIREMODE (Freezing bullets in burst fire mode)
	FireModeIconPaths(ALTFIRE_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletBurst'
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponBurstFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'KFProj_Bullet_Velocity'
	InstantHitDamageTypes(ALTFIRE_FIREMODE)=class'KFDT_Ballistic_Velocity'
	FireInterval(ALTFIRE_FIREMODE)=+.063 // 950 RPM
	InstantHitDamage(ALTFIRE_FIREMODE)=32
	Spread(ALTFIRE_FIREMODE)=0.016
	BurstAmount=4
	
	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_MP7'
	InstantHitDamage(BASH_FIREMODE)=24

    // Fire Effects
	// WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_MP7.Play_MP7_Fire_3P_Loop', FirstPersonCue=AkEvent'WW_WEP_MP7.Play_MP7_Fire_1P_Loop')
	// WeaponFireSnd(ALTFIRE_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_MP7.Play_MP7_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_MP7.Play_MP7_Fire_1P_Single')
	WeaponFireSound(DEFAULT_FIREMODE)=(DefaultCue=SoundCue'WEP_Velocity_SND.Velocity_Fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Velocity_SND.Velocity_Fire_Cue')
	WeaponFireSound(ALTFIRE_FIREMODE)=(DefaultCue=SoundCue'WEP_Velocity_SND.Velocity_Fire_3P_Cue', FirstPersonCue=SoundCue'WEP_Velocity_SND.Velocity_Fire_Cue')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_SA_MedicSMG.Play_SA_MedicSMG_Handling_DryFire'
	WeaponDryFireSnd(ALTFIRE_FIREMODE)=AkEvent'WW_WEP_SA_MedicSMG.Play_SA_MedicSMG_Handling_DryFire'

	// Advanced (High RPM) Fire Effects
	bLoopingFireAnim(DEFAULT_FIREMODE)=true
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false
	bHasLaserSight=true
	LaserSightTemplate=KFLaserSightAttachment'FX_LaserSight_ARCH.LaserSight_WithAttachment_1P'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.13f), (Stat=EWUS_Damage1, Scale=1.13f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.24f), (Stat=EWUS_Damage1, Scale=1.24f), (Stat=EWUS_Weight, Add=2)))
}