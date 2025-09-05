class KFWeap_Encore extends KFWeap_GrenadeLauncher_CylinderBase;

var float ReloadAnimRateModifier;
var float ReloadAnimRateModifierElite;

/** List of spawned harpoons (will be detonated oldest to youngest) */
var array<KFProj_HighExplosive_Encore> DeployedHarpoons;

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
	local KFProj_HighExplosive_Encore Harpoon;

	P = super.ProjectileFire();

	Harpoon = KFProj_HighExplosive_Encore(P);
	if (Harpoon != none)
	{
		DeployedHarpoons.AddItem(Harpoon);
		NumDeployedHarpoons = DeployedHarpoons.Length;
		bForceNetUpdate = true;
	}

	return P;
}

/** Removes a charge from the list using either an index or an actor and updates NumDeployedHarpoons */
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

/** Returns an anim rate scale for reloading */
simulated function float GetReloadRateScale()
{
	local float Modifier;

	Modifier = UseTacticalReload() ? ReloadAnimRateModifierElite : ReloadAnimRateModifier;

	return super.GetReloadRateScale() * Modifier;
}

defaultproperties
{
	// Inventory
	InventoryGroup=IG_Primary
	GroupPriority=21 // funny number
	InventorySize=5 //9
	WeaponSelectTexture=Texture2D'WEP_Encore_MAT.UI_WeaponSelect_Encore'
	AssociatedPerkClasses(0)=class'KFPerk_Survivalist'
	// AssociatedPerkClasses(1)=class'KFPerk_Demolitionist'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

    // FOV
	MeshIronSightFOV=82
    PlayerIronSightFOV=82

	// Zooming/Position
	PlayerViewOffset=(X=19.0,Y=13,Z=-2)
	// IronSightPosition=(X=0,Y=0,Z=0)
	IronSightPosition=(X=12.0,Y=12.0,Z=1.3)
	FastZoomOutTime=0.2

	// Content
	PackageKey="Encore"
	FirstPersonMeshName="WEP_Encore_MESH.Wep_1stP_Encore_Rig"
	FirstPersonAnimSetNames(0)="WEP_Encore_ARCH.Wep_1stP_Encore_Anim"
	PickupMeshName="WEP_Encore_MESH.Wep_Encore_Pickup"
	AttachmentArchetypeName="WEP_Encore_ARCH.Wep_M32_Encore_3P" //WEP_Encore_ARCH.Wep_Encore_3P WEP_Encore_ARCH.WEP_Encore_3P_Rate
	MuzzleFlashTemplateName="WEP_Encore_ARCH.Wep_Encore_MuzzleFlash"

	Begin Object Name=FirstPersonMesh
		// new anim tree with skelcontrol to rotate cylinders
		AnimTreeTemplate=AnimTree'CHR_1P_Arms_ARCH.WEP_1stP_Animtree_Master_Revolver'
	End Object

	// Ammo
	MagazineCapacity[0]=6
	SpareAmmoCapacity[0]=36 //24
	InitialSpareMags[0]=2
	AmmoPickupScale[0]=1.0
	bCanBeReloaded=true
	bReloadFromMagazine=false
	ForceReloadTime=0.0f

	// Recoil
	maxRecoilPitch=700 //600
	minRecoilPitch=675
	maxRecoilYaw=300
	minRecoilYaw=-300
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

	// DEFAULT_FIREMODE (lobs proximity mines that explode nearby zeds)
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Grenade'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponFiring //WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_HighExplosive_Encore'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Ballistic_EncoreImpact'
	FireInterval(DEFAULT_FIREMODE)=+0.20 //+0.25
	InstantHitDamage(DEFAULT_FIREMODE)=150.0
	Spread(DEFAULT_FIREMODE)=0.015
	PenetrationPower(DEFAULT_FIREMODE)=0.0
	FireOffset=(X=23,Y=4.0,Z=-3)

	ReloadAnimRateModifier=0.6f
	ReloadAnimRateModifierElite=0.7f;

	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None

	// BASH_FIREMODE
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_M32'
	InstantHitDamage(BASH_FIREMODE)=26 //25

	// Fire Effects
	WeaponFireSnd(DEFAULT_FIREMODE)=(DefaultCue=AkEvent'WW_WEP_M32.Play_M32_Fire_3P_Single', FirstPersonCue=AkEvent'WW_WEP_M32.Play_M32_Fire_1P_Single')
	WeaponDryFireSnd(DEFAULT_FIREMODE)=AkEvent'WW_WEP_M32.Play_M32_DryFire'

	// Animation
	bHasFireLastAnims=true

	// Attachments
	bHasIronSights=true
	bHasFlashlight=false

	// Advanced (High RPM) Fire Effects (WeaponFiring)
	bLoopingFireAnim(DEFAULT_FIREMODE)=false
	bLoopingFireSnd(DEFAULT_FIREMODE)=false

	WeaponFireWaveForm=ForceFeedbackWaveform'FX_ForceFeedback_ARCH.Gunfire.Heavy_Recoil_SingleShot'

	// Revolver
	bRevolver=true
	CylinderRotInfo=(Inc=60, Time=0.0875/*about 0.35 in the anim divided by ratescale of 4*/)

	// Revolver shell/cap replacement
	
	BulletFXSocketNames=(RW_Bullet_FX_1, RW_Bullet_FX_2, RW_Bullet_FX_3, RW_Bullet_FX_4, RW_Bullet_FX_5, RW_Bullet_FX_6)
	ShellBoneNames=(RW_Shell3, RW_Shell2, RW_Shell1, RW_Shell6, RW_Shell5, RW_Shell4)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp0
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp0)
	BulletMeshComponents.Add(BulletMeshComp0)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp1
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp1)
	BulletMeshComponents.Add(BulletMeshComp1)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp2
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp2)
	BulletMeshComponents.Add(BulletMeshComp2)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp3
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp3)
	BulletMeshComponents.Add(BulletMeshComp3)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp4
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp4)
	BulletMeshComponents.Add(BulletMeshComp4)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp5
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp5)
	BulletMeshComponents.Add(BulletMeshComp5)

	Begin Object Class=KFBulletSkeletalMeshComponent Name=BulletMeshComp6
		SkeletalMesh=SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UnusedBulletMeshTemplate = SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		UsedBulletMeshTemplate = none //SkeletalMesh'WEP_Encore_MESH.Wep_1stP_Encore_Shell'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		bAcceptsStaticDecals=false
		bAcceptsDecals=false
		CastShadow=false
		bUseAsOccluder=false
		DepthPriorityGroup=SDPG_Foreground // First person only
	End Object
	Components.Add(BulletMeshComp6)
	ReloadShell=BulletMeshComp6

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.25f), (Stat=EWUS_Weight, Add=1)))
}