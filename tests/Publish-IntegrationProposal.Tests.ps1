BeforeAll {
    . "$PSScriptRoot/../scripts/Publish-IntegrationProposal.ps1"
}

Describe 'Integration proposal file selection' {
    It 'uses Git blob hashing including UTF-8 byte length' {
        Get-IntegrationBlobSha -Content '' | Should -Be 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391'
        Get-IntegrationBlobSha -Content "hello`n" | Should -Be 'ce013625030ba8dba906f756967f9e9ca394464a'
    }

    It 'preserves customized shared files and selects only its environment configuration' {
        $files = @{
            'main.tf' = @{ content = 'starter'; bootstrap = $true }
            'config/dev.tfvars' = @{ content = 'updated'; bootstrap = $false }
        }
        $baseFiles = @{
            'main.tf' = @{ sha = 'customized'; mode = '100644' }
            'config/dev.tfvars' = @{ sha = 'old'; mode = '100644' }
            'config/acc.tfvars' = @{ sha = 'acc'; mode = '100644' }
        }

        $changes = Get-IntegrationProposalFiles -Files $files -BaseFiles $baseFiles
        @($changes.Keys) | Should -Be @('config/dev.tfvars')
    }

    It 'does not propose identical files' {
        $files = @{ 'config/dev.tfvars' = @{ content = 'same'; bootstrap = $false } }
        $baseFiles = @{ 'config/dev.tfvars' = @{ sha = (Get-IntegrationBlobSha 'same'); mode = '100644' } }

        (Get-IntegrationProposalFiles -Files $files -BaseFiles $baseFiles).Count | Should -Be 0
    }

    It 'proposes missing starter files' {
        $files = @{ 'main.tf' = @{ content = 'starter'; bootstrap = $true } }
        (Get-IntegrationProposalFiles -Files $files -BaseFiles @{}).Count | Should -Be 1
    }

    It 'refuses to replace a symlink with environment configuration' {
        $files = @{ 'config/dev.tfvars' = @{ content = 'updated'; bootstrap = $false } }
        $baseFiles = @{ 'config/dev.tfvars' = @{ sha = 'link'; mode = '120000' } }

        { Get-IntegrationProposalFiles -Files $files -BaseFiles $baseFiles } | Should -Throw '*non-regular*'
    }
}

