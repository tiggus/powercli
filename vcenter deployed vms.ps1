# git
$vcenters = <vcenterFQDN>
$domain = <domain>
$searchmsg = '*deploying*'
$samples = 150000 
$days = -90
$date = (Get-Date).tostring('ddMMyyyy-HHmm')
$outfiles = @()
[array]$vms=@()
[array]$searchervms=@()
$vcuser = <vcuser>
$vcpassword = <vcuserpass>
foreach ($singlevc in $vcenters){
    if ($defaultviservers) { Disconnect-VIServer * -Force -Confirm:$false -ErrorAction SilentlyContinue}
    Connect-VIServer $singlevc -user $vcuser -Password $vcpassword -WarningAction SilentlyContinue -InformationAction SilentlyContinue -Force
    $searcher = Get-VIEvent -start (Get-Date).adddays($days) -MaxSamples $samples | Where-Object {$_.FullFormattedMessage -like $searchmsg} 
    if ($searcher){
		foreach ($virtual in $searcher) {  
	    	$vm=New-Object PsObject
	       	Add-Member -InputObject $vm -MemberType NoteProperty -Name vmname -Value $virtual.vm.Name
           	Add-Member -InputObject $vm -MemberType NoteProperty -Name vcenter -Value ($singlevc -replace $domain,'')
	       	Add-Member -InputObject $vm -MemberType NoteProperty -Name source -Value $virtual.SrcTemplate.Name
           	Add-Member -InputObject $vm -MemberType NoteProperty -Name created -Value (get-date $virtual.CreatedTime -Format 'dd/MM/yyyy HH:mm')
            	Add-Member -InputObject $vm -MemberType NoteProperty -Name user -Value ($virtual.UserName -replace ($domain + '\\'),'')
            	Add-Member -InputObject $vm -MemberType NoteProperty -Name message -Value $virtual.FullFormattedMessage
	        $vms+=$vm
    	}
    }
   Disconnect-VIServer * -Force -Confirm:$false -ErrorAction SilentlyContinue
}
if ($vms){
    write-host 'deployed:' $vms.count -ForegroundColor Green
    $path = 'c:\temp\searcherEvent-' + $date + '.csv'
    $vms | Export-Csv $path -NoTypeInformation
}
else {write-host 'no events' -ForegroundColor Yellow}
