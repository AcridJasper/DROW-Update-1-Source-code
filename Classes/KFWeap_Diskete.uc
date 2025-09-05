class KFWeap_Diskete extends KFWeap_Eviscerator;

var transient KFParticleSystemComponent FirePSC;
var const ParticleSystem FireFXTemplate;

simulated state WeaponEquipping
{
	simulated event BeginState( name PreviousStateName )
	{
		super.BeginState( PreviousStateName );

		ActivatePSC(FirePSC, FireFXTemplate, 'MuzzleFlash');
	}
}

simulated function ActivatePSC(out KFParticleSystemComponent OutPSC, ParticleSystem ParticleEffect, name SocketName)
{
	if (MySkelMesh != none)
	{
		MySkelMesh.AttachComponentToSocket(OutPSC, SocketName);
		OutPSC.SetFOV(MySkelMesh.FOV);
	}
	else
	{
		AttachComponent(OutPSC);
	}

	OutPSC.ActivateSystem();

	if (OutPSC != none)
	{
		OutPSC.SetTemplate(ParticleEffect);
		OutPSC.SetDepthPriorityGroup(SDPG_Foreground);
	}
}

auto state Inactive
{
	simulated function BeginState(name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);
		StopIdleMotorSound();

		if (FirePSC != none)
		{
			FirePSC.DeactivateSystem();
		}
	}
}

defaultproperties
{
	// Inventory
	GroupPriority=21 // funny number
	InventorySize=7 // 8
	InventoryGroup=IG_Primary
	WeaponSelectTexture=Texture2D'WEP_Diskete_MAT.UI_WeaponSelect_Diskete'
	SecondaryAmmoTexture=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Electricity'

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

	// Content
	PackageKey="Diskete"
	FirstPersonMeshName="WEP_Diskete_MESH.Wep_1stP_Diskete_Rig"
	FirstPersonAnimSetNames(0)="WEP_1P_SawBlade_ANIM.WEP_1P_SawBlade_ANIM"
	FirstPersonAnimTree="WEP_1P_SawBlade_ANIM.1P_Sawblade_Animtree"
	PickupMeshName="WEP_Diskete_MESH.Wep_Diskete_Pickup"
	AttachmentArchetypeName="WEP_Diskete_ARCH.WEP_DisketePSC_3P"
	MuzzleFlashTemplateName="WEP_Sawblade_ARCH.Wep_Sawblade_MuzzleFlash"

	// Ammo
	bCanBeReloaded=true
	bReloadFromMagazine=true
	MagazineCapacity[0]=5
	SpareAmmoCapacity[0]=25
	InitialSpareMags[0]=0
	MagazineCapacity[1]=250 // 30 seconds of fuel
	AmmoPickupScale[1]=0.2
	
	// DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_Sawblade'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_Projectile
	WeaponProjectiles(DEFAULT_FIREMODE)=class'KFProj_Bullet_Diskete'
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Slashing_Diskete'
	InstantHitDamage(DEFAULT_FIREMODE)=250 //300
	Spread(DEFAULT_FIREMODE)=0.02
	PenetrationPower(DEFAULT_FIREMODE)=40.0
	PenetrationDamageReductionCurve(DEFAULT_FIREMODE)=(Points=((InVal=0.f,OutVal=0.f),(InVal=2.f, OutVal=2.f)))
	FireInterval(DEFAULT_FIREMODE)=0.95 // 63 RPM
	AmmoCost(DEFAULT_FIREMODE)=1
	FireOffset=(X=25,Y=5.0,Z=-10)
	BlockInterruptFiringTime=0.5

	FireFXTemplate=ParticleSystem'DROW_EMIT.FX_Heat_Lens'
	// Create all these particle system components off the bat so that the tick group can be set
	// fixes issue where the particle systems get offset during animations
	Begin Object Class=KFParticleSystemComponent Name=BasePSC0
		TickGroup=TG_PostUpdateWork
	End Object
	FirePSC=BasePSC0

	// Saw attack
	FiringStatesArray(HEAVY_ATK_FIREMODE)=MeleeSustained
	InstantHitDamage(HEAVY_ATK_FIREMODE)=70 //35
	InstantHitDamageTypes(HEAVY_ATK_FIREMODE)=class'KFDT_Slashing_Diskete'
	FireInterval(HEAVY_ATK_FIREMODE)=+0.12
	AmmoCost(HEAVY_ATK_FIREMODE)=1
	MeleeSustainedWarmupTime=0.1

	// BASH_FIREMODE
	FiringStatesArray(BASH_FIREMODE)=MeleeAttackBasic
	WeaponFireTypes(BASH_FIREMODE)=EWFT_Custom
	InstantHitDamage(BASH_FIREMODE)=150 //100
	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Slashing_Diskete'

	AssociatedPerkClasses(0)=class'KFPerk_Berserker'
	AssociatedPerkClasses(1)=class'KFPerk_Survivalist'

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.1f), (Stat=EWUS_Damage1, Scale=1.1f), (Stat=EWUS_Damage2, Scale=1.1f),  (Stat=EWUS_Weight, Add=1)))
}