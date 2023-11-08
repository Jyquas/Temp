# Dot-source Connect.ps1
. .\Connect.ps1

# Call Connect-ToSites to establish the connections
$sourceCtx, $targetCtx = Connect-ToSites -sourceSiteUrl "<Your-Source-SharePoint-Site-URL>" -targetSiteUrl "<Your-Target-SharePoint-Site-URL>"

function Add-ContentToModernPage {
    param (
        [Parameter(Mandatory = $true)] [string] $PageName,
        [Parameter(Mandatory = $true)] [array] $ContentBlocks,
        [Parameter(Mandatory = $true)] $Connection
    )

    # Retrieve the modern page
    $Page = Get-PnPClientSidePage -Identity $PageName -Connection $Connection

    # Iterate through each content block and add it to the page
    foreach ($ContentBlock in $ContentBlocks) {
        # Determine the section and column for the content block
        $section = $ContentBlock.Section
        $column = $ContentBlock.Column
        $content = $ContentBlock.Content

        # Add the content block to the specified section and column
        Add-PnPPageTextPart -Page $Page -Text $content -Section $section -Column $column -Connection $Connection
    }
}

# Query to get pages with a specific page layout from the source site
$pagesQuery = @"
<View>
    <Query>
        <Where>
            <Eq>
                <FieldRef Name='PageLayoutDescription' />
                <Value Type='Text'>Level 1</Value>
            </Eq>
        </Where>
    </Query>
</View>
"@
$pages = Get-PnPListItem -List "Pages" -Query $pagesQuery -Connection $sourceCtx

# Iterate through each page
foreach ($page in $pages) {
    $pageName = $page.FieldValues["FileLeafRef"]

    # Create a new modern page
    $newPage = Add-PnPClientSidePage -Name $pageName -LayoutType Article -Connection $targetCtx

    # Retrieve all versions of the page
    $allVersions = Get-PnPListItemVersion -List "Pages" -Identity $page.Id -Connection $sourceCtx

    # Filter to get only the major versions
    $majorVersions = $allVersions | Where-Object { $_.VersionLabel -match "^\d+\.\d+$" } | Sort-Object -Property VersionLabel -Descending

    # Process each major version
    foreach ($version in $majorVersions) {
        # Extract content fields from the version
        # Assumes Get-ContentFromVersion extracts the relevant content from the version
        $ContentBlocks = Get-ContentFromVersion -Version $version
        
        # Add content to the modern page
        Add-ContentToModernPage -PageName $newPage.Name -ContentBlocks $ContentBlocks -Connection $targetCtx

        # Checkout the page before making changes
        Set-PnPClientSidePage -Identity $newPage -Checkout -Connection $targetCtx

        # Check-in the page as a major version and publish
        Set-PnPClientSidePage -Identity $newPage -CheckIn -Publish -CommentsEnabled $false -Connection $targetCtx
    }
}

# Disconnect from the SharePoint sites
Disconnect-PnPOnline -Connection $sourceCtx
Disconnect-PnPOnline -Connection $targetCtx
