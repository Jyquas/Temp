# Dot-source Connect.ps1
. .\Connect.ps1

# Call Connect-ToSites to establish the connections
$sourceCtx, $targetCtx = Connect-ToSites -sourceSiteUrl "<Your-Source-SharePoint-Site-URL>" -targetSiteUrl "<Your-Target-SharePoint-Site-URL>"


function Add-ContentToModernPage {
    param (
        [Parameter(Mandatory = $true)] [string] $PageName,
        [Parameter(Mandatory = $true)] [string] $Content1,
        [Parameter(Mandatory = $true)] [string] $Content2,
        [Parameter(Mandatory = $true)] $Connection
    )

    # Retrieve the modern page
    $Page = Get-PnPClientSidePage -Identity $PageName -Connection $Connection

    # Add the text content to the modern page in the first section, first column
    Add-PnPPageTextPart -Page $Page -Text $Content1 -Section 1 -Column 1 -Connection $Connection

    # Add the text content to the modern page in the first section, second column
    Add-PnPPageTextPart -Page $Page -Text $Content2 -Section 1 -Column 2 -Connection $Connection

    # Save and publish the page
    $Page.Save()
    $Page.Publish()
}



# Query to get pages with a specific page layout from the source site
$pagesQuery = @"
<View>
    <Joins>
        <Join Type='INNER' ListAlias='MasterPageGallery'>
            <Eq>
                <FieldRef Name='PublishingPageLayout' RefType='Id' />
                <FieldRef List='MasterPageGallery' Name='ID'/>
            </Eq>
        </Join>
    </Joins>
    <ProjectedFields>
        <Field Name='PageLayoutDescription' Type='Lookup' List='MasterPageGallery' ShowField='Description'/>
    </ProjectedFields>
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
    # Get the last 5 versions of the page
    $versions = $page.Versions | Select-Object -Last 5

    # Outside the loop, create a new modern page
$newPage = Add-PnPClientSidePage -Name "$($page.Title).aspx" -LayoutType Article -Connection $targetCtx
Add-PnPPageSection -Page $newPage -SectionTemplate TwoColumn -Connection $targetCtx

# Loop through the versions of the classic page
for ($i = 0; $i -lt $versions.Count; $i++) {
    $version = $versions[$i]

    # Update the content of the modern page based on the content of the classic page version
    # Assume Get-ContentFromVersion is a function that extracts the content from a version of the classic page
    $content1 = Get-ContentFromVersion -Version $version -Field "ContentField1"
    $content2 = Get-ContentFromVersion -Version $version -Field "ContentField2"
    Add-ContentToModernPage -Page $newPage -Content1 $content1 -Content2 $content2 -Connection $targetCtx

    # If this is not the last version, check in the page to create a new version
    if ($i -lt $versions.Count - 1) {
        Set-PnPClientSidePage -Identity $newPage -CommentsEnabled $false -Publish -Connection $targetCtx
    }
}

# After the loop, publish the final version of the modern page
Set-PnPClientSidePage -Identity $newPage -CommentsEnabled $false -Publish -Connection $targetCtx


# Disconnect from the SharePoint sites
Disconnect-PnPOnline -Connection $sourceCtx
Disconnect-PnPOnline -Connection $targetCtx
