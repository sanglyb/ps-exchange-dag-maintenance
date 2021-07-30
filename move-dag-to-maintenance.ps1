$servername="mx1"
$target="mx2"
$dag="dagName"
 
#Ввод в режим обслуживания
Set-ServerComponentState $servername -Component HubTransport -State Draining -Requester Maintenance
Restart-Service MSExchangeTransport
#Set-ServerComponentState $servername -Component UMCallRouter -State Draining -Requester Maintenance
CD $ExScripts
.\StartDagServerMaintenance.ps1 -ServerName $servername -MoveComment Maintenance -PauseClusterNode
Redirect-Message -Server $servername -Target $target
Set-ServerComponentState $servername -Component ServerWideOffline -State Inactive -Requester Maintenance
 
#Проверка
Get-ServerComponentState $servername | Format-Table Component,State -Autosize
Get-MailboxServer $servername | Format-List DatabaseCopyAutoActivationPolicy
Get-ClusterNode $servername | Format-List
get-mailboxdatabasecopystatus
 
#Если нужно остановить все сервисы Exchange
$exchangeServices=Get-Service | Where-Object {$_.DisplayName -like "*Microsoft Exchange*"} | Where-Object {$_.Starttype -like "*Automatic*"}
$exchangeservices | stop-service
$exchangeservices | start-service
 
#Вывод из режима обслуживания
Set-ServerComponentState $servername -Component ServerWideOffline -State Active -Requester Maintenance
#Set-ServerComponentState $servername -Component UMCallRouter -State Active -Requester Maintenance
CD $ExScripts
.\StopDagServerMaintenance.ps1 -serverName $servername
Set-ServerComponentState $servername -Component HubTransport -State Active -Requester Maintenance
Restart-Service MSExchangeTransport
.\RedistributeActiveDatabases.ps1 -dag $dag -BalanceDbsByActivationPreference
 
 
#Проверка
Get-ServerComponentState $servername | Format-Table Component,State -Autosize
get-mailboxdatabasecopystatus