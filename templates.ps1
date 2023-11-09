# Connect to SharePoint Online
$siteUrl = "your_site_url"
$cred = Get-Credential
Connect-PnPOnline -Url $siteUrl -Credentials $cred

# Retrieve files from the Master Page Gallery
$files = Get-PnPListItem -List "Master Page Gallery" | Where-Object { $_["ContentType"] -like "*intranet*" }
# Connect to SharePoint Online
$siteUrl = "your_site_url"
$cred = Get-Credential
Connect-PnPOnline -Url $siteUrl -Credentials $cred

# Get the ID of the 'intranet' content type
$contentTypes = Get-PnPContentType
$intranetContentTypeId = $contentTypes | Where-Object { $_.Name -like "*intranet*" } | Select-Object -ExpandProperty Id

# Check if the 'intranet' content type exists
if ($intranetContentTypeId) {
    # Construct the CAML query
    $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
    $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='ContentTypeId'/><Value Type='ContentTypeId'>$intranetContentTypeId</Value></Eq></Where></Query></View>"

    # Retrieve files from the Master Page Gallery
    $files = Get-PnPListItem -List "Master Page Gallery" -Query $camlQuery -Fields "FileRef", "FileLeafRef"

    # Process each file
    
# Process each file
foreach ($file in $files) {
    $fileUrl = $file["FileRef"]
    
    # Download the file
    $tempFile = [System.IO.Path]::GetTempFileName()
    Get-PnPFile -Url $fileUrl -AsFile -Path $tempFile -Force

    # Load and modify the XML content
    [xml]$xmlContent = Get-Content $tempFile
    $xmlContent.DocumentElement.RemoveChild($xmlContent.DocumentElement.":DelegateControl")
    
    # Save the modified content
    $xmlContent.Save($tempFile)

    # Upload the modified file
    Set-PnPFile -Path $tempFile -Url $fileUrl -OverwriteIfExist
}

# Disconnect the session
Disconnect-PnPOnline
