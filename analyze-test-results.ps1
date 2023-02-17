$baseUrl = "###"
$pat = "###"
$queryString = "api-version=6.0"

$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$headers = @{authorization = "Basic $token"}

Write-Host "Getting all projects..."

$projects = Invoke-RestMethod -Uri "$baseUrl/_apis/projects?$queryString" -Method Get -ContentType "application/json" -Headers $headers

foreach($project in $projects.value)
{
    $projectName = $project.name

    Write-Host "Getting all test runs for $projectName..."

    $list = @() 

    $runs = Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/test/runs?$queryString" -Method Get -ContentType "application/json" -Headers $headers | ConvertTo-Json -Depth 10
    
    foreach($run in $runs)
    {
        $runId = $run.id

        $attachments = Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/test/runs/$runId/attachments?$queryString" -Method Get -ContentType "application/json" -Headers $headers
        
        foreach($attachment in $attachments.value)
        {
            $list += [PSCustomObject]@{
                Project = $projectName
                RunName = $run.name
                TestRunUrl = $run.url
                IsAutomated = $run.isAutomated
                Attachment = $attachment.fileName
                SizeInKB    = [math]::ceiling($attachment.size / 1000)
                Date = $attachment.createdDate.ToString("dd.MM.yyyy")
            }
        }
    }

    if($list.Count -gt 0)
    {
        $list | Export-Csv "$projectName.csv" -NoTypeInformation
    }
}
