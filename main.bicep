param location string = 'westeurope'

// param storageAccountRGName string = 'rg-weu-cse'

// param vmssName string

@description('Size of VMs in the VM Scale Set.')
param vmSize string = 'Standard_B2ms'

// @description('When true this limits the scale set to a single placement group, of max size 100 virtual machines')
// param singlePlacementGroup bool = true

@description('Admin username on all VMs.')
param adminUsername string

@description('Admin password on all VMs.')
@secure()
param adminPassword string

// @description('Location of the PowerShell DSC zip file relative to the URI specified in the _artifactsLocation, i.e. DSC/IISInstall.ps1.zip')
// param powershelldscZip string = 'https://stoweuscript.blob.core.windows.net/dsc/dsc.zip'

// @description('Location of the  of the WebDeploy package zip file relative to the URI specified in _artifactsLocation, i.e. WebDeploy/DefaultASPWebApp.v1.0.zip')
// param webDeployPackageFullPath string = 'https://stoweuscript.blob.core.windows.net/dsc/DefaultASPWebApp.v1.0.zip'

// @description('Version number of the DSC deployment. Changing this value on subsequent deployments will trigger the extension to run.')
// param powershelldscUpdateTagVersion string = '1.0'

// @description('Fault Domain count for each placement group.')
// param platformFaultDomainCount int = 1

var vm1Name = 'myVM1'
var vm2Name = 'myVM2'


var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'



var vNetName = 'vnet-weu-cseVM'

// var publicIPVM1Name = 'pubip-weu-VM1'
// var publicIPVM2Name = 'pubip-weu-VM2'
var publicIPLB = 'publicIPAddressLB'


var subnetName = 'subnet-weu-VM'

var storageAccountVM1Name = 'stoweucsevm1'
var storageAccountVM2Name = 'stoweucsevm2'

var loadBalancerName = 'lbweuVM'
var subnetRefLB = resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, subnetName)


resource publicIPAddressLB 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: publicIPLB
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'lbtwovms'
    }
  }
  sku: {
    name: 'Standard'
  }
}


resource loadBalancer 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        properties: {
          // subnet: {
          //   id: subnetRef
          // }
          // privateIPAddress: '10.0.2.6'
          // privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: publicIPAddressLB.id
          }
        }
        name: 'LoadBalancerFrontend'
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'LoadBalancerFrontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'lbprobe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
  // dependsOn: [
  //   vNet
  // ]
}

// ---------------------------------------------------------------------------------------------------------------------------------------------------------

// resource publicIPAddressVM1 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
//   name: publicIPVM1Name
//   location: location
//   properties: {
//     publicIPAllocationMethod: 'Dynamic'
//     dnsSettings: {
//       domainNameLabel: 'cse1'
//     }
//   }
// }

// ---------------------------------------------------------------------------------------------------------------------

resource windowsVM1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vm1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'logitech'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'diskweucse1'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceVM1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri:  storageAccountVM1.properties.primaryEndpoints.blob
      }
    }
  }
}

resource windowsVMExtensions 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
parent: windowsVM1
name: 'CSE1'
location: location
properties: {
  publisher: 'Microsoft.Compute'
  type: 'CustomScriptExtension'
  typeHandlerVersion: '1.10'
  autoUpgradeMinorVersion: true
protectedSettings: {
  commandToExecute: 'powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)'
}  
}
}

// -----------------------------------------------------------------------------------

// resource publicIPAddressVM2 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
//   name: publicIPVM2Name
//   location: location
//   properties: {
//     publicIPAllocationMethod: 'Dynamic'
//     dnsSettings: {
//       domainNameLabel: 'cse2'
//     }
//   }
// }


resource windowsVM2 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vm2Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'intern'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'diskweucse2'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceVM2.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri:  storageaccountVM2.properties.primaryEndpoints.blob
      }
    }
  }
}

// ---------------------------------------------------------------------------------------------------------


resource windowsVMExt 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: windowsVM2
  name: 'CSE2'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
  protectedSettings: {
    commandToExecute: 'powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)'
  }  
  }
  }



// resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
// name: storageAccountName
// scope: resourceGroup(storageAccountRGName)
// }

// -----------------------------------------------------------------------------------------------------------------

resource networkInterfaceVM1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-weu-VM1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigVM1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          // publicIPAddress: {
          //   id: publicIPAddressVM1.id
          // }
        loadBalancerBackendAddressPools: [
          {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
          }
        ]
          subnet: {
            id: subnetRefLB
          }
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------------------------------------------


resource storageAccountVM1 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountVM1Name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

// -----------------------------------------------------------------------------------------------

resource networkInterfaceVM2 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-weu-VM2'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfigVM2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          // publicIPAddress: {
          //   id: publicIPAddressVM2.id
          // }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool1')
            }
          ]
          subnet: {
            id: subnetRefLB
          }
        }
      }
    ]
  }
}

resource storageaccountVM2 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountVM2Name
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}


// ------------------------------------------------------------------------------------------------------------------

  
  resource vNet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
    name: vNetName
    location: location
    properties: {
      addressSpace: {
        addressPrefixes: [
          addressPrefix
        ]
      }
      subnets: [
        {
          name: subnetName
          properties: {
            addressPrefix: subnetPrefix
          }
        }
        // {
        //   name: 'Subnet-2'
        //   properties: {
        //     addressPrefix: '10.0.1.0/24'
        //   }
        // }
      ]
    }
  }
