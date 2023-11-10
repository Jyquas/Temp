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
# Retrieve all files from the Master Page Gallery
$allFiles = Get-PnPListItem -List "Master Page Gallery" -Fields "ContentTypeId", "FileRef", "FileLeafRef"

# Filter files based on ContentType ID
$filteredFiles = $allFiles | Where-Object { $intranetContentTypeIds -contains $_["ContentTypeId"].StringValue }

# Process each filtered file
foreach ($file in $filteredFiles) {
    $fileUrl = $file.FieldValues.FileRef

    # Generate a temporary file path with .xml extension
    $tempFileBasePath = [System.IO.Path]::GetTempPath()
    $tempFileName = [System.IO.Path]::GetRandomFileName()
    $tempFilePath = "$tempFileBasePath$tempFileName.xml"

    # Download the file to the temporary path
    Get-PnPFile -Url $fileUrl -AsFile -Path $tempFilePath -Force

    # Load and modify the XML content
    [xml]$xmlContent = Get-Content $tempFilePath
    # Your XML modification logic goes here
    # For example: $xmlContent.DocumentElement.RemoveChild($xmlContent.DocumentElement.":DelegateControl")

    # Save the modified content back to the temporary file
    $xmlContent.Save($tempFilePath)

    # Upload the modified file back to SharePoint
    Set-PnPFile -Path $tempFilePath -Url $fileUrl -OverwriteIfExist
}

    # Disconnect the session
Disconnect-PnPOnline
