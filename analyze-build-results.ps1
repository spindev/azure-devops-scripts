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

    $builds = Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/build/builds?$queryString" -Method Get -ContentType "application/json" -Headers $headers
    
    foreach($build in $builds.value)
    {
        $buildId = $build.id

        try {
            $artifacts = Invoke-RestMethod -Uri "$baseUrl/$projectName/_apis/build/builds/$buildId/artifacts?$queryString" -Method Get -ContentType "application/json" -Headers $headers
        
            foreach($artifact in $artifacts.value)
            {
                $list += [PSCustomObject]@{
                    Project = $projectName
                    BuildDefinition = $build.definition.name
                    BuildNumber = $build.buildNumber
                    BuildUrl = $build.url
                    Artifact = $artifact.name
                     SizeInKB    = [math]::ceiling($artifact.resource.properties.artifactsize / 1000)
                    Date = $build.startTime.ToString("dd.MM.yyyy")
                }
            }
        }
        catch {
            Write-Host "Build $buildId already deleted..."
        }
    }

    if($list.Count -gt 0)
    {
        $list | Export-Csv "$projectName.csv" -NoTypeInformation
    }
}
