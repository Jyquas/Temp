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

    # Generate a temporary file path with .aspx extension
    $tempFileBasePath = [System.IO.Path]::GetTempPath()
    $tempFileName = [System.IO.Path]::GetRandomFileName()
    $tempFilePath = "$tempFileBasePath$tempFileName.aspx"

    # Download the file to the temporary path
    Get-PnPFile -Url $fileUrl -AsFile -Path $tempFilePath -Force

    # Load the ASPX content
    $aspxContent = Get-Content $tempFilePath -Raw

    # Modify the ASPX content to remove the specific HTML node
    # This is a basic example and might need to be adjusted for your specific scenario
    $pattern = '<SharePointWebControls:DelegateControl[^>]*>.*?</SharePointWebControls:DelegateControl>'
    $aspxContent = [regex]::Replace($aspxContent, $pattern, '', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # Save the modified content back to the temporary file
    Set-Content -Path $tempFilePath -Value $aspxContent

    # Upload the modified file back to SharePoint
    Set-PnPFile -Path $tempFilePath -Url $fileUrl -OverwriteIfExist
}


    # Disconnect the session
Disconnect-PnPOnline
