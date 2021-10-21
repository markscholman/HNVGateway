#region Functions
function Validate-IsEmptyTrim {
	<#
		.SYNOPSIS
			Validates if input is empty (ignores spaces).
	
		.DESCRIPTION
			Validates if input is empty (ignores spaces).
	
		.PARAMETER  Text
			A string containing an IP address
	
		.INPUTS
			System.String
	
		.OUTPUTS
			System.Boolean
	#>
	[OutputType([Boolean])]
	param ([string]$Text)
	
	if ($text -eq $null -or $text.Trim().Length -eq 0) {
		return $true
	}
	
	return $false
}

function Load-DataGridView {
	<#
	.SYNOPSIS
		This functions helps you load items into a DataGridView.

	.DESCRIPTION
		Use this function to dynamically load items into the DataGridView control.

	.PARAMETER  DataGridView
		The ComboBox control you want to add items to.

	.PARAMETER  Item
		The object or objects you wish to load into the ComboBox's items collection.
	
	.PARAMETER  DataMember
		Sets the name of the list or table in the data source for which the DataGridView is displaying data.

	#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		[System.Windows.Forms.DataGridView]$DataGridView,
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		$Item,
		[Parameter(Mandatory = $false)]
		[string]$DataMember
	)
	$DataGridView.SuspendLayout()
	$DataGridView.DataMember = $DataMember
	
	if ($Item -is [System.ComponentModel.IListSource]`
	-or $Item -is [System.ComponentModel.IBindingList] -or $Item -is [System.ComponentModel.IBindingListView]) {
		$DataGridView.DataSource = $Item
	} else {
		$array = New-Object System.Collections.ArrayList
		
		if ($Item -is [System.Collections.IList]) {
			$array.AddRange($Item)
		} else {
			$array.Add($Item)
		}
		$DataGridView.DataSource = $array
	}
	
	$DataGridView.ResumeLayout()
}

function Load-ListBox {
<#
	.SYNOPSIS
		This functions helps you load items into a ListBox or CheckedListBox.

	.DESCRIPTION
		Use this function to dynamically load items into the ListBox control.

	.PARAMETER  ListBox
		The ListBox control you want to add items to.

	.PARAMETER  Items
		The object or objects you wish to load into the ListBox's Items collection.

	.PARAMETER  DisplayMember
		Indicates the property to display for the items in this control.
	
	.PARAMETER  Append
		Adds the item(s) to the ListBox without clearing the Items collection.
	
	.EXAMPLE
		Load-ListBox $ListBox1 "Red", "White", "Blue"
	
	.EXAMPLE
		Load-ListBox $listBox1 "Red" -Append
		Load-ListBox $listBox1 "White" -Append
		Load-ListBox $listBox1 "Blue" -Append
	
	.EXAMPLE
		Load-ListBox $listBox1 (Get-Process) "ProcessName"
#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		[System.Windows.Forms.ListBox]$ListBox,
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		$Items,
		[Parameter(Mandatory = $false)]
		[string]$DisplayMember,
		[switch]$Append
	)
	
	if (-not $Append) {
		$listBox.Items.Clear()
	}
	
	if ($Items -is [System.Windows.Forms.ListBox+ObjectCollection]) {
		$listBox.Items.AddRange($Items)
	} elseif ($Items -is [Array]) {
		$listBox.BeginUpdate()
		foreach ($obj in $Items) {
			$listBox.Items.Add($obj)
		}
		$listBox.EndUpdate()
	} else {
		$listBox.Items.Add($Items)
	}
	
	$listBox.DisplayMember = $DisplayMember
}

function Load-ComboBox {
<#
	.SYNOPSIS
		This functions helps you load items into a ComboBox.

	.DESCRIPTION
		Use this function to dynamically load items into the ComboBox control.

	.PARAMETER  ComboBox
		The ComboBox control you want to add items to.

	.PARAMETER  Items
		The object or objects you wish to load into the ComboBox's Items collection.

	.PARAMETER  DisplayMember
		Indicates the property to display for the items in this control.
	
	.PARAMETER  Append
		Adds the item(s) to the ComboBox without clearing the Items collection.
	
	.EXAMPLE
		Load-ComboBox $combobox1 "Red", "White", "Blue"
	
	.EXAMPLE
		Load-ComboBox $combobox1 "Red" -Append
		Load-ComboBox $combobox1 "White" -Append
		Load-ComboBox $combobox1 "Blue" -Append
	
	.EXAMPLE
		Load-ComboBox $combobox1 (Get-Process) "ProcessName"
#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		[System.Windows.Forms.ComboBox]$ComboBox,
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		$Items,
		[Parameter(Mandatory = $false)]
		[string]$DisplayMember,
		[switch]$Append
	)
	
	if (-not $Append) {
		$ComboBox.Items.Clear()
	}
	
	if ($Items -is [Object[]]) {
		$ComboBox.Items.AddRange($Items)
	} elseif ($Items -is [Array]) {
		$ComboBox.BeginUpdate()
		foreach ($obj in $Items) {
			$ComboBox.Items.Add($obj)
		}
		$ComboBox.EndUpdate()
	} else {
		$ComboBox.Items.Add($Items)
	}
	
	$ComboBox.DisplayMember = $DisplayMember
}

function Get-ScriptDirectory { 
	if($hostinvocation -ne $null)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}
[string]$ScriptDirectory = Get-ScriptDirectory

function Wait-NodesUp {
	for ($i = 0; $i -le 1; $i++) {
		$GWVMNode1, $GWVMNode2 | ForEach-Object {
			$node = "down"
			while ($node -ne "up") {
				$testnode = Test-NetConnection -ComputerName $_ -Port 5985
				if ($testnode.TcpTestSucceeded -eq $false) {
					Write-Host -ForegroundColor Red "Cannot reach $_ for Remote PowerShell"
					Clear-DnsClientCache
					Start-Sleep -Seconds 30
				} else {
					$node = "up"
				}
				
			}
		}
	}
}

function Construct-RunasAccount {
	param (
		$RunasAccount
	)
	$VMMRunasAccount = Get-SCRunAsAccount $RunasAccount
	$RunasDomainAccount = $VMMRunasAccount.Domain + "\" + $VMMRunasAccount.UserName
	return $RunasDomainAccount
}

function Deploy-GatewayVM {
	param (
		$VMMServer,
		$VMFENetwork,
		$VMFESubnet,
		$VMMGTNetwork,
		$VMMGTSubnet,
		$VMBENetwork,
		$HVHHost,
		$ServerName,
		$Domain,
		$VMTemplate,
		$VMLocalAdmin,
		$Cred
	)
	$script = {
		$Guid = [guid]::NewGuid()
		$ProfileGuid = "Profile_" + $Guid
		$TemplateGuid = "Template_" + $Guid
		$OSProfileGuid = "OSProfile_" + $Guid
		$GuidHW = [guid]::NewGuid()
		$GuidTMPL = [guid]::NewGuid()
		
		Import-Module virtualmachinemanager
		Get-SCVMMServer -ComputerName $USING:VMMServer | Out-Null
		
		New-SCVirtualScsiAdapter -JobGroup $GuidHW -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType
		New-SCVirtualDVDDrive -JobGroup $GuidHW -Bus 0 -LUN 1
		
		$VMFESubnet = Get-SCVMSubnet -Name $USING:VMFESubnet
		$VMFENetwork = Get-SCVMNetwork -Name $USING:VMFENetwork
		New-SCVirtualNetworkAdapter -JobGroup $GuidHW -MACAddress "00:00:00:00:00:00" -MACAddressType Static -VLanEnabled $false -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Static -IPv6AddressType Dynamic -VMSubnet $VMFESubnet -VMNetwork $VMFENetwork
		$VMMGTSubnet = Get-SCVMSubnet -Name $USING:VMMGTSubnet
		$VMMGTNetwork = Get-SCVMNetwork -Name $USING:VMMGTNetwork
		New-SCVirtualNetworkAdapter -JobGroup $GuidHW -MACAddress "00:00:00:00:00:00" -MACAddressType Static -VLanEnabled $false -Synthetic -EnableVMNetworkOptimization $false -EnableMACAddressSpoofing $false -EnableGuestIPNetworkVirtualizationUpdates $false -IPv4AddressType Static -IPv6AddressType Dynamic -VMSubnet $VMMGTSubnet -VMNetwork $VMMGTNetwork
		New-SCVirtualNetworkAdapter -JobGroup $GuidHW -Synthetic
		
		$CPUType = Get-SCCPUType | Where-Object { $_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)" }
		$CapabilityProfile = Get-SCCapabilityProfile | Where-Object { $_.Name -eq "Hyper-V" }
		
		$Template = Get-SCVMTemplate | Where-Object { $_.Name -eq $using:VMTemplate }
		if ($Template.Generation -eq 1) {
			Set-SCVirtualCOMPort -NoAttach -GuestPort 1 -JobGroup $GuidHW
			Set-SCVirtualCOMPort -NoAttach -GuestPort 2 -JobGroup $GuidHW
			Set-SCVirtualFloppyDrive -RunAsynchronously -NoMedia -JobGroup $GuidHW
			New-SCHardwareProfile -CPUType $CPUType -Name $ProfileGuid -Description "Profile used to create a VM/Template" -CPUCount 4 -MemoryMB 8192 -DynamicMemoryEnabled $false -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $true -HAVMPriority 2000 -DRProtectionRequired $false -NumLock $false -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" -CPULimitFunctionality $false -CPULimitForMigration $false -CapabilityProfile $CapabilityProfile -Generation 1 -JobGroup $GuidHW | Out-Null
		}
		if ($Template.Generation -eq 2) {
			New-SCHardwareProfile -CPUType $CPUType -Name $ProfileGuid -Description "Profile used to create a VM/Template" -CPUCount 4 -MemoryMB 8192 -DynamicMemoryEnabled $false -MemoryWeight 5000 -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $true -HAVMPriority 2000 -DRProtectionRequired $false -SecureBootEnabled $true -CPULimitFunctionality $false -CPULimitForMigration $false -CapabilityProfile $CapabilityProfile -Generation 2 -JobGroup $GuidHW | Out-Null
		}
		
		$HardwareProfile = Get-SCHardwareProfile | Where-Object { $_.Name -eq $ProfileGuid }
		
		$LocalAdministratorCredential = get-scrunasaccount -Name $using:VMLocalAdmin
		$DomainJoinCredential = $Using:Cred
		$OperatingSystem = Get-SCOperatingSystem | Where-Object { $_.Name -eq "Windows Server 2012 R2 Standard" }
		
		New-SCVMTemplate -Name $TemplateGuid -Template $Template -HardwareProfile $HardwareProfile -JobGroup $GuidTMPL -ComputerName $USING:ServerName -TimeZone 110 -LocalAdministratorCredential $LocalAdministratorCredential -Domain $Using:Domain -DomainJoinCredential $DomainJoinCredential -AnswerFile $null -OperatingSystem $OperatingSystem | Out-Null
		$template = Get-SCVMTemplate -All | Where-Object { $_.Name -eq $TemplateGuid }
		
		$virtualMachineConfiguration = New-SCVMConfiguration -VMTemplate $template -Name $USING:ServerName
		
		$vmHost = Get-SCVMHost -ComputerName $using:HVHHost
		
		Set-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration -VMHost $vmHost
		Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration
		
		$AllNICConfigurations = Get-SCVirtualNetworkAdapterConfiguration -VMConfiguration $virtualMachineConfiguration
		
		Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration
		
		New-SCVirtualMachine -Name $USING:ServerName -VMConfiguration $virtualMachineConfiguration -Description "" -BlockDynamicOptimization $false -JobGroup $GuidTMPL -StartAction "NeverAutoTurnOnVM" -StopAction "SaveVM" | Out-Null
		
		Remove-SCVMTemplate $TemplateGuid
		
		Remove-SCHardwareProfile $ProfileGuid
		
		Start-SCVirtualMachine $USING:ServerName
	}
	Invoke-Command -ScriptBlock $script -ComputerName $VMMServer -ArgumentList $VMMServer,$VMFENetwork,$VMFESubnet,$VMMGTNetwork,$VMMGTSubnet,$VMBENetwork,$HVHHost,$ServerName,$Domain,$VMTemplate,$VMLocalAdmin,$Cred
}

function Configure-GatewayVM {
	param (
		$GWVMNode1,
		$GWVMNode2,
		$RunasAccount,
		$FENetworkSubnet,
		$MgtNetworkSubnet,
		$cred
	)
	$script = {
		
		Install-WindowsFeature Routing, Failover-Clustering -IncludeManagementTools
		
		net localgroup administrators $using:runasaccount /add
		
		$ManagementInterface = Get-NetIPConfiguration | Where-Object { $_.IPv4Address.IpAddress -match $using:MgtNetworkSubnet } | Select-Object -ExpandProperty InterfaceIndex
		$FEInterface = Get-NetIPConfiguration | Where-Object { $_.IPv4Address.IpAddress -match $using:FENetworkSubnet } | Select-Object -ExpandProperty InterfaceIndex
		
		Get-NetAdapter | Where-Object { $_.Status -eq "Disconnected" } | Rename-NetAdapter -NewName "Backend"
		Get-NetAdapter -InterfaceIndex $FEInterface | Rename-NetAdapter -NewName "Frontend"
		Get-NetAdapter -InterfaceIndex $ManagementInterface | Rename-NetAdapter -NewName "Management"
		
		Install-RemoteAccess -MultiTenancy
		
		Enable-WSManCredSSP Server -Force
		
		Get-NetConnectionProfile -InterfaceAlias "Frontend" | Set-NetConnectionProfile -NetworkCategory Public
		#Get-NetConnectionProfile -InterfaceAlias "Backend" | Set-NetConnectionProfile -NetworkCategory Private
		Get-NetFirewallRule RemoteDesktop-UserMode-In-TCP | Set-NetFirewallRule -Enabled True -Profile @("Domain", "Private")
		Start-Sleep -Seconds 2
		Stop-Computer -Force
	}
	Invoke-Command -ScriptBlock $script -ComputerName $GWVMNode1, $GWVMNode2 -ArgumentList $RunasAccount,$FENetworkSubnet,$MgtNetworkSubnet -Credential $cred
}

function Configure-GatewayBackendNetwork {
	param (
		$GWVMNode1,
		$GWVMNode2,
		$VMMServer,
		$BENetwork
	)
	$script = {
		Import-Module virtualmachinemanager
		Get-SCVMMServer -ComputerName $USING:VMMServer | Out-Null
		$VM1 = Get-SCVirtualMachine -Name $using:GWVMNode1
		$VM2 = Get-SCVirtualMachine -Name $using:GWVMNode2
		if ($VM1.Status -ne "PowerOff") {
			Stop-SCVirtualMachine $using:GWVMNode1
			while ($VM1.Status -ne "PowerOff") {
				Start-Sleep -Seconds 5
			}
		}
		
		$Guid = [guid]::NewGuid()
		
		Get-SCVirtualNetworkAdapter -VM $VM1| Where-Object { $_.LogicalNetwork -eq $null } | Set-SCVirtualNetworkAdapter -NoLogicalNetwork -VLanEnabled $false -VirtualNetwork $using:BENetwork -MACAddress "00:00:00:00:00:00" -MACAddressType Static -IPv4AddressType Dynamic -IPv6AddressType Dynamic -NoPortClassification -JobGroup $Guid
		
		$ClusterNonPossibleOwner = @()
		$ClusterNonPossibleOwner += Get-SCVMHost -ComputerName $VM2.HostName
		$ClusterPreferredOwner = @()
		$ClusterPreferredOwner += Get-SCVMHost -ComputerName  $VM1.HostName
		Set-SCVirtualMachine -VM $VM1 -Name $VM1.Name -JobGroup $Guid -ClusterNonPossibleOwner $ClusterNonPossibleOwner -ClusterPreferredOwner $ClusterPreferredOwner
		
		if ($VM2.Status -ne "PowerOff") {
			Stop-SCVirtualMachine $VM2
			while ($VM2.Status -ne "PowerOff") {
				Start-Sleep -Seconds 2
			}
		}
		
		$Guid = [guid]::NewGuid()
		
		Get-SCVirtualNetworkAdapter -VM $VM2 | Where-Object { $_.LogicalNetwork -eq $null } | Set-SCVirtualNetworkAdapter -NoLogicalNetwork -VLanEnabled $false -VirtualNetwork $using:BENetwork -MACAddress "00:00:00:00:00:00" -MACAddressType Static -IPv4AddressType Dynamic -IPv6AddressType Dynamic -NoPortClassification -JobGroup $Guid
		
		$ClusterNonPossibleOwner = @()
		$ClusterNonPossibleOwner += Get-SCVMHost -ComputerName $VM1.HostName
		$ClusterPreferredOwner = @()
		$ClusterPreferredOwner += Get-SCVMHost -ComputerName  $VM2.HostName
		
		Set-SCVirtualMachine -VM $VM2 -Name $VM2.Name -JobGroup $Guid -ClusterNonPossibleOwner $ClusterNonPossibleOwner -ClusterPreferredOwner $ClusterPreferredOwner
	}
	
	Invoke-Command -ScriptBlock $script -ComputerName $VMMServer -ArgumentList $VMMServer,$GWVMNode1, $GWVMNode2,$BENetwork
}

function Configure-SharedVHDX {
	param (
		$HVHNode1,
		$HVHNode2,
		$GWVMNode1,
		$GWVMNode2,
		$GWVMClusterName,
		$Cred
	)
	Start-Sleep -Seconds 2
	$script1 = {
		$GWVM1 = Get-VM $using:GWVMNode1 -ComputerName $using:HVHNode1
		
		$VMHDPath = (Get-VHD -VMId $GWVM1.id).Path
		$VMRootPath = Split-Path $VMHDPath
		$RootPath = Split-Path $VMRootPath
		New-Item -ItemType Directory -Path "$RootPath\VMMDisks\$using:GWVMClusterName"
		$Quorum = New-VHD -Path ("$RootPath\VMMDisks\" + $using:GWVMClusterName + "\HNV-Quorum.vhdx") -Dynamic -SizeBytes 1GB
		$RRAS = New-VHD -Path ("$RootPath\VMMDisks\" + $using:GWVMClusterName + "\HNV-RRAS.vhdx") -Dynamic -SizeBytes 10GB
		
		Add-VMHardDiskDrive -Path $Quorum.Path -VM $GWVM1 -SupportPersistentReservations
		Add-VMHardDiskDrive -Path $RRAS.Path -VM $GWVM1 -SupportPersistentReservations
		Start-VM $GWVM1
		$Disks = $Quorum.Path, $RRAS.Path
		return $Disks
	}
	
	$Disks = Invoke-Command -ScriptBlock $script1 -ComputerName $HVHNode1 -Credential $Cred -ArgumentList $HVHNode1,$GWVMNode1,$GWVMClusterName
	Start-Sleep -Seconds 2
	
	$script2 = {
		$Quorum = $using:Disks[0]
		$RRAS = $using:Disks[1]
		
		$GWVM2 = Get-VM $using:GWVMNode2 -ComputerName $using:HVHNode2
		
		Add-VMHardDiskDrive -Path $Quorum -VM $GWVM2 -SupportPersistentReservations -ComputerName $using:HVHNode2
		Add-VMHardDiskDrive -Path $RRAS -VM $GWVM2 -SupportPersistentReservations -ComputerName $using:HVHNode2
		Start-VM $GWVM2
	}
	
	Invoke-Command -ScriptBlock $script2 -ComputerName $HVHNode2 -Credential $Cred -ArgumentList $HVHNode2, $GWVMNode2, $Disks
}

function Configure-GatewayVMCluster {
	param (
		$GWVMNode1,
		$GWVMNode1FQDN,
		$GWVMNode2,
		$FENetworkSubnet,
		$ClusterName,
		$ClusterIP,
		$cred
	)
	
	Start-Sleep -Seconds 2
	$script = {
		Get-NetConnectionProfile -InterfaceAlias "Frontend" | Set-NetConnectionProfile -NetworkCategory Public
		#Get-NetConnectionProfile -InterfaceAlias "Backend" | Set-NetConnectionProfile -NetworkCategory Private
		
		$disks = Get-Disk | Where-Object { $_.OperationalStatus -ne "Online" }
		foreach ($disk in $disks) {
			if ($disk | Where-Object OperationalStatus -eq Offline) {
				$disk | Set-Disk -IsOffline $false
				if ($disk.PartitionStyle -eq "RAW") {
					$disk | Initialize-Disk -PartitionStyle GPT
				}
				if ($disk.IsReadOnly -eq $True) {
					$disk | Set-Disk -IsReadOnly $False
				}
				$disk | New-Partition -UseMaximumSize |
				Format-Volume -FileSystem NTFS -allocationunitsize 4096 -Force -Confirm:$false
			}
		}
		
		$fakeroute = 0
		if (((Get-NetRoute -InterfaceAlias Management).destinationprefix) -notcontains "0.0.0.0/0") {
			$fakeroute = 1
			New-NetRoute -InterfaceAlias Management -DestinationPrefix 0.0.0.0/0 -NextHop 1.2.3.4
		}
		
		$cluster = New-Cluster -Name $using:ClusterName -Node @($using:GWVMNode1, $using:GWVMNode2) -StaticAddress $using:ClusterIP -IgnoreNetwork $using:FENetworkSubnet
		
		$csvdisk = Get-ClusterResource | where { $_.OwnerGroup -eq "Available Storage" } | Select -ExpandProperty Name
		
		Add-ClusterSharedVolume -Cluster $cluster -Name @($csvdisk)
		
		Add-ClusterResourceType -Name "RAS Cluster Resource" -Dll $env:windir\System32\RasClusterRes.dll
		
		(Get-ClusterNetwork | Where-Object { $_.Role -eq 1 }).Role = 3
		
		if ($fakeroute -eq 1) {
			Remove-NetRoute -InterfaceAlias Management -DestinationPrefix 0.0.0.0/0 -Confirm:$false
		}
		
		Disable-WSManCredSSP Server
	}
	Invoke-Command -ScriptBlock $script -ComputerName $GWVMNode1FQDN -Authentication 'Credssp' -Credential $cred -ArgumentList $GWVMNode1,$GWVMNode2,$FENetworkSubnet,$ClusterIP,$ClusterName
}

function Add-VMMNetworkService {
	param (
		$VMMServer,
		$HostGroup,
		$HVHGatewayCluster,
		$HNVGWVMCluster,
		$HNVGWVMClusterNetbios,
		$BackendSwitch,
		$FEVMNetwork,
		$BELogicalNetwork,
		$RunasAccount
	)
	$script = {
		Import-Module virtualmachinemanager
		Get-SCVMMServer -ComputerName $using:VMMServer | Out-Null
		
		$credentials = Get-SCRunAsAccount -Name $using:RunasAccount
		$configurationProvider = Get-SCConfigurationProvider -Name "Microsoft Windows Server Gateway Provider"
		$vmHostGroups = @()
		foreach ($item in $using:HostGroup) {
			$vmHostGroups += Get-SCVMHostGroup -Name $item
		}
		Add-SCNetworkService -Name $using:HNVGWVMClusterNetbios -RunAsAccount $credentials -ConfigurationProvider $configurationProvider -VMHostGroup $vmHostGroups -ConnectionString "VMHost=$using:HVHGatewayCluster;GatewayVM=$using:HNVGWVMCluster;BackendSwitch=$using:BackendSwitch" -RunAsynchronously -Certificate $certificates
		
		$networkService = Get-SCNetworkService -Name $using:HNVGWVMClusterNetbios
		$frontEndAdapter = $networkService.NetworkAdapters | Where-Object { $_.AdapterName -eq "Frontend" }
		$FElogicalNetwork = Get-SCVMNetwork -Name $using:FEVMNetwork
		$FELogicalNetworkDefinition = $FElogicalNetwork.VMSubnet.LogicalNetworkDefinition
		Add-SCNetworkConnection -Name "Front End" -LogicalNetworkDefinition $FELogicalNetworkDefinition -Service $networkService -NetworkAdapter $frontEndAdapter -ConnectionType "FrontEnd" -RunAsynchronously
		
		$backEndAdapter = $networkService.NetworkAdapters | Where-Object { $_.AdapterName -eq "Backend" }
		$BELogicalNetworkDefinition = Get-SCLogicalNetworkDefinition | Where-Object { $_.LogicalNetwork -eq $using:BELogicalNetwork }
		Add-SCNetworkConnection -Name "Back End" -LogicalNetworkDefinition $BELogicalNetworkDefinition -Service $networkService -NetworkAdapter $backEndAdapter -ConnectionType "BackEnd" -RunAsynchronously
		
		Set-SCNetworkService -NetworkService $networkService -Name $using:HNVGWVMClusterNetbios -Description "" -ConnectionString "VMHost=$using:HVHGatewayCluster;GatewayVM=$using:HNVGWVMCluster;BackendSwitch=$using:BackendSwitch" -RunAsAccount $credentials
	}
	Invoke-Command -ScriptBlock	$script -ComputerName $VMMServer -ArgumentList $HostGroup,$HNVGWVMCluster,$HNVGWVMClusterNetbios,$BackendSwitch,$FEVMNetwork,$BELogicalNetwork,$RunasAccount
}

function Migrate-HNVgatewayCluster {
	param(
		$CurrentNetworkGatewayName,
		$NewNetworkGatewayName,
		$VMMServer
	)	
	$script = {
		Import-Module virtualmachinemanager
		Get-SCVMMServer -ComputerName $using:VMMServer | Out-Null
		
		$VMNetworks = (Get-SCNetworkGateway).VMNetworkGateways | Where-Object { $_.NetworkGateway.Name -eq $using:CurrentNetworkGatewayName } | Select-Object -ExpandProperty VMNetwork
		foreach ($vmNetwork in $VMNetworks) {
			$VmNetworkGateway = (Get-SCNetworkGateway).VMNetworkGateways | Where-Object { $_.Name -eq $vmNetwork.VMNetworkGateways.Name }
			$natconnections = $VmNetworkGateway.Natconnections
			$natrules = $VmNetworkGateway.Natconnections.Rules
			$vpnconnections = $VmNetworkGateway.VPNConnections
			$EffectiveRoutes = $VmNetworkGateway.EffectiveRoutes
			Remove-SCVMNetworkGateway -VMNetworkGateway $VmNetworkGateway
			
			$vmSubnet = Get-SCVMSubnet -VMNetwork $vmNetwork
			$gatewayDevice = Get-SCNetworkGateway -Name $using:NewNetworkGatewayName
			$VmNetworkGateway = Add-SCVMNetworkGateway -Name $vmNetwork.Name -EnableBGP $false -NetworkGateway $gatewayDevice -VMNetwork $vmNetwork
			$natConnection = Add-SCNATConnection -Name $vmNetwork.Name -VMNetworkGateway $VmNetworkGateway -ExternalIPAddress $natrules[0].ExternalIPAddress.IPAddressToString
			
			foreach ($Rule in $natrules) {
				Add-SCNATRule -Name $Rule.Name -Protocol $Rule.Protocol -InternalIPAddress $Rule.InternalIPAddress -ExternalPort $Rule.ExternalPort -NATConnection $natConnection -InternalPort $Rule.InternalPort
			}
			
			foreach ($vpn in $vpnconnections) {
				$runAsAccount = Get-SCRunAsAccount -Name $vpnconnections.Secret.Name
				$vpnConnection = Add-SCVPNConnection -Name $vpn.Name -VMNetworkGateway $VmNetworkGateway -Secret $runAsAccount -TargetIPv4VPNAddress $vpn.TargetVPNIPv4Address -AuthenticationMethod $vpn.AuthenticationMethod
				foreach ($route in $EffectiveRoutes) {
					Add-SCNetworkRoute -IPSubnet $route.IPSubnet -RunAsynchronously -VPNConnection $vpnConnection -VMNetworkGateway $VmNetworkGateway
				}
			}
		}
	}
	
	Invoke-Command -ScriptBlock $script -ComputerName $VMMServer -ArgumentList $CurrentNetworkGatewayName, $NewNetworkGatewayName
}

function Migrate-HNVNetwork {
	param (
		$CustomerVMNetwork,
		$NewNetworkGatewayName,
		$VMMServer
	)
	$script = {
		Import-Module virtualmachinemanager
		Get-SCVMMServer -ComputerName $using:VMMServer | Out-Null
		
		$vmNetwork = Get-SCVMNetwork -Name $using:CustomerVMNetwork
		$VmNetworkGateway = (Get-SCNetworkGateway).VMNetworkGateways | Where-Object { $_.Name -eq $vmNetwork.VMNetworkGateways.Name }
		$natconnections = $VmNetworkGateway.Natconnections
		$natrules = $VmNetworkGateway.Natconnections.Rules
		$vpnconnections = $VmNetworkGateway.VPNConnections
		$EffectiveRoutes = $VmNetworkGateway.EffectiveRoutes
		$x = Get-SCNetworkRoute -Gateway $VmNetworkGateway
		
		Remove-SCVMNetworkGateway -VMNetworkGateway $VmNetworkGateway
		
		$vmSubnet = Get-SCVMSubnet -VMNetwork $vmNetwork
		$gatewayDevice = Get-SCNetworkGateway -Name $using:NewNetworkGatewayName
		$VmNetworkGateway = Add-SCVMNetworkGateway -Name $vmNetwork.Name -EnableBGP $false -NetworkGateway $gatewayDevice -VMNetwork $vmNetwork
		$natConnection = Add-SCNATConnection -Name $vmNetwork.Name -VMNetworkGateway $VmNetworkGateway -ExternalIPAddress $natrules[0].ExternalIPAddress.IPAddressToString
		
		foreach ($Rule in $natrules) {
			Add-SCNATRule -Name $Rule.Name -Protocol $Rule.Protocol -InternalIPAddress $Rule.InternalIPAddress -ExternalPort $Rule.ExternalPort -NATConnection $natConnection -InternalPort $Rule.InternalPort
		}
		
		foreach ($vpn in $vpnconnections) {
			$runAsAccount = Get-SCRunAsAccount -Name $vpn.Secret.Name
			$vpnConnection = Add-SCVPNConnection -Name $vpn.Name -VMNetworkGateway $VmNetworkGateway -Secret $runAsAccount -TargetIPv4VPNAddress $vpn.TargetVPNIPv4Address -AuthenticationMethod $vpn.AuthenticationMethod
			foreach ($route in $EffectiveRoutes) {
				Add-SCNetworkRoute -IPSubnet $route.IPSubnet -RunAsynchronously -VPNConnection $vpnConnection -VMNetworkGateway $VmNetworkGateway
			}
		}
	}
	
	Invoke-Command -ScriptBlock $script -ComputerName $VMMServer -ArgumentList $CustomerVMNetwork, $NewNetworkGatewayName
}

function Add-ExternalIP {
	param (
		$ipaddress, # = "31.204.136.140"
		$newipaddress, # = "31.204.136.111"
		$ComputerName,
		$cred
	)
	$script = {
		$NetnatAddress = Get-NetNatExternalAddress | Where-Object { $_.IPAddress -eq $ipaddress }
		Add-NetNatExternalAddress -NatName $NetnatAddress.NatName -IPAddress $newipaddress -PortStart 1 -PortEnd 49151
	}
	Invoke-Command -ScriptBlock $script -ComputerName $ComputerName -Credential $cred
}

function Add-ExternalNAT {
	# This command adds the actual NAT Port rules
	#Add-NetNatStaticMapping -NatName f2566857-d818-4f69-a5db-43eb76a1d956 -Protocol TCP -ExternalIPAddress 31.204.136.111 -ExternalPort 80 -InternalIPAddress 10.134.253.2-InternalPort 80
	param (
	$ipaddressExternal = "31.204.136.111",
	$Protocol = "TCP",
	$PortInt = 80,
	$PortExt = 80,
	$ipaddressInternal = "10.134.253.2"
	)
	$NetnatAddress = Get-NetNatExternalAddress | Where-Object { $_.IPAddress -eq $ipaddressExternal }
	Add-NetNatStaticMapping -NatName $NetnatAddress.NatName -Protocol $Protocol -ExternalIPAddress $ipaddressExternal -ExternalPort $PortExt -InternalIPAddress $ipaddressInternal-InternalPort $PortInt
	
	
}

function Remove-ExternalIP {
	param (
	$ipaddress = "31.204.136.111"
	)
	$NetnatAddress = Get-NetNatExternalAddress | Where-Object { $_.IPAddress -eq $ipaddress }
	Remove-NetNatExternalAddress -NatName $NetnatAddress.NatName -ExternalAddressID $NetnatAddress.ExternalAddressID
}

function Remove-ExternalNAT {
	# This command remove the actual NAT Port rules
	#Remove-NetNatStaticMapping -NatName f2566857-d818-4f69-a5db-43eb76a1d956 -StaticMappingID 2
	param (
	$ipaddressExternal = "31.204.136.111"
	)
	$NetnatAddress = Get-NetNatExternalAddress | Where-Object { $_.IPAddress -eq $ipaddressExternal }
	Remove-NetNatStaticMapping -NatName $NetnatAddress.NatName -StaticMappingID 2
}

#endregion