function Process-Terms {
    param (
        [Parameter(Mandatory = $true)]
        $Terms,
        $TermStore,
        $TermSetId,
        $NewUrlBase
    )

    $result = @()

    foreach ($term in $Terms) {
        # Retrieve the associated navigation term
        $navTerm = $TermStore.GetTerm($term.Id)
        $TermStore.Context.Load($navTerm)
        $TermStore.Context.ExecuteQuery()

        if ($navTerm.TargetUrl -ne $null) {
            # Construct the new URL based on the term data
            $newUrl = $NewUrlBase + "[new page path based on term data].aspx"
            
            # Build term data
            $termData = @{
                TermSetId = $TermSetId
                TermId = $term.Id.ToString()
                NewUrl = $newUrl
            }
            $result += $termData
        }

        # Process child terms if any
        if ($term.Terms -and $term.Terms.Count -gt 0) {
            $childResults = Process-Terms -Terms $term.Terms -TermStore $TermStore -TermSetId $TermSetId -NewUrlBase $NewUrlBase
            $result += $childResults
        }
    }

    return $result
}

# Variables
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$termGroupId = "your-term-group-id"
$termSetName = "your-term-set-name"
$termSetId = "your-term-set-id" # Add the correct Term Set ID
$newUrlBase = "https://yourtenant.sharepoint.com/sites/newsite/sitepages/"
$outputFile = "term-mapping.json"

# Connect to SPO
Connect-PnPOnline -Url $siteUrl -Interactive

# Retrieve the term set and term store
$termGroup = Get-PnPTermGroup -Identity $termGroupId
$termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $termGroup
$termStore = $termSet.TermStore

# Retrieve terms including child terms
$terms = Get-PnPTerm -TermSet $termSet -TermGroup $termGroup -IncludeChildTerms

# Process terms to build mapping
$termMapping = Process-Terms -Terms $terms -TermStore $termStore -TermSetId $termSetId -NewUrlBase $newUrlBase

# Write to JSON
$termMapping | ConvertTo-Json -Depth 100 | Out-File $outputFile

# Output completion message
Write-Host "Term mapping exported to $outputFile"
