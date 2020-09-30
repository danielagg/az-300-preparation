$SubscriptionId = 123456789
 
Connect-AzureRmAccount -Subscription $SubscriptionId

$resourceGroup = Get-AzureRmResourceGroup `
  -Name 'new-resource-group' `
  -Location 'centralus'

$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name 'new-subnet-config' `
  -AddressPrefix '10.2.1.0/24'

$vnet = New-AzureRmVirtualNetwork `
  -ResourceGroupName $resourceGroup.ResourceGroupName `
  -Location $resourceGroup.Location `
  -Name 'new-vnet' `
  -AddressPrefix '10.2.0.0/16' `
  -Subnet $subnetConfig

$publicIp = New-AzureRmPublicIpAddress `
  -ResourceGroupName $resourceGroup.ResourceGroupName `
  -Location $resourceGroup.Location `
  -Name 'new-public-ip' `
  -AllocationMethod Static

$networkSecRuleConfig = New-AzureRmNetworkSecurityRuleConfig `
  -Name 'network-sec-rule-config' `
  -Description 'Allow SSH' `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix 'Internet' `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22


# With Azure CLI, the port had to be opened manually, but not with this
# Priority is sequential (100 gets executed before 101)

$networkSecGroup = New-AzureRmNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup.ResourceGroupName `
  -Location $resourceGroup.Location `
  -Name 'new-network-sec-group' `
  -SecurityRules $networkSecRuleConfig `

$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetConfig.Name }

$nic = New-AzureRmNetworkInterface `
  -ResourceGroupName $resourceGroup.ResourceGroupName `
  -Location $resourceGroup.Location `
  -Name 'new-nic' `
  -Subnet $subnet `
  -PublicIpAddress $publicIp `
  -NetworkSecurityGroup $networkSecGroup

$vmConfig = New-AzureRmVMConfig `
  -VMName 'name-of-new-vm' `
  -VMSize 'Standard_D1'

$password = ConvertTo-SecureString 'password1234' `
  -AsPlainText `
  -Force

$credential = New-Object System.Management.Automation.PSCredential ('demoadmin', $password)

$vmConfig = Set-AzureRmVMOperatingSystem `
  -VM $vmConfig `
  -Linux `
  -ComputerName 'vm-computer-name' `
  -DisablePasswordAuthentication `
  -Credential $credential

$sshPublicKey = Get-Content "~/.ssh/id_rsa.pub"

Add-AzureRmVMSshPublicKey `
  -VM $vmConfig `
  -KeyData $sshPublicKey `
  -Path "/home/demoadmin/.ssh/authorized_keys"

$vmConfig = Set-AzureRmVMSourceImage `
  -VM $vmConfig `
  -PublisherName 'Redhat' `
  -Offer 'rhel' `
  -Skus '7.4' `
  -Version 'latest'

# Assign NIC
$vmConfig = Add-AzureRmVMNetworkInterface `
  -VM $vmConfig `
  -Id $nic.Id

New-AzureRmVM `
  -ResourceGroupName $resourceGroup.ResourceGroupName `
  -Location $resourceGroup.Location `
  -VM $vmConfig

$IpOfVm = Get-AzureRmPublicIpAddress `
  -ResourceGroupName $resourceGroup.ResourceGroupName `
  -Location $resourceGroup.Location | Select-Object -ExpandProperty -PublicIpAddress

$IpOfVm


New-AzKeyvault `
  -name "<your-unique-keyvault-name>" `
  -ResourceGroupName "myResourceGroup" `
  -Location EastUS `
  -EnabledForDiskEncryption

$KeyVault = Get-AzKeyVault `
  -VaultName "<your-unique-keyvault-name>"
  -ResourceGroupName "MyResourceGroup"

Set-AzVMDiskEncryptionExtension `
  -ResourceGroupName MyResourceGroup `
  -VMName "MyVM" `
  -DiskEncryptionKeyVaultUrl $KeyVault.VaultUri `
  -DiskEncryptionKeyVaultId $KeyVault.ResourceId `
  -SkipVmBackup `
  -VolumeType All





$keyVault = New-AzureRmKeyVault `
  -VaultName 'az203DemoEncryptionVault' `
  -ResourceGroupName 'az203-EncryptionDemo' `
  -Location 'West US'

Set-AzureRmKeyVaultAccessPolicy `
  -VaultName 'az203DemoEncryptionVault' `
  -ResourceGroupName 'az203-EncryptionDemo' `
  -EnabledForDiskEncryption

Set-AzureRmKeyVaultAccessPolicy `
  -VaultName 'az203DemoEncryptionVault' `
  -UserPrincipalName '<your_AAD_username>' `
  -PermissionsToKeys Get,List,Update,Create,Import,Delete -PermissionsToSecrets Get,List,Set,Delete,Recover,Backup,Restore

Add-AzureKeyVaultKey `
  -VaultName 'az203DemoEncryptionVault'
  -Name 'az203VMEncryptionKey' -Destination 'Software';

$keyEncryptionKeyUrl = ( `
  Get-AzureKeyVaultKey `
    -VaultName 'az203DemoEncryptionVault' `
    -Name 'az203VMEncryptionKey' `
).Key.kid;

Set-AzureRmVMDiskEncryptionExtension `
  -ResourceGroupName 'az203-EncryptionDemo' `
  -VMName 'az203demoVM' `
  -DiskEncryptionKeyVaultUrl $keyVault.VaultUri `
  -DiskEncryptionKeyVaultId $keyVault.ResourceId `
  -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
  -KeyEncryptionKeyVaultId $keyVault.ResourceId;