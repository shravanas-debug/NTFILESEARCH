Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ----------------------- Relaunch as Admin -----------------------
function Relaunch-AsAdmin {
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
$runButton.Size = New-Object System.Drawing.Size(120,30)
$runButton.Location = New-Object System.Drawing.Point(20,480)
$form.Controls.Add($runButton)

# Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Size = New-Object System.Drawing.Size(120,30)
$browseButton.Location = New-Object System.Drawing.Point(160,480)
$form.Controls.Add($browseButton)

# Easy mode button
$easyButton = New-Object System.Windows.Forms.Button
$easyButton.Text = "Easy Mode Search"
$easyButton.Size = New-Object System.Drawing.Size(180,30)
$easyButton.Location = New-Object System.Drawing.Point(300,480)
$form.Controls.Add($easyButton)

# Hypergod button
$hyperButton = New-Object System.Windows.Forms.Button
$hyperButton.Text = "HyperGod Scan"
$hyperButton.Size = New-Object System.Drawing.Size(180,30)
$hyperButton.Location = New-Object System.Drawing.Point(500,480)
$form.Controls.Add($hyperButton)

# Settings button
$settingsButton = New-Object System.Windows.Forms.Button
$settingsButton.Text = "Settings"
$settingsButton.Size = New-Object System.Drawing.Size(120,30)
$settingsButton.Location = New-Object System.Drawing.Point(700,480)
$form.Controls.Add($settingsButton)

# ----------------------- SETTINGS FORM -----------------------
$settingsForm = New-Object System.Windows.Forms.Form
$settingsForm.Text = "Settings"
$settingsForm.Size = New-Object System.Drawing.Size(400,200)
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

$backButton = New-Object System.Windows.Forms.Button
$backButton.Text = "Back"
$backButton.Location = New-Object System.Drawing.Point(20,120)
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
        $files = Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue -Include *.exe | Where-Object { $_.Name -like $pattern }
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
    if ($hyperCheck.Checked) {
        # Slow mode (lag, unresponsive, notification)
        $files = Get-ChildItem -Path C:\ -Filter *.exe -Recurse -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            $item.SubItems.Add($f.FullName)
            $listView.Items.Add($item) | Out-Null
        }
        [System.Windows.Forms.MessageBox]::Show("HyperGod scan finished.","NTSELECTFILE")
    } else {
        # Fast mode
        $files = Get-ChildItem -Path C:\ -Filter *.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 500
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
