# Dot-source Connect.ps1
. .\Connect.ps1

# Call Connect-ToSites to establish the connections
$sourceCtx, $targetCtx = Connect-ToSites -sourceSiteUrl "<Your-Source-SharePoint-Site-URL>" -targetSiteUrl "<Your-Target-SharePoint-Site-URL>"


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
    
    # Iterate through each version, starting with the oldest
    for ($i = 0; $i -lt $versions.Count; $i++) {
        $version = $versions[$i]
        
        # If it's the oldest version, create a new page in the target site
        if ($i -eq 0) {
            $newPage = Add-PnPClientSidePage -Name "$($page.Title)-v$($version.VersionLabel).aspx" -LayoutType Article -Connection $targetCtx
            Add-PnPPageSection -Page $newPage -SectionTemplate TwoColumn -Connection $targetCtx
        }
        else {
            # Otherwise, get the existing page from the target site
            $newPage = Get-PnPClientSidePage -Identity "$($page.Title)-v$($version.VersionLabel).aspx" -Connection $targetCtx
        }
        
        # Update the content of the page based on the version
        # Assuming Get-ContentFromVersion is a function to extract content from a version
        $content1 = Get-ContentFromVersion -Version $version -Column 1
        $content2 = Get-ContentFromVersion -Version $version -Column 2
        
        Add-PnPPageTextPart -Page $newPage -Section 1 -Column 1 -Text $content1 -Connection $targetCtx
        Add-PnPPageTextPart -Page $newPage -Section 1 -Column 2 -Text $content2 -Connection $targetCtx
        
        # Save and publish the page in the target site
        $newPage.Save($targetCtx)
        $newPage.Publish($targetCtx)
    }
}

# Disconnect from the SharePoint sites
Disconnect-PnPOnline -Connection $sourceCtx
Disconnect-PnPOnline -Connection $targetCtx
