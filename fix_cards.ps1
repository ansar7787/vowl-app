$files = @(
    "lib\features\accent\speed_variance\presentation\pages\speed_variance_screen.dart",
    "lib\features\accent\word_linking\presentation\pages\word_linking_screen.dart",
    "lib\features\accent\vowel_distinction\presentation\pages\vowel_distinction_screen.dart",
    "lib\features\accent\syllable_stress\presentation\pages\syllable_stress_screen.dart",
    "lib\features\accent\pitch_pattern_match\presentation\pages\pitch_pattern_match_screen.dart",
    "lib\features\accent\shadowing_challenge\presentation\pages\shadowing_challenge_screen.dart",
    "lib\features\accent\consonant_clarity\presentation\pages\consonant_clarity_screen.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Raw $file
        
        # 1. Remove the import for *_explanation_card.dart
        $content = $content -replace "(?m)^import 'package:vowl/features/accent/.*?_explanation_card\.dart';\r?\n?", ""

        # 2. Remove the showExplanation variable
        $content = $content -replace "(?m)^\s*final bool showExplanation = .*?;\r?\n?", ""
        
        # 3. Simplify the height calculation
        $content = $content -replace "\(\s*showExplanation\s*\?\s*\d+\.h\s*:\s*0\s*\)", "0"
        $content = $content -replace "\(\s*_isAnswered\s*\?\s*\d+\.h\s*:\s*0\s*\)", "0"
        $content = $content -replace "\(\s*_isAnswered\s*\?\s*\(isCompact\s*\?\s*\d+\.h\s*:\s*\d+\.h\)\s*:\s*0\s*\)", "0"

        $lines = $content -split "`n"
        $newLines = @()
        $skip = $false
        $bracketCount = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            if ($line -match "if \(_isAnswered.*\) \.\.\.\[") {
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
