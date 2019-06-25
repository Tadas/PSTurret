<#
.SYNOPSIS
	Keeps sending control packets to maintain a continuous control "signal"
#>
function Send-USBTurretControlSignal {
	Param(
		[byte[]]$ControlPacket,

		[ValidateRange(0, 30 * 1000)]
		[int]$ForDuration = 1000, # Milliseconds

		[Alias('ToTurret')]
		[ValidateNotNull()]
		$Turret = (Get-USBTurret | Select-Object -First 1)
	)

	Write-Verbose "Send-USBTurretControlSignal| Total duration: $ForDuration ms"

	# When you send a command and don't send a "stop" command the turret will automatically stop after this much time
	$COMMAND_TIMEOUT_MS = 3000

	$StopPacket = New-Object byte[] 65
	$StopPacket[7] = 8
	$StopPacket[8] = 8

	# Calculate how many "full" commands and how much remaining time we will have
	$Remainder = 0
	$Times = [math]::divrem( $ForDuration, $COMMAND_TIMEOUT_MS, [ref]$Remainder )

	for ($i = 0; $i -lt $Times; $i++) {
		Write-Verbose "Send-USBTurretControlSignal| Sending a packet for: $COMMAND_TIMEOUT_MS"
		Send-USBTurretControlPacket $ControlPacket -Turret $Turret
		Start-Sleep -Milliseconds $COMMAND_TIMEOUT_MS
	}

	Start-Sleep -Milliseconds 100
	if ($Remainder -gt 0){
		Write-Verbose "Send-USBTurretControlSignal| Sending a short packet for: $Remainder"
		Send-USBTurretControlPacket $ControlPacket -Turret $Turret
		Start-Sleep -Milliseconds $Remainder
		
		# Stop the turret by sending an empty command. If there was no remainder of time
		# then we assume the turret will timeout the last command and stop on it's own
		Write-Verbose "Send-USBTurretControlSignal| Sending a stop packet"
		Send-USBTurretControlPacket $StopPacket -Turret $Turret
	}
	Start-Sleep -Milliseconds 100
	Write-Verbose ""
}