$path = 'lib/core/presentation/widgets/game_dialog_helper.dart'
$content = Get-Content $path -Raw

$targetGameOver = @"
        return ModernGameDialog(
          title: resolvedTitle,
          description: resolvedDescription,
          buttonText: resolvedButtonText,
          isSuccess: false,
          isRescueLife: onRestore != null,
          onButtonPressed: () {
            if (isActionTaken) return;
            isActionTaken = true;
            // Pass true to signal the user wants to give up
            Navigator.of(dialogCtx).pop(true);
          },
"@

$replacementGameOver = @"
        return ModernGameDialog(
          title: resolvedTitle,
          description: resolvedDescription,
          buttonText: resolvedButtonText,
          isSuccess: false,
          isRescueLife: onRestore != null,
          onSecondaryPressed: () {
            if (isActionTaken) return;
            isActionTaken = true;
            Navigator.of(dialogCtx).pop(true); // Pop dialog
            if (context.mounted) {
              Navigator.of(context).pop(true); // Pop game screen
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  context.push('/review_mistakes');
                }
              });
            }
          },
          secondaryButtonText: context.tr('games.review_mistakes', fallback: 'Review Mistakes'),
          onButtonPressed: () {
            if (isActionTaken) return;
            isActionTaken = true;
            // Pass true to signal the user wants to give up
            Navigator.of(dialogCtx).pop(true);
          },
"@

$content = $content.Replace($targetGameOver, $replacementGameOver)

$targetCompletion = @"
            ModernGameDialog(
              title: resolvedTitle,
              description: desc,
              buttonText: resolvedButtonText,
              starsListener: GamificationRepositoryImpl.lastEarnedStars,
              onButtonPressed: () {
"@

$replacementCompletion = @"
            ModernGameDialog(
              title: resolvedTitle,
              description: desc,
              buttonText: resolvedButtonText,
              starsListener: GamificationRepositoryImpl.lastEarnedStars,
              onSecondaryPressed: mistakesMade > 0 ? () {
                Navigator.of(dialogCtx).pop();
                if (context.mounted) {
                  context.read<AuthBloc>().add(const AuthRefreshUser());
                  Navigator.of(context).pop(popResult);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) {
                      context.push('/review_mistakes');
                    }
                  });
                }
              } : null,
              secondaryButtonText: mistakesMade > 0 ? context.tr('games.review_mistakes', fallback: 'Review Mistakes') : null,
              onButtonPressed: () {
"@

$content = $content.Replace($targetCompletion, $replacementCompletion)

Set-Content $path $content
