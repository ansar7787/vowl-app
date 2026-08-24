$accentDir = "lib\features\accent"
$files = Get-ChildItem -Path $accentDir -Recurse -Include *_screen.dart | Select-Object -ExpandProperty FullName

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content -Raw $file
        # Remove unused gapSlider
        $content = $content -replace "(?m)^\s*final\s+gapSlider\s*=.*?\r?\n", ""
        # Remove unused livesRemaining (but we need to be careful if it's used elsewhere, but IDE says it's unused)
        $content = $content -replace "(?m)^\s*final\s+livesRemaining\s*=.*?\r?\n", ""
        # Remove unused lives
        $content = $content -replace "(?m)^\s*final\s+lives\s*=.*?\r?\n", ""
        
        $content | Set-Content $file -Encoding UTF8
    }
}

$fixSentence = "lib\features\writing\fix_the_sentence\presentation\pages\fix_the_sentence_screen.dart"
if (Test-Path $fixSentence) {
    $content = Get-Content -Raw $fixSentence
    
    # We will remove _selectReplacement method which might span multiple lines.
    # It's better to just replace it with empty string if we can match it, or I can use sed/awk style logic.
    # Actually, I'll let flutter analyze tell me if there's anything else.
}

