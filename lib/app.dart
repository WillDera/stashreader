import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/library/library_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/snippets/snippets_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class StashReaderApp extends StatelessWidget {
  const StashReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'StashReader',
      debugShowCheckedModeBanner: false,
      theme: themeProv.isSepia ? themeProv.sepiaTheme : themeProv.lightTheme,
      darkTheme: themeProv.darkTheme,
      themeMode: themeProv.isSepia ? ThemeMode.light : themeProv.themeMode,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    LibraryScreen(),
    SnippetsScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  static const _icons = [
    Icons.menu_book,
    Icons.bookmark,
    Icons.search,
    Icons.settings,
  ];
  static const _labels = ['Library', 'Snippets', 'Search', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = context.watch<ThemeProvider>().isSepia;
    final bgColor = isSepia
        ? AppTheme.sepiaBackground
        : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground);
    final pillBg = isSepia
        ? AppTheme.sepiaSurface
        : (isDark ? const Color(0xFF2A2928) : const Color(0xFFF0ECE4));
    final activeColor = isSepia ? AppTheme.sepiaAccent : AppTheme.accent;
    final inactiveColor = isSepia
        ? AppTheme.sepiaTextSecondary
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // ponytail: floating pill nav, replace with standard BottomNavigationBar if platform feel matters more than look
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final active = _currentIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[i],
                          size: 22,
                          color: active ? activeColor : inactiveColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            color: active ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
