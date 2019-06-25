function Fire-USBTurret {
	Param(
		[ValidateNotNull()]
		$Turret = (Get-USBTurret | Select-Object -First 1)
	)

	$ControlPacket = New-Object byte[] 65
	$ControlPacket[$script:COMMAND_INDEXES['Fire']] = 1
	$ControlPacket[7] = 8
	$ControlPacket[8] = 8

	Send-USBTurretControlSignal -ControlPacket $ControlPacket -ForDuration 3200 -ToTurret $Turret
}