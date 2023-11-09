# Connect to SharePoint Online
$siteUrl = "your_site_url"
$cred = Get-Credential
Connect-PnPOnline -Url $siteUrl -Credentials $cred

# Retrieve files from the Master Page Gallery
$files = Get-PnPListItem -List "Master Page Gallery" | Where-Object { $_["ContentType"] -like "*intranet*" }

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
