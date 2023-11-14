function Find-TermById {
    param (
        [Parameter(Mandatory = $true)]
        $Terms,
        [Parameter(Mandatory = $true)]
        $TermId
    )

    foreach ($term in $Terms) {
        if ($term.Id -eq $TermId) {
            return $term
        }

        if ($term.ChildTerms) {
            $foundTerm = Find-TermById -Terms $term.ChildTerms -TermId $TermId
            if ($foundTerm) {
                return $foundTerm
            }
        }
    }

    return $null
}

# Variables
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$classicPageUrl = "path/to/classic/page"
$modernPageName = "ModernPageName.aspx"
$staticWebId = "your-static-webid" # Replace with actual WebID
$staticTermSetId = "your-static-termsetid" # Replace with actual TermSetID

# Connect to the SharePoint site
Connect-PnPOnline -Url $siteUrl -Interactive

# Retrieve content from the classic page (assuming it's stored in a field like 'PublishingPageContent')
$classicPageContent = Get-PnPListItem -List "Pages" -Query "<View><Query><Where><Eq><FieldRef Name='FileRef'/><Value Type='Url'>$classicPageUrl</Value></Eq></Where></Query></View>"

# Process the content to replace URLs
$pattern = "fixupredirect\.aspx\?WebID=$staticWebId&termSetID=$staticTermSetId&termId=([\w-]+)"
foreach ($item in $classicPageContent) {
    $content = $item["PublishingPageContent"]

    if ($content -match $pattern) {
        $termId = $matches[1]
        $foundTerm = Find-TermById -Terms $termMappings -TermId $termId

        if ($foundTerm) {
            $newUrl = $foundTerm.FriendlyUrlSegment
            $content = $content -replace $pattern, $newUrl
        }
    }

    # Create a new client-side page and add the processed content
    $page = Set-PnPClientSidePage -Name $modernPageName -LayoutType Article -CommentsEnabled:$false
    Add-PnPClientSideText -Page $page -Section 1 -Column 1 -Text $content
}

# Output completion message
Write-Host "Content migrated to modern page: $modernPageName"

