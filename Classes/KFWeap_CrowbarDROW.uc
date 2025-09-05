class KFWeap_CrowbarDROW extends KFWeap_MeleeBase;

defaultproperties
{
	// Content
	PackageKey="CrowbarDROW"
	
	// Crovel
	FirstPersonMeshName="WEP_CrowbarDROW_MESH.Wep_1stP_CrowbarDROW1_Rig"
	FirstPersonAnimSetNames(0)="WEP_CrowbarDROW_ARCH.WEP_1P_CrowbarDROW1_ANIM"
	PickupMeshName="WEP_CrowbarDROW_MESH.Wep_CrowbarDROW_Pickup"
	AttachmentArchetypeName="WEP_CrowbarDROW_ARCH.Wep_CrowbarDROW1_3P"

	DroppedPickupClass=class'KFDroppedPickup_LootBeam_Legendary_DROW' // Loot beam fx (no offset)

	// Katana
	// PlayerViewOffset=(X=2,Y=0,Z=0)
	// FirstPersonMeshName="WEP_CrowbarDROW_MESH.Wep_1stP_CrowbarDROW_Rig"
	// FirstPersonAnimSetNames(0)="WEP_CrowbarDROW_ANIM.WEP_1stP_CrowbarDROW_Anim"
	// AttachmentArchetypeName="WEP_CrowbarDROW_ARCH.Wep_CrowbarDROW_3P"

	Begin Object Name=MeleeHelper_0
		MaxHitRange=190
		// Override automatic hitbox creation (advanced)
		HitboxChain.Add((BoneOffset=(X=+3,Z=190)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=170)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=150)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=130)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=110)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=90)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=70)))
		HitboxChain.Add((BoneOffset=(X=-3,Z=50)))
		HitboxChain.Add((BoneOffset=(X=+3,Z=30)))
		HitboxChain.Add((BoneOffset=(Z=10)))
		WorldImpactEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Blunted_melee_impact'
		// modified combo sequences
		MeleeImpactCamShakeScale=0.035f //0.4
		ChainSequence_F=(DIR_Left, DIR_ForwardRight, DIR_ForwardLeft, DIR_ForwardRight, DIR_ForwardLeft)
		ChainSequence_B=(DIR_BackwardLeft, DIR_Left, DIR_Right, DIR_ForwardRight, DIR_Left, DIR_Right, DIR_Left)
		ChainSequence_L=(DIR_Right, DIR_BackwardRight, DIR_ForwardRight, DIR_ForwardLeft, DIR_Right, DIR_Left)
		ChainSequence_R=(DIR_Left, DIR_BackwardLeft, DIR_ForwardLeft, DIR_ForwardRight, DIR_Left, DIR_Right)
	End Object

    // Inventory
	GroupPriority=21 // funny number
	InventorySize=4
	WeaponSelectTexture=Texture2D'WEP_CrowbarDROW_MAT.UI_WeaponSelect_CrowbarDROW'

	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'KFDT_Bludgeon_CrowbarDROW_Light'
	InstantHitDamage(DEFAULT_FIREMODE)=90

	InstantHitDamageTypes(HEAVY_ATK_FIREMODE)=class'KFDT_Bludgeon_CrowbarDROW_Heavy'
	InstantHitDamage(HEAVY_ATK_FIREMODE)=120

	InstantHitDamageTypes(BASH_FIREMODE)=class'KFDT_Bludgeon_CrowbarDROW_Bash'
	InstantHitDamage(BASH_FIREMODE)=25

	AssociatedPerkClasses(0)=class'KFPerk_Berserker'

	// Block Sounds
	BlockSound=AkEvent'WW_WEP_Bullet_Impacts.Play_Block_MEL_Crovel'
	ParrySound=AkEvent'WW_WEP_Bullet_Impacts.Play_Parry_Metal'
	
	ParryStrength=4 //3
	ParryDamageMitigationPercent=0.50
	BlockDamageMitigation=0.60

	WeaponUpgrades[1]=(Stats=((Stat=EWUS_Damage0, Scale=1.2f), (Stat=EWUS_Damage1, Scale=1.2f), (Stat=EWUS_Damage2, Scale=1.2f), (Stat=EWUS_Weight, Add=1)))
	WeaponUpgrades[2]=(Stats=((Stat=EWUS_Damage0, Scale=1.45f), (Stat=EWUS_Damage1, Scale=1.45f), (Stat=EWUS_Damage2, Scale=1.45f), (Stat=EWUS_Weight, Add=2)))
	WeaponUpgrades[3]=(Stats=((Stat=EWUS_Damage0, Scale=1.65f), (Stat=EWUS_Damage1, Scale=1.65f), (Stat=EWUS_Damage2, Scale=1.65f), (Stat=EWUS_Weight, Add=3)))
	WeaponUpgrades[4]=(Stats=((Stat=EWUS_Damage0, Scale=1.85f), (Stat=EWUS_Damage1, Scale=1.85f), (Stat=EWUS_Damage2, Scale=1.85f), (Stat=EWUS_Weight, Add=4)))
}