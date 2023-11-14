# Load SharePoint CSOM assemblies
Add-Type -Path "path\to\Microsoft.SharePoint.Client.dll"
Add-Type -Path "path\to\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "path\to\Microsoft.SharePoint.Client.Taxonomy.dll"

# SharePoint site details
$siteUrl = "http://yoursharepointserver/sites/yoursite"
$username = "domain\username"
$password = ConvertTo-SecureString "your-password" -AsPlainText -Force
$credentials = New-Object System.Net.NetworkCredential($username, $password)

# Create context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
$ctx.Credentials = $credentials

# Access taxonomy session and term store
$taxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($ctx)
$termStore = $taxonomySession.GetDefaultSiteCollectionTermStore()
$ctx.Load($termStore)
$ctx.ExecuteQuery()

# Term group and term set ID
$termGroupIdString = "your-term-group-id" # Replace with your actual term group ID
$termSetIdString = "your-term-set-id" # Replace with your actual term set ID
$termGroupId = New-Object Guid($termGroupIdString)
$termSetId = New-Object Guid($termSetIdString)

# Load the term group
$termGroup = $termStore.GetGroup($termGroupId)
$ctx.Load($termGroup)
$ctx.ExecuteQuery()

# Load the term group's term sets and retrieve the specific term set
$ctx.Load($termGroup.TermSets)
$ctx.ExecuteQuery()
$termSet = $termGroup.TermSets | Where-Object { $_.Id -eq $termSetId }

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

        # Retrieve the navigation term to get the friendly URL
        $navTerm = [Microsoft.SharePoint.Client.Taxonomy.NavigationTerm]::GetNavigationTerm($term)
        $ctx.Load($navTerm)
        $ctx.ExecuteQuery()

        $termData = @{
            TermId = $term.Id
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
