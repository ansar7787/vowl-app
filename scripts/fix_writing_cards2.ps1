$files = Get-ChildItem -Path lib\features\writing -Recurse -Include *_screen.dart | Select-Object -ExpandProperty FullName

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Raw $file
        $lines = $content -split "`r?`n"
        $newLines = @()
        $skip = $false
        $bracketCount = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            if ($line -match "if \(.*isAnswered.*\) \.\.\.\[") {
                $lookahead = $lines[$i..([math]::Min($i+30, $lines.Count-1))] -join " "
                if ($lookahead -match "ExplanationCard") {
                    $skip = $true
                    $bracketCount = 0
                }
            }
            
            if ($skip) {
                $bracketCount += ($line.Length - $line.Replace("[","").Length)
                $bracketCount -= ($line.Length - $line.Replace("]","").Length)
                if ($bracketCount -le 0 -and $line -match "\]") {
                    $skip = $false
                }
                continue
            }
            
            $newLines += $line
        }
        
        $newLines -join "`n" | Set-Content $file -Encoding UTF8
        Write-Host "Processed $file"
    }
}
