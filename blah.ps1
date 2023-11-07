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

    # Save and publish the page
    $Page.Save($Connection)
    $Page.Publish($Connection)
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

# Assuming $itemId is the ID of the item and $listTitle is the title of the list
$listTitle = "Pages"
$itemId = 1 # Replace with your actual list item ID

# Retrieve all versions of the specified list item
$versions = Get-PnPListItemVersion -List $listTitle -Identity $itemId

# Iterate through the versions and perform actions
foreach ($version in $versions) {
    # Access the desired field values using their internal names
    $content1 = $version.FieldValues["ContentField1"]
    # Additional processing...
}

# Retrieve all major versions (assuming major versions end with .0)
$majorVersions = $allVersions | Where-Object { $_.VersionLabel -match "^\d+\.\d+$" } | Sort-Object -Property VersionLabel -Descending

# Select the first 5 major versions, which are the most recent ones due to sorting
$firstFiveMajorVersions = $majorVersions | Select-Object -First 5

# Reverse the order to have the oldest of the five as the first one
$reversedFiveMajorVersions = [array]::Reverse($firstFiveMajorVersions)


    # Get the last 5 versions of the page
    $versions = $page.Versions | Select-Object -Last 5

    # Outside the loop, create a new modern page
    $newPage = Add-PnPClientSidePage -Name "$($page.Title).aspx" -LayoutType Article -Connection $targetCtx
    Add-PnPPageSection -Page $newPage -SectionTemplate TwoColumn -Connection $targetCtx

    # Define the content blocks for each version of the page
    $ContentBlocks = @()

    # Loop through the versions of the classic page
    for ($i = 0; $i -lt $versions.Count; $i++) {
        $version = $versions[$i]

        # Extract the content from the classic page version
        # Assume Get-ContentFromVersion is a function that extracts the content from a version of the classic page
        $ContentBlocks += @(
            @{ Section = 1; Column = 1; Content = Get-ContentFromVersion -Version $version -Field "ContentField1" },
            @{ Section = 2; Column = 1; Content = Get-ContentFromVersion -Version $version -Field "ContentField2" },
            @{ Section = 2; Column = 2; Content = Get-ContentFromVersion -Version $version -Field "ContentField3" }
        )
        
        # Add content to the modern page
        Add-ContentToModernPage -PageName "$($newPage.Name)" -ContentBlocks $ContentBlocks -Connection $targetCtx

        # If this is not the last version, check in the page to create a new version
        if ($i -lt $versions.Count - 1) {
            Set-PnPClientSidePage -Identity $newPage -CommentsEnabled $false -Publish -Connection $targetCtx
        }
    }

    # After the loop, publish the final version of the modern page
    Set-PnPClientSidePage -Identity $newPage -CommentsEnabled $false -Publish -Connection $targetCtx
}

# Disconnect from the SharePoint sites
Disconnect-PnPOnline -Connection $sourceCtx
Disconnect-PnPOnline -Connection $targetCtx
