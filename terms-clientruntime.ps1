# Load SharePoint CSOM assemblies
Add-Type -Path "path\to\Microsoft.SharePoint.Client.dll"
Add-Type -Path "path\to\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "path\to\Microsoft.SharePoint.Client.Taxonomy.dll"

# SharePoint site details
$siteUrl = "http://yoursharepointserver/sites/yoursite"

# Create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)

# Access taxonomy session, term store, term group, and term set
$taxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($ctx)
$termStore = $taxonomySession.GetDefaultSiteCollectionTermStore()
$termGroup = $termStore.GetGroup("your-term-group-id")
$termSet = $termGroup.GetTermSet("your-term-set-id")
$ctx.Load($termSet)
$ctx.ExecuteQuery()

# Function to process terms
function Process-Terms {
    param (
        [Parameter(Mandatory = $true)]
        $Terms
    )

    $result = @()

    foreach ($term in $Terms) {
        $ctx.Load($term)
        $ctx.ExecuteQuery()

        # Assuming target URL is stored in a local custom property
        $targetUrl = $term.LocalCustomProperties["TargetUrl"]

        # Retrieve the navigation term to get the friendly URL
        $navTerm = [Microsoft.SharePoint.Client.Taxonomy.NavigationTerm]::GetNavigationTerm($term)
        $ctx.Load($navTerm)
        $ctx.ExecuteQuery()

        $termData = @{
            TermId = $term.Id
            TargetUrl = $targetUrl
            FriendlyUrl = $navTerm.GetResolvedDisplayUrl($null)
        }
        $result += $termData

        if ($term.Terms) {
            $childResults = Process-Terms -Terms $term.Terms
            $result += $childResults
        }
    }

    return $result
}

# Retrieve and process terms
$terms = $termSet.GetAllTerms()
$ctx.Load($terms)
$ctx.ExecuteQuery()

$termMapping = Process-Terms -Terms $terms

# Export to JSON
$termMapping | ConvertTo-Json -Depth 100 | Out-File "term-mapping.json"

# Output completion message
Write-Host "Term mapping exported to term-mapping.json"
