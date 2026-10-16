Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-IntegrationBlobSha {
    param([Parameter(Mandatory)][AllowEmptyString()][string] $Content)

    $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes("blob $($contentBytes.Length)`0")
    $hashBytes = [System.Security.Cryptography.SHA1]::HashData([byte[]]($headerBytes + $contentBytes))
    return [Convert]::ToHexString($hashBytes).ToLowerInvariant()
}

function Get-IntegrationProposalFiles {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Files,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.IDictionary] $BaseFiles
    )

    $changes = [ordered]@{}
    foreach ($filePath in ($Files.Keys | Sort-Object)) {
        $file = $Files[$filePath]
        if ($filePath -match '(^/|\\|(^|/)\.\.(/|$))') {
            throw "Invalid proposal path: $filePath"
        }
        if ($file.bootstrap -and $BaseFiles.Contains($filePath)) {
            continue
        }
        $blobSha = Get-IntegrationBlobSha -Content $file.content
        if (-not $BaseFiles.Contains($filePath) -or $BaseFiles[$filePath].sha -ne $blobSha) {
            if ($BaseFiles.Contains($filePath) -and $BaseFiles[$filePath].mode -ne '100644') {
                throw "Refusing to replace a non-regular file: $filePath"
            }
            $changes[$filePath] = @{ content = $file.content; sha = $blobSha }
        }
    }
    return $changes
}

function Get-IntegrationDigest {
    param([Parameter(Mandatory)][string] $Value)

    return [Convert]::ToHexString(
        [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($Value))
    ).ToLowerInvariant()
}

function Invoke-IntegrationGitHubApi {
    param(
        [Parameter(Mandatory)][hashtable] $Context,
        [Parameter(Mandatory)][string] $Path,
        [ValidateSet('GET', 'POST', 'PATCH')][string] $Method = 'GET',
        [hashtable] $Body,
        [switch] $AllowNotFound
    )

    $request = @{
        Uri = "$($Context.api_url.TrimEnd('/'))/$Path"
        Method = $Method
        Headers = @{
            Authorization = "Bearer $($Context.token)"
            Accept = 'application/vnd.github+json'
            'User-Agent' = 'xms-integration-proposals'
        }
    }
    if ($Body) {
        $request.ContentType = 'application/json; charset=utf-8'
        $request.Body = [System.Text.Encoding]::UTF8.GetBytes(($Body | ConvertTo-Json -Depth 50 -Compress))
    }
    try {
        $response = Invoke-WebRequest @request
        return ConvertFrom-Json -InputObject $response.Content -AsHashtable
    }
    catch {
        $responseProperty = $_.Exception.PSObject.Properties['Response']
        $statusCode = if ($responseProperty -and $responseProperty.Value) { [int]$responseProperty.Value.StatusCode } else { 0 }
        if ($AllowNotFound -and $statusCode -eq 404) { return $null }
        throw "GitHub request failed ($statusCode): $Method $Path. Check access, branch rules, or concurrent changes; retry the deployment."
    }
}

function Get-IntegrationGitTree {
    param([hashtable] $Context, [string] $RepositoryPath, [string] $CommitSha)

    $commit = Invoke-IntegrationGitHubApi -Context $Context -Path "$RepositoryPath/git/commits/$CommitSha"
    $tree = Invoke-IntegrationGitHubApi -Context $Context -Path "$RepositoryPath/git/trees/$($commit.tree.sha)?recursive=1"
    if ($tree.truncated) { throw 'Repository tree is truncated; refusing to publish an incomplete comparison.' }
    $files = @{}
    foreach ($entry in $tree.tree) { $files[$entry.path] = $entry }
    return @{ commit = $commit; files = $files }
}

