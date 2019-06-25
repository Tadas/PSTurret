function Move-USBTurret {
	Param(
		[ValidateRange(0, 30 * 1000)]
		[int]$Left  = 0,

		[ValidateRange(0, 30 * 1000)]
		[int]$Right = 0,

		[ValidateRange(0, 30 * 1000)]
		[int]$Up    = 0,

		[ValidateRange(0, 30 * 1000)]
		[int]$Down  = 0,

		[ValidateNotNull()]
		$Turret = (Get-USBTurret | Select-Object -First 1)
	)

	if (($Left -ne 0) -and ($Right -ne 0)){ throw "Incorrect paramters - Left AND Right" }
	if (($Up   -ne 0) -and ($Down  -ne 0)){ throw "Incorrect paramters - Up AND Down" }

	$Destination = @{
		Left  = $Left
		Right = $Right
		Up    = $Up
		Down  = $Down
	}

	# Select the longest command in the request - this will be our stop
	$MaxDuration = ($Destination.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Value

	$i = 0;
	while ($i -lt $MaxDuration) {
		# The command will change at the next min value. Take into acount that we've moved forward in time by $i amount of time
		$NextCommandChangeAt = ($Destination.GetEnumerator() | ? Value -gt $i | Sort-Object -Property Value | Select-Object -First 1).Value
		
		$Duration = $NextCommandChangeAt - $i # We're counting command duration from the last point in time which was $i

		# Build command packet with all the commands we need to send at this time
		$ControlPacket = New-Object byte[] 65
		$ControlPacket[7] = 8
		$ControlPacket[8] = 8

		$CommandsToSend = ($Destination.GetEnumerator() | Sort-Object -Property Value -Descending | ? Value -gt $i).Name
		foreach ($Command in $CommandsToSend) {
			# Look up index of a command and mark that location as 1 in the control packet
			$ControlPacket[$script:COMMAND_INDEXES[$Command]] = 1
		}
		Write-Verbose "Invoke-USBTurretForDuration| Sending '$($CommandsToSend -join '+')' for $Duration ms"
		Send-USBTurretControlSignal -ControlPacket $ControlPacket -ForDuration $Duration -ToTurret $Turret
		Start-Sleep -Milliseconds 15 # Sometimes commands get ignored, a slight delay seems to help
		$i += $Duration
	}
	Start-Sleep -Milliseconds 100
	Write-Verbose ""
}