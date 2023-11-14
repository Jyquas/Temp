function Process-Terms {
    param (
        [Parameter(Mandatory = $true)]
        $Terms,
        [string]$ParentFriendlyUrlSegment = '' # Parameter for parent's friendly URL segment
    )

    $result = @()

    foreach ($term in $Terms) {
        # Get the current term's friendly URL segment, if available
        $currentFriendlyUrlSegment = $term.LocalCustomProperties["FriendlyUrlSegment"]

        # Build the full friendly URL segment for the current term
        $fullFriendlyUrlSegment = $ParentFriendlyUrlSegment
        if ($currentFriendlyUrlSegment) {
            $fullFriendlyUrlSegment += '/' + $currentFriendlyUrlSegment
        }

        $termData = @{
            Term = $term.Name
            Id = $term.Id
            LocalCustomProperties = $term.LocalCustomProperties
            FriendlyUrlSegment = $fullFriendlyUrlSegment.TrimStart('/')
        }

        # Process child terms recursively, if any
        if ($term.Terms -and $term.Terms.Count -gt 0) {
            $termData["ChildTerms"] = Process-Terms -Terms $term.Terms -ParentFriendlyUrlSegment $fullFriendlyUrlSegment
        }

        $result += $termData
    }

    return $result
}


function ProcessTerms {
    param (
        [Parameter(Mandatory = $true)]
        $Terms,
        [string]$ParentPath = '' # Add a parameter for the parent path
    )

    $result = @()

    foreach ($term in $Terms) {
        # Build the term path
        $termPath = $ParentPath + '/' + $term.Name

        $termData = @{
            Term = $term.Name
            Id = $term.Id
            LocalCustomProperties = $term.LocalCustomProperties
            Path = $termPath.TrimStart('/') # Remove leading slash for root terms
        }

        # If the term has child terms, process them recursively
        if ($term.Terms -and $term.Terms.Count -gt 0) {
            $termData["ChildTerms"] = Process-Terms -Terms $term.Terms -ParentPath $termPath
        }

        $result += $termData
    }

    return $result
}

function ProcessFullPathTerms {
    param (
        [Parameter(Mandatory = $true)]
        $Terms,
        [string]$ParentPath = '' # Parameter for the path constructed up to the parent
    )

    $result = @()

    foreach ($term in $Terms) {
        # Determine the current term's segment (either a custom friendly URL segment or the term name)
        $currentSegment = $term.LocalCustomProperties["FriendlyUrlSegment"]
        if (-not $currentSegment) {
            $currentSegment = $term.Name
        }

        # Build the full path for the current term
        $fullPath = $ParentPath
        if ($fullPath -and $currentSegment) {
            $fullPath += '/'
        }
        $fullPath += $currentSegment

        $termData = @{
            Term = $term.Name
            Id = $term.Id
            LocalCustomProperties = $term.LocalCustomProperties
            Path = $fullPath
        }

        # Process child terms recursively, if any
        if ($term.Terms -and $term.Terms.Count -gt 0) {
            $termData["ChildTerms"] = ProcessFullPathTerms -Terms $term.Terms -ParentPath $fullPath
        }

        $result += $termData
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
