Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------------- CMD INFO / README -----------------------
$cmdInfo = @"
NTSELECTFILE - v2.0
-----------------------------
Buttons:
- Run Program: Launch selected file
- Browse: Manually select file
- Easy Mode Search: Search common folders (Program Files, System32)
- HyperGod Scan: Full system scan; Slow mode can lag
- Settings: Enable/disable Slow HyperGod, File Type Filter, Run as Admin
- God Mode Folder: Optional bonus (created from HyperGod / Settings)
Settings defaults: All off
ListView: Shows first 50 items to prevent lag
File Type Filter: Optional, off by default, can be enabled in Settings
"@

Write-Host $cmdInfo -ForegroundColor Cyan

# ----------------------- Relaunch as Admin -----------------------
function Relaunch-AsAdmin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        $scriptPath = $MyInvocation.MyCommand.Path
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = (Get-Command pwsh -ErrorAction SilentlyContinue).Path
        if (-not $psi.FileName) { $psi.FileName = (Get-Command powershell).Path }
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $psi.Verb = "runas"
        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            exit
        } catch {
            [System.Windows.Forms.MessageBox]::Show("User canceled UAC.","NTSELECTFILE")
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Already running as Administrator.","NTSELECTFILE")
    }
}

# ----------------------- MAIN FORM -----------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "NTSELECTFILE"
$form.Size = New-Object System.Drawing.Size(900,600)
$form.StartPosition = "CenterScreen"
$form.BackColor = "Black"
$form.ForeColor = "White"
$form.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Regular)

# Search box
$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Size = New-Object System.Drawing.Size(400,30)
$searchBox.Location = New-Object System.Drawing.Point(20,20)
$form.Controls.Add($searchBox)

# Results view
$listView = New-Object System.Windows.Forms.ListView
$listView.View = 'Details'
$listView.FullRowSelect = $true
$listView.Size = New-Object System.Drawing.Size(840,400)
$listView.Location = New-Object System.Drawing.Point(20,60)
$listView.Columns.Add("Name",300)
$listView.Columns.Add("Path",500)
$form.Controls.Add($listView)

# Run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Program"
$runButton.Size = New-Object System.Drawing.Size(160,30)
$runButton.Location = New-Object System.Drawing.Point(20,480)
$form.Controls.Add($runButton)

# Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Size = New-Object System.Drawing.Size(160,30)
$browseButton.Location = New-Object System.Drawing.Point(200,480)
$form.Controls.Add($browseButton)

# Easy mode button
$easyButton = New-Object System.Windows.Forms.Button
$easyButton.Text = "Easy Mode Search"
$easyButton.Size = New-Object System.Drawing.Size(200,30)
$easyButton.Location = New-Object System.Drawing.Point(380,480)
$form.Controls.Add($easyButton)

# Hypergod button
$hyperButton = New-Object System.Windows.Forms.Button
$hyperButton.Text = "HyperGod Scan"
$hyperButton.Size = New-Object System.Drawing.Size(200,30)
$hyperButton.Location = New-Object System.Drawing.Point(580,480)
$form.Controls.Add($hyperButton)

# Settings button
$settingsButton = New-Object System.Windows.Forms.Button
$settingsButton.Text = "Settings"
$settingsButton.Size = New-Object System.Drawing.Size(160,30)
$settingsButton.Location = New-Object System.Drawing.Point(780,480)
$form.Controls.Add($settingsButton)

# ----------------------- SETTINGS FORM -----------------------
$settingsForm = New-Object System.Windows.Forms.Form
$settingsForm.Text = "Settings"
$settingsForm.Size = New-Object System.Drawing.Size(400,250)
$settingsForm.StartPosition = "CenterScreen"
$settingsForm.BackColor = "Black"
$settingsForm.ForeColor = "White"
$settingsForm.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Regular)

$adminCheck = New-Object System.Windows.Forms.CheckBox
$adminCheck.Text = "Run as Administrator"
$adminCheck.Location = New-Object System.Drawing.Point(20,30)
$settingsForm.Controls.Add($adminCheck)

