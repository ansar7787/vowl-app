import 'dart:io';

void main() {
  final file = File('lib/features/writing/complete_sentence/presentation/pages/complete_sentence_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');

  // Variables
  content = content.replaceAll('String? _selectedProjectile;', 'final ValueNotifier<String?> _selectedProjectile = ValueNotifier(null);');
  content = content.replaceAll('bool _showConfetti = false;', 'final ValueNotifier<bool> _showConfetti = ValueNotifier(false);');
  content = content.replaceAll('bool _showAnagram = false;', 'final ValueNotifier<bool> _showAnagram = ValueNotifier(false);');

  // Dispose
  content = content.replaceAll('''  @override
  void dispose() {
    _dragNotifier.dispose();
    super.dispose();
  }''', '''  @override
  void dispose() {
    _dragNotifier.dispose();
    _selectedProjectile.dispose();
    _showConfetti.dispose();
    _showAnagram.dispose();
    super.dispose();
  }''');

  // Logic
  content = content.replaceAll('''    setState(() {
      _selectedProjectile = selected;
    });''', '''    _selectedProjectile.value = selected;''');

  content = content.replaceAll('''      setState(() {
        _showAnagram = true;
      });''', '''      _showAnagram.value = true;''');

  content = content.replaceAll('''    setState(() {
      _showAnagram = false;
    });''', '''    _showAnagram.value = false;''');

  content = content.replaceAll('''          setState(() {
            _selectedProjectile = null;
            _dragNotifier.value = null;
            _showAnagram = false;
          });''', '''          _selectedProjectile.value = null;
          _dragNotifier.value = null;
          _showAnagram.value = false;''');

  content = content.replaceAll('setState(() => _showConfetti = true);', '_showConfetti.value = true;');

  // Builder Wrap
  content = content.replaceAll('''          showConfetti: _showConfetti,''', '''          showConfetti: _showConfetti.value,''');

  content = content.replaceAll('''          child: quest == null
              ? (_lastQuest == null
                    ? GameShimmerLoading(primaryColor: _theme.primaryColor)
                    : const SizedBox.shrink())
              : Stack(''', '''          child: ListenableBuilder(
            listenable: Listenable.merge([_showConfetti, _selectedProjectile, _showAnagram]),
            builder: (context, _) {
              return quest == null
                  ? (_lastQuest == null
                        ? GameShimmerLoading(primaryColor: _theme.primaryColor)
                        : const SizedBox.shrink())
                  : Stack(''');

  // Widget properties
  content = content.replaceAll('''                      selectedProjectile: _selectedProjectile,''', '''                      selectedProjectile: _selectedProjectile.value,''');
  
  content = content.replaceAll('''                    if (_showAnagram && !isAnswered)''', '''                    if (_showAnagram.value && !isAnswered)''');

  // Fix brackets at bottom of builder
  content = content.replaceAll('''                  ],
                ),
        );
      },
    );
  }
}''', '''                  ],
                );
            },
          ),
        );
      },
    );
  }
}''');

  // Fix Sliver Layout
  content = content.replaceAll('''        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: 160.h), // Bottom padding for feedback card
            ],
          ),
        ),''', '''        SliverToBoxAdapter(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(height: 160.h), // Bottom padding for feedback card
            ],
          ),
        ),''');

  content = content.replaceAll('\n', '\r\n');
  file.writeAsStringSync(content);
}
