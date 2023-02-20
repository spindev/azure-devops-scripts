$baseUrl = "###"
$pat = "###"
$queryString = "api-version=6.0"

$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$headers = @{authorization = "Basic $token"}

Write-Host "Getting all projects... "

$projects = Invoke-RestMethod -Uri "$baseUrl/_apis/projects?$queryString" -Method Get -ContentType "application/json" -Headers $headers
$projectCount = $projects.count
$index = 0

foreach($project in $projects.value)
{
    $projectName = $project.name
    $index += 1

    Write-Host "Getting all test runs for $projectName... ($index/$projectCount)"

    $list = @() 

    $runs = Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/test/runs?$queryString" -Method Get -ContentType "application/json" -Headers $headers
    
    foreach($run in $runs.value)
    {
        $runId = $run.id

        try {
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
        catch {
            Write-Host "Testrun $runId already deleted..."
        }
    }

    if($list.Count -gt 0)
    {
        $list | Export-Csv "$projectName.csv" -NoTypeInformation
    }
}