Describe 'Integration proposal publishing' {
    BeforeEach {
        $script:baseSha = 'a' * 40
        $script:headSha = $script:baseSha
        $script:baseFiles = @{}
        $script:pullRequests = @()
        $script:writes = [System.Collections.Generic.List[hashtable]]::new()
        $script:branchExists = $false
        $script:headMessage = 'Initial commit'
        $script:headTree = 'base-tree'
        $script:nextTree = 'proposal-tree'
        $script:moveBase = $false
        $script:manifest = @{
            owner = 'workloads'; repository = 'crm'; identity = 'crm-dev'; revision = ''
            files = @{
                'main.tf' = @{ content = 'starter'; bootstrap = $true }
                'config/dev.tfvars' = @{ content = 'dev'; bootstrap = $false }
            }
        }
        $script:context = @{ api_url = 'https://enterprise.example/api/v3'; token = 'test-token' }

        Mock Invoke-IntegrationGitHubApi {
            param($Context, $Path, $Method = 'GET', $Body, $AllowNotFound)
            if ($Method -ne 'GET') { $script:writes.Add(@{ path = $Path; method = $Method; body = $Body }) }
            if ($Path -eq 'repos/workloads/crm') { return @{ default_branch = 'trunk' } }
            if ($Path -eq 'repos/workloads/crm/git/ref/heads/trunk') {
                return @{ object = @{ sha = $script:baseSha } }
            }
            if ($Path -like '*/pulls?state=*') { return $script:pullRequests }
            if ($Path -like '*/git/ref/heads/xms*') {
                if (-not $script:branchExists) { return $null }
                return @{ object = @{ sha = $script:headSha } }
            }
            if ($Path -like '*/git/commits/*') {
                if ($Path.EndsWith($script:baseSha)) {
                    return @{ tree = @{ sha = 'base-tree' }; message = 'Initial commit' }
                }
                return @{ tree = @{ sha = $script:headTree }; message = $script:headMessage }
            }
            if ($Path -like '*/git/trees/*') {
                return @{ truncated = $false; tree = @($script:baseFiles.Values) }
            }
            if ($Path -like '*/git/refs' -and $Method -eq 'POST') {
                $script:branchExists = $true
                return @{ object = @{ sha = $script:headSha } }
            }
            if ($Path -like '*/git/trees' -and $Method -eq 'POST') { return @{ sha = $script:nextTree } }
            if ($Path -like '*/git/commits' -and $Method -eq 'POST') {
                $script:headMessage = $Body.message
                if ($script:moveBase) { $script:baseSha = 'c' * 40 }
                return @{ sha = ('b' * 40) }
            }
            if ($Path -like '*/git/refs/heads/*' -and $Method -eq 'PATCH') {
                $script:headSha = $Body.sha
                $script:headTree = $script:nextTree
                return @{}
            }
            if ($Path -match '/pulls(/\d+)?$' -and $Method -in @('POST', 'PATCH')) {
                $branch = if ($Body.ContainsKey('head')) { $Body.head } else { $script:pullRequests[0].head.ref }
                $script:pullRequests = @(@{
                    number = 1; html_url = 'https://enterprise.example/workloads/crm/pull/1'
                    state = 'open'; merged_at = $null; body = $Body.body
                    head = @{ ref = $branch }; base = @{ ref = $Body.base }
                })
                return $script:pullRequests[0]
            }
            throw "Unexpected mock request: $Method $Path"
        }
    }

    It 'creates one atomic proposal against the actual default branch without force updates' {
        $result = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $result.status | Should -Be 'proposed'
        $treeWrite = @($writes | Where-Object { $_.path -like '*/git/trees' })
        $treeWrite.Count | Should -Be 1
        $treeWrite[0].body.tree.Count | Should -Be 2
        @($writes | Where-Object { $_.path -like '*/git/refs/heads/trunk' }).Count | Should -Be 0
        @($writes | Where-Object { $_.body.ContainsKey('force') })[0].body.force | Should -BeFalse
        $pullRequests[0].base.ref | Should -Be 'trunk'
    }

    It 'reuses the open PR without another commit on an identical deployment' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $writes.Clear()
        $result = Invoke-IntegrationProposal -Manifest $manifest -Context $context

        $result.status | Should -Be 'proposed'
        @($writes | Where-Object { $_.path -like '*/git/commits' -or $_.path -like '*/pulls' }).Count | Should -Be 0
    }

    It 'updates the same open PR for changed spoke data' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $writes.Clear()
        $manifest.files['config/dev.tfvars'].content = 'new-dev'
        $script:nextTree = 'updated-tree'
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context

        @($writes | Where-Object { $_.path -like '*/pulls' }).Count | Should -Be 0
        @($writes | Where-Object { $_.path -like '*/pulls/1' }).Count | Should -Be 1
        @($writes | Where-Object { $_.path -like '*/git/commits' }).Count | Should -Be 1
    }

    It 'does not reopen a rejected unchanged proposal even after its branch is deleted' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $script:pullRequests[0].state = 'closed'
        $script:branchExists = $false
        $writes.Clear()

        (Invoke-IntegrationProposal -Manifest $manifest -Context $context).status | Should -Be 'rejected'
        $writes.Count | Should -Be 0
    }

    It 'creates a new proposal after rejection when desired configuration changes' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $script:pullRequests[0].state = 'closed'
        $script:branchExists = $false
        $script:headSha = $script:baseSha
        $manifest.files['config/dev.tfvars'].content = 'new-dev'
        $writes.Clear()

        (Invoke-IntegrationProposal -Manifest $manifest -Context $context).status | Should -Be 'proposed'
        @($writes | Where-Object { $_.path -like '*/pulls' }).Count | Should -Be 1
    }

    It 'does not write when all intended files are already merged' {
        foreach ($filePath in $manifest.files.Keys) {
            $script:baseFiles[$filePath] = @{
                path = $filePath; sha = Get-IntegrationBlobSha $manifest.files[$filePath].content; mode = '100644'
            }
        }
        (Invoke-IntegrationProposal -Manifest $manifest -Context $context).status | Should -Be 'no_changes'
        $writes.Count | Should -Be 0
    }

    It 'creates another PR after a merge and deleted branch for new spoke data' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $script:pullRequests[0].state = 'closed'
        $script:pullRequests[0].merged_at = '2026-10-16'
        $script:branchExists = $false
        $script:baseSha = 'c' * 40
        $script:headSha = $script:baseSha
        $manifest.files['config/dev.tfvars'].content = 'new-dev'
        $writes.Clear()

        (Invoke-IntegrationProposal -Manifest $manifest -Context $context).status | Should -Be 'proposed'
        @($writes | Where-Object { $_.path -like '*/pulls' }).Count | Should -Be 1
    }

    It 'preserves reviewer commits by refusing to rebuild their proposal branch' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $script:headMessage = 'Reviewer customization'
        $writes.Clear()

        { Invoke-IntegrationProposal -Manifest $manifest -Context $context } | Should -Throw '*reviewer commits*'
        $writes.Count | Should -Be 0
    }

    It 'does not update branches if the default branch moves during publication' {
        $script:moveBase = $true
        { Invoke-IntegrationProposal -Manifest $manifest -Context $context } | Should -Throw '*branch changed*'
        @($writes | Where-Object { $_.method -eq 'PATCH' }).Count | Should -Be 0
    }

    It 'uses separate proposal identities for dev and acc in the same repository' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $devBranch = $script:pullRequests[0].head.ref
        $manifest.identity = 'crm-acc'
        $manifest.files.Remove('config/dev.tfvars')
        $manifest.files['config/acc.tfvars'] = @{ content = 'acc'; bootstrap = $false }
        $script:branchExists = $false
        $script:headSha = $script:baseSha
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context

        $script:pullRequests[0].head.ref | Should -Not -Be $devBranch
    }

    It 'fails before API requests without publisher credentials' {
        $context.token = ''
        { Invoke-IntegrationProposal -Manifest $manifest -Context $context } | Should -Throw '*github_token*'
        Should -Invoke Invoke-IntegrationGitHubApi -Times 0 -Exactly
    }

    It 'allows an explicit retry of rejected identical content' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $script:pullRequests[0].state = 'closed'
        $script:branchExists = $false
        $script:headSha = $script:baseSha
        $manifest.revision = 'retry-1'
        $writes.Clear()

        (Invoke-IntegrationProposal -Manifest $manifest -Context $context).status | Should -Be 'proposed'
        @($writes | Where-Object { $_.path -like '*/pulls' }).Count | Should -Be 1
    }

    It 'refuses a tree modified while retaining a generated commit message' {
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $script:headTree = 'reviewer-tree'
        $writes.Clear()

        { Invoke-IntegrationProposal -Manifest $manifest -Context $context } | Should -Throw '*edited outside*'
        $writes.Count | Should -Be 0
    }

    It 'preserves customized shared files while publishing a second environment' {
        $manifest.identity = 'crm-acc'
        $manifest.files.Remove('config/dev.tfvars')
        $manifest.files['config/acc.tfvars'] = @{ content = 'acc'; bootstrap = $false }
        $script:baseFiles['main.tf'] = @{ path = 'main.tf'; sha = 'custom'; mode = '100644' }
        $script:baseFiles['config/dev.tfvars'] = @{ path = 'config/dev.tfvars'; sha = 'dev'; mode = '100644' }

        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $treeWrite = @($writes | Where-Object { $_.path -like '*/git/trees' })[0]
        @($treeWrite.body.tree.path) | Should -Be @('config/acc.tfvars')
    }

    It 'normalizes an Enterprise root URL to the REST API endpoint' {
        $context.api_url = 'https://enterprise.example/'
        $null = Invoke-IntegrationProposal -Manifest $manifest -Context $context
        $context.api_url | Should -Be 'https://enterprise.example/api/v3'
    }
}