$hyperCheck = New-Object System.Windows.Forms.CheckBox
$hyperCheck.Text = "Enable Slow HyperGod Mode"
$hyperCheck.Location = New-Object System.Drawing.Point(20,70)
$settingsForm.Controls.Add($hyperCheck)

$fileTypeCheck = New-Object System.Windows.Forms.CheckBox
$fileTypeCheck.Text = "Enable File Type Filter in Search"
$fileTypeCheck.Location = New-Object System.Drawing.Point(20,110)
$settingsForm.Controls.Add($fileTypeCheck)

$backButton = New-Object System.Windows.Forms.Button
$backButton.Text = "Back"
$backButton.Size = New-Object System.Drawing.Size(160,30)
$backButton.Location = New-Object System.Drawing.Point(20,160)
$settingsForm.Controls.Add($backButton)

# ----------------------- SWITCH LOGIC -----------------------
$settingsButton.Add_Click({
    $form.Hide()
    $settingsForm.ShowDialog() | Out-Null
    $form.Show()
})

$backButton.Add_Click({
    if ($adminCheck.Checked) {
        Relaunch-AsAdmin
    }
    $settingsForm.Close()
})

# ----------------------- SEARCH FUNCTION -----------------------
$searchBox.Add_TextChanged({
    $listView.Items.Clear()
    if ($searchBox.Text.Length -gt 0) {
        $pattern = "*$($searchBox.Text)*"
        $files = Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue
        
        if ($fileTypeCheck.Checked) {
            $fileType = Read-Host "Enter file extension (e.g., exe, txt)"
            if ($fileType) { $files = $files | Where-Object { $_.Name -like $pattern -and $_.Extension -eq ".$fileType" } }
            else { $files = $files | Where-Object { $_.Name -like $pattern } }
        } else {
            $files = $files | Where-Object { $_.Name -like $pattern }
        }

        $files = $files | Select-Object -First 50   # limit to 50 results
        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            $item.SubItems.Add($f.FullName)
            $listView.Items.Add($item) | Out-Null
        }
    }
})

# ----------------------- EASY MODE -----------------------
$easyButton.Add_Click({
    $listView.Items.Clear()
    $commonDirs = @("C:\Program Files","C:\Program Files (x86)","C:\Windows\System32")
    foreach ($dir in $commonDirs) {
        $files = Get-ChildItem -Path $dir -Filter *.exe -Recurse -ErrorAction SilentlyContinue
        $files = $files | Select-Object -First 50
        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            $item.SubItems.Add($f.FullName)
            $listView.Items.Add($item) | Out-Null
        }
    }
})

# ----------------------- HYPERGOD -----------------------
$hyperButton.Add_Click({
    $listView.Items.Clear()
    $files = Get-ChildItem -Path C:\ -Filter *.exe -Recurse -ErrorAction SilentlyContinue
    if ($hyperCheck.Checked) {
        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            $item.SubItems.Add($f.FullName)
            $listView.Items.Add($item) | Out-Null
        }
        [System.Windows.Forms.MessageBox]::Show("HyperGod scan finished (Slow mode).","NTSELECTFILE")
    } else {
        $files = $files | Select-Object -First 50
        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            $item.SubItems.Add($f.FullName)
            $listView.Items.Add($item) | Out-Null
        }
    }
})

# ----------------------- BROWSE -----------------------
$browseButton.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "Executables (*.exe)|*.exe|All files (*.*)|*.*"
    if ($ofd.ShowDialog() -eq "OK") {
        $item = New-Object System.Windows.Forms.ListViewItem((Split-Path $ofd.FileName -Leaf))
        $item.SubItems.Add($ofd.FileName)
        $listView.Items.Clear()
        $listView.Items.Add($item) | Out-Null
    }
})

# ----------------------- RUN -----------------------
$runButton.Add_Click({
    if ($listView.SelectedItems.Count -gt 0) {
        $path = $listView.SelectedItems[0].SubItems[1].Text
        try {
            Start-Process $path
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to run: $path","NTSELECTFILE")
        }
    }
})

# ----------------------- START -----------------------
[void]$form.ShowDialog()
