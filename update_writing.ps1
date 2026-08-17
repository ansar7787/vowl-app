Get-ChildItem -Path "lib\features\writing" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName
    $modified = $false
    
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($content[$i] -match "lastAnswerCorrect") {
            $content[$i] = $content[$i] -replace 'curr\.lastAnswerCorrect == null', '!curr.answerStatus.isAnswered'
            $content[$i] = $content[$i] -replace 'state\.lastAnswerCorrect == null', '!state.answerStatus.isAnswered'
            $content[$i] = $content[$i] -replace 'prev\.lastAnswerCorrect != curr\.lastAnswerCorrect', 'prev.answerStatus != curr.answerStatus'
            $content[$i] = $content[$i] -replace 'state\.lastAnswerCorrect != null', 'state.answerStatus.isAnswered'
            $content[$i] = $content[$i] -replace 'isLoaded \? state\.lastAnswerCorrect : null', 'isLoaded ? state.answerStatus.asBoolOrNull : null'
            $content[$i] = $content[$i] -replace 'state\.lastAnswerCorrect == true', 'state.answerStatus == AnswerStatus.correct'
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $_.FullName -Value $content
        Write-Host "Modified $($_.FullName)"
    }
}