function Invoke-IntegrationProposal {
    param(
        [Parameter(Mandatory)][hashtable] $Manifest,
        [Parameter(Mandatory)][hashtable] $Context
    )

    $apiUri = [uri]$Context.api_url
    if ($apiUri.Scheme -ne 'https' -or $apiUri.UserInfo -or $apiUri.Query -or $apiUri.Fragment) {
        throw 'github_api_url must be an HTTPS API URL without credentials, query, or fragment.'
    }
    if ($apiUri.Host -ne 'api.github.com' -and $apiUri.AbsolutePath.Trim('/') -eq '') {
        $Context.api_url = "$($Context.api_url.TrimEnd('/'))/api/v3"
    }
    if ([string]::IsNullOrWhiteSpace($Context.token)) {
        throw 'Set github_token, GH_TOKEN, or GITHUB_TOKEN for the proposal publisher.'
    }
    $owner = [uri]::EscapeDataString($Manifest.owner)
    $repository = [uri]::EscapeDataString($Manifest.repository)
    $repositoryPath = "repos/$owner/$repository"
    $repo = Invoke-IntegrationGitHubApi -Context $Context -Path $repositoryPath
    $baseBranch = $repo.default_branch
    $baseRefPath = "$repositoryPath/git/ref/heads/$([uri]::EscapeDataString($baseBranch))"
    $baseRef = Invoke-IntegrationGitHubApi -Context $Context -Path $baseRefPath -AllowNotFound
    if (-not $baseRef) {
        throw 'The repository must have an initial commit (enable repository_auto_init). No default-branch writes were made.'
    }
    $baseSha = $baseRef.object.sha
    $base = Get-IntegrationGitTree -Context $Context -RepositoryPath $repositoryPath -CommitSha $baseSha
    $changes = Get-IntegrationProposalFiles -Files $Manifest.files -BaseFiles $base.files
    if ($changes.Count -eq 0) {
        return @{ status = 'no_changes'; url = '' }
    }

    $identity = Get-IntegrationDigest "$($Manifest.owner)/$($Manifest.repository)/$($Manifest.identity)"
    $revisionFiles = [ordered]@{}
    foreach ($filePath in ($Manifest.files.Keys | Sort-Object)) {
        $revisionFiles[$filePath] = [ordered]@{
            sha = Get-IntegrationBlobSha $Manifest.files[$filePath].content
            bootstrap = $Manifest.files[$filePath].bootstrap
        }
    }
    $revision = Get-IntegrationDigest (($revisionFiles | ConvertTo-Json -Depth 10 -Compress) + $Manifest.revision)
    $identityMarker = "<!-- xms-integration:${identity}:"
    $revisionMarker = "$identityMarker$revision -->"
    $pullRequests = @()
    $page = 1
    do {
        $batch = @(Invoke-IntegrationGitHubApi -Context $Context -Path "$repositoryPath/pulls?state=all&per_page=100&page=$page")
        $pullRequests += @($batch | Where-Object { $_.body -and $_.body.Contains($identityMarker) })
        $page++
    } while ($batch.Count -eq 100)
    $open = @($pullRequests | Where-Object { $_.state -eq 'open' })
    if ($open.Count -gt 1) { throw 'Multiple open proposals exist for this spoke. Close duplicates before retrying.' }
    $rejected = @($pullRequests | Where-Object {
        $_.state -eq 'closed' -and -not $_.merged_at -and $_.body.Contains($revisionMarker)
    })
    if ($open.Count -eq 0 -and $rejected.Count -gt 0) {
        return @{ status = 'rejected'; url = $rejected[0].html_url }
    }

    $branch = if ($open.Count -eq 1) {
        $open[0].head.ref
    }
    else {
        "xms/integration-$($identity.Substring(0, 16))-$($revision.Substring(0, 16))-$($baseSha.Substring(0, 12))"
    }
    if ($branch -eq $baseBranch -or -not $branch.StartsWith("xms/integration-$($identity.Substring(0, 16))")) {
        throw 'Unexpected proposal branch; refusing to write.'
    }
    $branchRefPath = "$repositoryPath/git/ref/heads/$([uri]::EscapeDataString($branch))"
    $branchRef = Invoke-IntegrationGitHubApi -Context $Context -Path $branchRefPath -AllowNotFound
    if (-not $branchRef) {
        if ($open.Count -eq 1) { throw 'The open proposal branch was deleted. Close the PR before retrying.' }
        $branchRef = Invoke-IntegrationGitHubApi -Context $Context -Method POST -Path "$repositoryPath/git/refs" -Body @{
            ref = "refs/heads/$branch"; sha = $baseSha
        }
    }
    $headSha = $branchRef.object.sha
    $head = Get-IntegrationGitTree -Context $Context -RepositoryPath $repositoryPath -CommitSha $headSha
    if ($headSha -ne $baseSha) {
        if ($head.commit.message -notmatch '(?m)^XMS-Integration-Manifest: ([A-Za-z0-9+/=]+)$') {
            throw 'Proposal branch contains reviewer commits. Preserve or merge them before retrying.'
        }
        $metadata = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Matches[1])) | ConvertFrom-Json -AsHashtable
        if ($metadata.identity -ne $identity -or $metadata.tree -ne $head.commit.tree.sha) {
            throw 'Proposal branch was edited outside the publisher. Preserve or merge those edits before retrying.'
        }
    }

    $entries = @($changes.Keys | ForEach-Object {
        @{ path = $_; mode = '100644'; type = 'blob'; content = $changes[$_].content }
    })
    $tree = Invoke-IntegrationGitHubApi -Context $Context -Method POST -Path "$repositoryPath/git/trees" -Body @{
        base_tree = $base.commit.tree.sha; tree = $entries
    }
    if ($tree.sha -ne $head.commit.tree.sha) {
        $metadataJson = @{ identity = $identity; tree = $tree.sha } | ConvertTo-Json -Compress
        $metadataEncoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($metadataJson))
        $parents = if ($headSha -eq $baseSha) { @($headSha) } else { @($headSha, $baseSha) }
        $commit = Invoke-IntegrationGitHubApi -Context $Context -Method POST -Path "$repositoryPath/git/commits" -Body @{
            message = "Propose integration configuration for $($Manifest.identity)`n`nXMS-Integration-Manifest: $metadataEncoded"
            tree = $tree.sha
            parents = @($parents)
        }
        $currentBase = Invoke-IntegrationGitHubApi -Context $Context -Path $baseRefPath
        $currentHead = Invoke-IntegrationGitHubApi -Context $Context -Path $branchRefPath
        if ($currentBase.object.sha -ne $baseSha -or $currentHead.object.sha -ne $headSha) {
            throw 'A branch changed during publishing. No branch update was made; retry the deployment.'
        }
        $null = Invoke-IntegrationGitHubApi -Context $Context -Method PATCH -Path "$repositoryPath/git/refs/heads/$([uri]::EscapeDataString($branch))" -Body @{
            sha = $commit.sha; force = $false
        }
    }

    $pullRequestBody = @{
        title = "Integration configuration: $($Manifest.identity)"
        body = "Review the proposed spoke configuration before merging. Existing shared workload files are retained. No automatic merge is performed.`n`n$revisionMarker"
        base = $baseBranch
    }
    if ($open.Count -eq 1) {
        $pullRequest = $open[0]
        if ($pullRequest.body -ne $pullRequestBody.body -or $pullRequest.base.ref -ne $baseBranch) {
            $pullRequest = Invoke-IntegrationGitHubApi -Context $Context -Method PATCH -Path "$repositoryPath/pulls/$($pullRequest.number)" -Body $pullRequestBody
        }
    }
    else {
        $pullRequestBody.head = $branch
        $pullRequest = Invoke-IntegrationGitHubApi -Context $Context -Method POST -Path "$repositoryPath/pulls" -Body $pullRequestBody
    }
    return @{ status = 'proposed'; url = $pullRequest.html_url }
}

if ($MyInvocation.InvocationName -ne '.') {
    $manifestJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:XMS_PROPOSAL_MANIFEST))
    $manifest = ConvertFrom-Json -InputObject $manifestJson -AsHashtable
    $token = $env:XMS_PROPOSAL_TOKEN
    if ([string]::IsNullOrWhiteSpace($token)) { $token = $env:GH_TOKEN }
    if ([string]::IsNullOrWhiteSpace($token)) { $token = $env:GITHUB_TOKEN }
    $result = Invoke-IntegrationProposal -Manifest $manifest -Context @{ api_url = $env:XMS_GITHUB_API_URL; token = $token }
    Write-Host "Integration proposal: $($result.status) $($result.url)"
}