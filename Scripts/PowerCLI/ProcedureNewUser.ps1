#Script by Joel Cressy (http://github.com/jtcressy)
if(!(Get-Module PowerCLI*)){
    #import powercli modules if not already imported
    Get-Module -ListAvailable PowerCLI* | Import-Module
}
#Editable Variables
$DefaultRAM = "8192"
$DefaultCPU = "20000"
$ADNetBIOSName = "CRL"

#connect to vcenter, will prompt for admin username/password
if(Connect-VIServer vcenter.crl.coloradomesa.edu)
{

    #get information
    if(($NewUser = Read-Host -Prompt 'Input New Username') -eq '')
    {
        Write-Host "ERR: Username Required"
        break
    }
    #check if user exists
    if((Get-ADUser -LDAPFilter "(sAMAccountName=$NewUser)") -eq $Null)
    {
        Write-Host "ERR: User does not exist"
        break
    }
    $NewUserPrincipal = $ADNetBIOSName + "\" + $NewUser
    Write-Host "Press enter to accept defaults in [] or enter custom amount"
    if(($RAMLimit = Read-Host -Prompt 'Input max RAM usage in MB [$DefaultRAM]') -eq ''){$RAMLimit = $DefaultRAM}
    if(($CPULimit = Read-Host -Prompt 'Input max CPU usage in MHz [$DefaultCPU]') -eq ''){$CPULimit = $DefaultCPU}
    
    #Locate containing folder/resource pool
    $UsersResourcePool = Get-ResourcePool -Location VMServs -Name Users
    $UsersFolder = Get-Folder -Location "CSMS Server Room" -Name Students
    
    #check to make sure no folder is already created
    if(!(Get-Folder -Location "CSMS Server Room" -Name $NewUser -Erroraction 'silentlycontinue'))
    {
        #create folder
        $NewFolder = New-Folder -Location $UsersFolder -Name $NewUser
        Write-Host "User Folder Created For User $NewUser"
        #apply permission to folder
        New-VIPermission -Role "VM Folder Owner" -Entity $NewFolder -Propagate $true -Principal $NewUserPrincipal -WarningAction 'silentlycontinue'
    }
    else
    {
        Write-Host "User Folder Already Exists"
        #check if permission exists
        if(!(Get-VIPermission -Entity (Get-Folder -Location $UsersFolder -Name $NewUser) -Principal $NewUserPrincipal -Erroraction 'silentlycontinue'))
        {
            #apply permission to folder
            New-VIPermission -Role "VM Folder Owner" -Entity $NewFolder -Propagate $true -Principal $NewUserPrincipal -WarningAction 'silentlycontinue'
            Write-Host "User Folder Permission Added For User $NewUser"
        }
        else
        {
            Write-Host "User Folder Permission Already Exists"
        }
    }
    #check to make sure no resource pool is already created
    if(!(Get-ResourcePool -Location VMServs -Name $NewUser -Erroraction 'silentlycontinue'))
    {
        #create resource pool
        $NewResourcePool = New-ResourcePool -Location $UsersResourcePool -Name $NewUser -CpuLimitMhz $CPULimit -MemLimitMB $RAMLimit
        Write-Host "Resource Pool Created For User $NewUser"
        #Apply permission to resource pool
        New-VIPermission -Role "Compute Consumer" -Entity $NewResourcePool -Propagate $true -Principal $NewUserPrincipal -WarningAction 'silentlycontinue'
    }
    else
    {
        Write-Host "User Resource Pool Already Exists"
        #check if permission exists
        if(!(Get-VIPermission -Entity (Get-ResourcePool -Location $UsersResourcePool -Name $NewUser) -Principal $NewUserPrincipal -Erroraction 'silentlycontinue'))
        {
            #Apply permission to resource pool
            New-VIPermission -Role "Compute Consumer" -Entity $NewResourcePool -Propagate $true -Principal $NewUserPrincipal -WarningAction 'silentlycontinue'
            Write-Host "Resource Pool Permission Added For User $NewUser"
        }
        else
        {
            Write-Host "User Resource Pool Permission Already Exists"
        }
    }
}
else
{
    Write-Host "ERR: Invalid Credentials / Could Not Logon To VIServer"
}