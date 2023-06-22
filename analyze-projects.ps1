$baseUrl = "https://dev.azure.com/Xpirit"
$pat = "xxx"
$baseReleaseUrl = $baseUrl.replace('https://dev.', 'https://vsrm.dev.')
$queryString = "api-version=7.0"

Write-Host $baseReleaseUrl

$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$headers = @{authorization = "Basic $token"}

Write-Host "Getting all projects... "

$projects = Invoke-RestMethod -Uri "$baseUrl/_apis/projects?$queryString" -Method Get -ContentType "application/json" -Headers $headers

$index = 0

$list = @() 

foreach($project in $projects.value) {
    $projectName = $project.name
    $index += 1

    Write-Host "Collecting all the required values for $projectName ..."

    $list += [PSCustomObject]@{
        Project = $projectName
        Repos = (Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/git/repositories?$queryString" -Method Get -ContentType "application/json" -Headers $headers).count
        PullRequests = (Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/git/pullrequests?$queryString" -Method Get -ContentType "application/json" -Headers $headers).count
        PipelineDefinitions = (Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/pipelines?$queryString" -Method Get -ContentType "application/json" -Headers $headers).count
        ReleaseDefinitions = (Invoke-RestMethod -Uri "$baseReleaseUrl/$projectName/_apis/release/definitions?$queryString" -Method Get -ContentType "application/json" -Headers $headers).count
       }
}

if($list.Count -gt 0) {
    $list | Export-Csv "project-state.csv" -NoTypeInformation
}