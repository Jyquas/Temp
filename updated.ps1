# Define your source and target SharePoint site URLs
$sourceSiteUrl = "<Your-Source-SharePoint-Site-URL>"
$targetSiteUrl = "<Your-Target-SharePoint-Site-URL>"

# Prompt for credentials
$cred = Get-Credential

# Connect to the source and target SharePoint sites
$sourceCtx = Connect-PnPOnline -Url $sourceSiteUrl -Credentials $cred -ReturnConnection
$targetCtx = Connect-PnPOnline -Url $targetSiteUrl -Credentials $cred -ReturnConnection

# Function to retrieve the last 5 versions of a classic page
function Get-Last5Versions($pageUrl) {
    $pageItem = Get-PnPListItem -List "Pages" -Query "<View><Query><Where><Eq><FieldRef Name='FileRef'/><Value Type='Url'>$pageUrl</Value></Eq></Where></Query></View>" -Connection $sourceCtx
    $versions = $pageItem.Versions | Select-Object -Last 5
    return $versions
}

# Function to create a new modern page based on content type and layout
function New-ModernPage($pageTitle, $contentType, $pageLayout) {
    $page = Add-PnPClientSidePage -Name $pageTitle -LayoutType $pageLayout -Connection $targetCtx
    Set-PnPListItem -List "SitePages" -Identity $page.Id -ContentType $contentType -Connection $targetCtx
    return $page
}

# Function to add content to a specific section and column on a modern page
function Add-ContentToModernPage($page, $content1, $content2) {
    Add-PnPPageTextPart -Page $page -Section 1 -Column 1 -Text $content1 -Connection $targetCtx
    Add-PnPPageTextPart -Page $page -Section 1 -Column 2 -Text $content2 -Connection $targetCtx
    $page.Save($targetCtx)
}

# Example Usage
$pageUrl = "sites/classicsite/pages/samplepage.aspx"
$pageTitle = "NewModernPage"
$contentType = "Article"
$pageLayout = "Article"

$oldPageVersions = Get-Last5Versions -pageUrl $pageUrl

# Create a new modern page
$newPage = New-ModernPage -pageTitle $pageTitle -contentType $contentType -pageLayout $pageLayout

# Loop through the last 5 versions of the classic page
foreach ($version in $oldPageVersions) {
    # Assume you have logic to extract content from old versions
    # For the sake of this example, we're just using placeholders
    $content1 = "Content for the first column"
    $content2 = "Content for the second column"

    # Add content to the modern page and publish it to create a new major version
    try {
        Add-ContentToModernPage -page $newPage -content1 $content1 -content2 $content2
        Set-PnPClientSidePage -Identity $newPage -CommentsEnabled $false -Publish -Connection $targetCtx
    } catch {
        Write-Host "Error: $($_.Exception.Message)"
    }
}

# Disconnect from the SharePoint sites
Disconnect-PnPOnline -Connection $sourceCtx
Disconnect-PnPOnline -Connection $targetCtx
