class KFCameraLensEmit_IcedDROW extends KFEmit_CameraEffect;

function NotifyRetriggered()
{
	super.NotifyRetriggered();

	// Keep the effect going if we take fire damage again
 	LifeSpan = default.LifeSpan;
}

defaultproperties
{
	PS_CameraEffect=ParticleSystem'DROW_EMIT.FX_Camera_Iced_DROW'
	bAllowMultipleInstances=false
	LifeSpan=3.5f ///1.5f // effect is 3 seconds long
	bDepthTestEnabled=false
	
	//DistFromCamera=90
}