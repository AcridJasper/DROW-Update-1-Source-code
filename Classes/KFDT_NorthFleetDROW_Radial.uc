class KFDT_NorthFleetDROW_Radial extends KFDT_EMP
	abstract
	hidedropdown;

defaultproperties
{
	KDeathVel=0

	EMPPower=25 //200
	GoreDamageGroup=DGT_EMP
	EffectGroup=FXG_Electricity
	
	WeaponDef=class'KFWeapDef_NorthFleetDROW'
	ModifierPerkList(0)=class'KFPerk_Survivalist'
	// ModifierPerkList(1)=class'KFPerk_Demolitionist'

	// We play radial effect here
	OverrideImpactEffect=ParticleSystem'DROW_EMIT.FX_NorthFleetDROW_Radial'
}