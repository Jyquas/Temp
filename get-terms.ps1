# Function to recursively process terms and build a hierarchical structure
function Process-Terms {
    param (
        [Parameter(Mandatory = $true)]
        $Terms
    )

    $result = @()

    foreach ($term in $Terms) {
        $termData = @{
            Term = $term.Name
            Id = $term.Id
            LocalCustomProperties = $term.LocalCustomProperties
        }

        # If the term has child terms, process them recursively
        if ($term.Terms -and $term.Terms.Count -gt 0) {
            $termData["ChildTerms"] = Process-Terms -Terms $term.Terms
        }

        $result += $termData
    }

    return $result
}

# Variables
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$termGroupId = "your-term-group-id"
$termSetName = "your-term-set-name"
$outputFile = "terms.json"

# Connect to SPO
Connect-PnPOnline -Url $siteUrl -Interactive

# Retrieve the term set from the specified term group
$termGroup = Get-PnPTermGroup -Identity $termGroupId
$termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $termGroup

# Retrieve terms and include child terms
$terms = Get-PnPTerm -TermSet $termSet -TermGroup $termGroup -IncludeChildTerms

# Process terms and build hierarchy
$hierarchicalTerms = Process-Terms -Terms $terms

# Write to JSON
$hierarchicalTerms | ConvertTo-Json -Depth 10 | Out-File $outputFile

# Output completion message
Write-Host "Term data exported to $outputFile"