Describe 'GitHub API transport' {
    It 'does not disclose credentials or raw network errors' {
        Mock Invoke-WebRequest { throw [System.Net.Http.HttpRequestException]::new('secret-token-in-network-error') }
        $context = @{ api_url = 'https://api.github.com'; token = 'secret-token' }

        { Invoke-IntegrationGitHubApi -Context $context -Path 'repos/workloads/crm' } |
            Should -Throw 'GitHub request failed (0): GET repos/workloads/crm.*'
    }

    It 'sends UTF-8 JSON using the configured Enterprise endpoint' {
        Mock Invoke-WebRequest { @{ Content = '{"sha":"created"}' } }
        $context = @{ api_url = 'https://enterprise.example/api/v3/'; token = 'test-token' }
        $result = Invoke-IntegrationGitHubApi -Context $context -Path 'repos/workloads/crm/git/trees' -Method POST -Body @{ content = 'test' }

        $result.sha | Should -Be 'created'
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://enterprise.example/api/v3/repos/workloads/crm/git/trees' -and
            $Headers.Authorization -eq 'Bearer test-token' -and
            $ContentType -eq 'application/json; charset=utf-8' -and
            ([System.Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json).content -eq 'test'
        }
    }
}

Describe 'Repository file ownership migration' {
    It 'retains every former repository file resource and declares no managed repository files' {
        $proposalConfiguration = Get-Content "$PSScriptRoot/../proposals.tf" -Raw
        $mainConfiguration = Get-Content "$PSScriptRoot/../main.tf" -Raw
        $formerResources = @(
            'spoke_outputs_tfvars', 'backend_config', 'workflow_terraform', 'main_tf', 'variables_tf',
            'outputs_tf', 'versions_tf', 'providers_tf', 'backend_tf', 'readme'
        )
        foreach ($resourceName in $formerResources) {
            $proposalConfiguration | Should -Match "(?s)removed\s*\{\s*from\s*=\s*github_repository_file\.$resourceName\s+lifecycle\s*\{\s*destroy\s*=\s*false\s*\}\s*\}"
        }
        $mainConfiguration | Should -Not -Match 'resource\s+"github_repository_file"'
        $proposalConfiguration | Should -Not -Match 'resource\s+"github_repository_file"'
    }
}