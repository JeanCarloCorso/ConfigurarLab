param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}



$dominio = "cetesc.net"
$pc = Get-CimInstance -ClassName Win32_ComputerSystem
$rede = Get-NetAdapter

$CSV = Import-Csv "C:\Users\di\Desktop\NomesPCLab.csv"

$mac = @()
$nome = @()

$CSV | ForEach-Object{
    $mac += $_.mac
    $nome += $_.nome
}

$posicao = 0
$contem = $false
For ($i=0; $i -lt $mac.Count; $i++){
    if($mac[$i] -eq $rede.MacAddress){
        $posicao = $i
        $contem = $true
        break
    }
}

if(!($contem)){
    Write-Warning "O endereço mec deste dispositivo não foi encontrado"
}else{
    
    Write-Warning "Esta maquina atualmente possui estas configurações: "
    Write-Output ""
    Write-Host 'Nome atual: '$pc.Name
    Write-Host 'Dominio atual: '$pc.Domain
    Write-Host 'Mec: '$rede.MacAddress
    Write-Output ""

    if(!($pc.Name -eq $nome[$posicao]) -or (!($pc.Domain -eq $dominio))){
        Write-Warning "Seu PC sofrerá alterações ao fim do processo:"
        Write-Output ""
        Write-Output "Novo Nome: $($nome[$posicao])"
        Write-Output "Novo Dominio: $dominio"
        Write-Output ""
        Write-Warning "Seu computador será reiniciado altomaticamente no decorrer do processo. Realmente deseja proseguir? (s) (n)"
        $escolha = Read-Host
        if(($escolha -eq "s") -or ($escolha -eq "S")){
        
            if(!($nome[$posicao] -eq $pc.Name)){
                Rename-Computer -NewName $nome[$posicao] -Restart
            } else {
                if(!($dominio -eq $pc.Domain)){
                    $cred = Get-Credential
                    Add-Computer -DomainName $dominio -Credential $cred -Restart
                }
            }
        }
    }else{
        Write-Warning "Esta maquina já está configurada!!!"
    }
}







