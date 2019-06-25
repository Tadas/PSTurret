function Get-USBTurret {
	Param(
		[int]$vendorID = 0x1130,
		[int]$productID = 0x0202
	)
	# TODO - multiple turrets??
	[HidSharp.HidDevice[]]$HIDDevices = [HIDSharp.DeviceList]::Local.GetHidDevices($vendorID, $productID)

	@{
		MagicDevice   = [HIDSharp.HIDStream]($HIDDevices | Where-Object MaxOutputReportLength -eq  9 | Select-Object -First 1).Open()
		ControlDevice = [HIDSharp.HIDStream]($HIDDevices | Where-Object MaxOutputReportLength -eq 65 | Select-Object -First 1).Open()
	}
}