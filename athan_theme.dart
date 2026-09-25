import 'package:flutter/material.dart';

/// Athan-style token set extracted from screenshots (@3x, 393x852 dp logical).
/// Values marked TODO in the JSON spec are intentionally absent here.

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.successBright,
    required this.successText,
    required this.accentOrange,
    required this.accentPurple,
    required this.accentBlue,
    required this.promoPurple,
    required this.adBadgeMagenta,
    required this.surfaceSunken,
    required this.outlineOnSurface,
    required this.outlineStrong,
    required this.onSurfaceMuted,
    required this.categoryPrayers,
    required this.categoryQuran,
    required this.categoryDhikr,
    required this.categoryOther,
    required this.timetableHeaderBlue,
    required this.timetableRowDark,
    required this.timetableRowLight,
  });

  final Color successBright;      // #17C964 countdown ring, notification speakers
  final Color successText;        // #06A44B picker Cancel/Done
  final Color accentOrange;       // #F5A623 dhikr + goal accent
  final Color accentPurple;       // #7C4DFF quran
  final Color accentBlue;         // #2196F3 other
  final Color promoPurple;        // #8E6DC8 remove-ads banner
  final Color adBadgeMagenta;     // #C210C8 header badge
  final Color surfaceSunken;      // #E7E4DE menstrual-mode strip
  final Color outlineOnSurface;   // #EBEBEB dividers inside white cards
  final Color outlineStrong;      // #8A8A8A 1.5 dp outlined-button stroke
  final Color onSurfaceMuted;     // #9A9A9A empty values, inactive dots
  final Color categoryPrayers;
  final Color categoryQuran;
  final Color categoryDhikr;
  final Color categoryOther;
  final Color timetableHeaderBlue;
  final Color timetableRowDark;
  final Color timetableRowLight;

  @override
  AppPalette copyWith({
    Color? successBright,
    Color? successText,
    Color? accentOrange,
    Color? accentPurple,
    Color? accentBlue,
    Color? promoPurple,
    Color? adBadgeMagenta,
    Color? surfaceSunken,
    Color? outlineOnSurface,
    Color? outlineStrong,
    Color? onSurfaceMuted,
    Color? categoryPrayers,
    Color? categoryQuran,
    Color? categoryDhikr,
    Color? categoryOther,
    Color? timetableHeaderBlue,
    Color? timetableRowDark,
    Color? timetableRowLight,
  }) {
    return AppPalette(
      successBright: successBright ?? this.successBright,
      successText: successText ?? this.successText,
      accentOrange: accentOrange ?? this.accentOrange,
      accentPurple: accentPurple ?? this.accentPurple,
      accentBlue: accentBlue ?? this.accentBlue,
      promoPurple: promoPurple ?? this.promoPurple,
      adBadgeMagenta: adBadgeMagenta ?? this.adBadgeMagenta,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      outlineOnSurface: outlineOnSurface ?? this.outlineOnSurface,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      categoryPrayers: categoryPrayers ?? this.categoryPrayers,
      categoryQuran: categoryQuran ?? this.categoryQuran,
      categoryDhikr: categoryDhikr ?? this.categoryDhikr,
      categoryOther: categoryOther ?? this.categoryOther,
      timetableHeaderBlue: timetableHeaderBlue ?? this.timetableHeaderBlue,
      timetableRowDark: timetableRowDark ?? this.timetableRowDark,
      timetableRowLight: timetableRowLight ?? this.timetableRowLight,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      successBright: Color.lerp(successBright, other.successBright, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      accentOrange: Color.lerp(accentOrange, other.accentOrange, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      promoPurple: Color.lerp(promoPurple, other.promoPurple, t)!,
      adBadgeMagenta: Color.lerp(adBadgeMagenta, other.adBadgeMagenta, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      outlineOnSurface: Color.lerp(outlineOnSurface, other.outlineOnSurface, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      categoryPrayers: Color.lerp(categoryPrayers, other.categoryPrayers, t)!,
      categoryQuran: Color.lerp(categoryQuran, other.categoryQuran, t)!,
      categoryDhikr: Color.lerp(categoryDhikr, other.categoryDhikr, t)!,
      categoryOther: Color.lerp(categoryOther, other.categoryOther, t)!,
      timetableHeaderBlue:
          Color.lerp(timetableHeaderBlue, other.timetableHeaderBlue, t)!,
      timetableRowDark: Color.lerp(timetableRowDark, other.timetableRowDark, t)!,
      timetableRowLight:
          Color.lerp(timetableRowLight, other.timetableRowLight, t)!,
    );
  }

  static const light = AppPalette(
    successBright: Color(0xFF17C964),
    successText: Color(0xFF06A44B),
    accentOrange: Color(0xFFF5A623),
    accentPurple: Color(0xFF7C4DFF),
    accentBlue: Color(0xFF2196F3),
    promoPurple: Color(0xFF8E6DC8),
    adBadgeMagenta: Color(0xFFC210C8),
    surfaceSunken: Color(0xFFE7E4DE),
    outlineOnSurface: Color(0xFFEBEBEB),
    outlineStrong: Color(0xFF8A8A8A),
    onSurfaceMuted: Color(0xFF9A9A9A),
    categoryPrayers: Color(0xFF00873F),
    categoryQuran: Color(0xFF7C4DFF),
    categoryDhikr: Color(0xFFF5A623),
    categoryOther: Color(0xFF2196F3),
    timetableHeaderBlue: Color(0xFF2E8FBF),
    timetableRowDark: Color(0xFF4A4A4A),
    timetableRowLight: Color(0xFFF7F7F7),
  );
}

@immutable
class AppMetrics extends ThemeExtension<AppMetrics> {
  const AppMetrics({
    this.base = 4.0,
    this.gutterList = 16.0,
    this.gutterCard = 20.0,
    this.gutterReader = 24.0,
    this.radiusCard = 20.0,
    this.radiusListCard = 16.0,
    this.radiusSheetTop = 24.0,
    this.radiusFolder = 40.0,
    this.radiusIconTile = 14.0,
    this.hairline = 0.5,
    this.sectionRule = 1.5,
    this.progressTrack = 8.0,
    this.ringStroke = 6.0,
    this.iconTabBar = 23.0,
    this.iconListLeading = 27.0,
    this.iconAction = 26.0,
    this.backButtonDiameter = 42.0,
    this.confirmFabDiameter = 112.0, // uncertain, single observation
  });

  final double base,
      gutterList,
      gutterCard,
      gutterReader,
      radiusCard,
      radiusListCard,
      radiusSheetTop,
      radiusFolder,
      radiusIconTile,
      hairline,
      sectionRule,
      progressTrack,
      ringStroke,
      iconTabBar,
      iconListLeading,
      iconAction,
      backButtonDiameter,
      confirmFabDiameter;

  @override
  AppMetrics copyWith() => this;

  @override
  AppMetrics lerp(ThemeExtension<AppMetrics>? other, double t) => this;

  static const standard = AppMetrics();
}

const _bodyFont = 'Roboto';   // best match; verify against the real bundle
const _displayFont = 'Roboto'; // TODO: display face is a distinct unidentified
                               // slabbed geometric - swap once identified

const ColorScheme athanColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF4B45F0),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEDEDED), // neutral chip, deliberately untinted
  onPrimaryContainer: Color(0xFF4B45F0),
  secondary: Color(0xFF00873F),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF00873F),
  onSecondaryContainer: Color(0xFFFFFFFF),
  tertiary: Color(0xFFF5A623),
  onTertiary: Color(0xFF111111),
  // No error colour is evidenced anywhere in the source app. Material demands
  // one, so this is an explicit placeholder, NOT an extracted token.
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF111111),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFF0EDE7),
  surfaceContainerHighest: Color(0xFFF5F5F5),
  onSurfaceVariant: Color(0xFF6E6E6E),
  outline: Color(0xFFE3E0DA),
  outlineVariant: Color(0xFFEBEBEB),
  shadow: Color(0x00000000), // shadowless system
  scrim: Color(0x8C6E6E6E),
  inverseSurface: Color(0xFF4A4A4A),
  onInverseSurface: Color(0xFFFFFFFF),
);

final ThemeData athanTheme = ThemeData(
  useMaterial3: true,
  colorScheme: athanColorScheme,
  scaffoldBackgroundColor: const Color(0xFFF0EDE7),
  splashFactory: InkSparkle.splashFactory,
  extensions: const <ThemeExtension<dynamic>>[
    AppPalette.light,
    AppMetrics.standard,
  ],

  // Tracking is ~0 everywhere except all-caps section labels: a deliberate
  // deviation from Material 3's positive label/body tracking.
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: _displayFont, fontSize: 24, fontWeight: FontWeight.w700, height: 30 / 24, letterSpacing: 0, color: Color(0xFF111111)),
    headlineSmall: TextStyle(fontFamily: _bodyFont, fontSize: 21, fontWeight: FontWeight.w500, height: 28 / 21, letterSpacing: 0, color: Color(0xFF111111)),
    titleLarge: TextStyle(fontFamily: _bodyFont, fontSize: 20, fontWeight: FontWeight.w700, height: 26 / 20, letterSpacing: 0, color: Color(0xFF111111)),
    titleMedium: TextStyle(fontFamily: _displayFont, fontSize: 19, fontWeight: FontWeight.w700, height: 25 / 19, letterSpacing: 0, color: Color(0xFF111111)),
    bodyLarge: TextStyle(fontFamily: _bodyFont, fontSize: 17.5, fontWeight: FontWeight.w400, height: 25 / 17.5, letterSpacing: 0, color: Color(0xFF111111)),
    bodyMedium: TextStyle(fontFamily: _bodyFont, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, letterSpacing: 0, color: Color(0xFF6E6E6E)),
    labelLarge: TextStyle(fontFamily: _bodyFont, fontSize: 17, fontWeight: FontWeight.w700, height: 22 / 17, letterSpacing: 0),
    labelMedium: TextStyle(fontFamily: _bodyFont, fontSize: 12.5, fontWeight: FontWeight.w500, height: 16 / 12.5, letterSpacing: 0, color: Color(0xFF6E6E6E)),
    labelSmall: TextStyle(fontFamily: _bodyFont, fontSize: 11, fontWeight: FontWeight.w500, height: 14 / 11, letterSpacing: 0.1, color: Color(0xFF111111)),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF0EDE7),
    foregroundColor: Color(0xFF111111),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    toolbarHeight: 56,
    titleTextStyle: TextStyle(fontFamily: _bodyFont, fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
    iconTheme: IconThemeData(size: 24, color: Color(0xFF111111)),
    actionsIconTheme: IconThemeData(size: 26, color: Color(0xFF111111)),
  ),

  cardTheme: CardThemeData(
    color: const Color(0xFFFFFFFF),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),

  dividerTheme: const DividerThemeData(
    color: Color(0xFFE3E0DA),
    thickness: 0.5,
    space: 0.5,
  ),

  listTileTheme: const ListTileThemeData(
    minVerticalPadding: 12,
    horizontalTitleGap: 16,
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
    minLeadingWidth: 27,
    titleTextStyle: TextStyle(fontFamily: _bodyFont, fontSize: 17.5, fontWeight: FontWeight.w400, height: 25 / 17.5, color: Color(0xFF111111)),
    subtitleTextStyle: TextStyle(fontFamily: _bodyFont, fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: Color(0xFF6E6E6E)),
    iconColor: Color(0xFF111111),
  ),

  iconTheme: const IconThemeData(size: 24, color: Color(0xFF111111)),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF00873F),
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontFamily: _bodyFont, fontSize: 17, fontWeight: FontWeight.w700),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF111111),
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      side: const BorderSide(color: Color(0xFF8A8A8A), width: 1.5),
      shape: const StadiumBorder(),
      textStyle: const TextStyle(fontFamily: _bodyFont, fontSize: 17, fontWeight: FontWeight.w700),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF4B45F0),
      textStyle: const TextStyle(fontFamily: _bodyFont, fontSize: 17, fontWeight: FontWeight.w700),
    ),
  ),

  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? const Color(0xFF00873F) : const Color(0xFFFAFAFA),
    ),
    thumbColor: const WidgetStatePropertyAll(Colors.white),
    trackOutlineColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFFD5D2CC),
    ),
    trackOutlineWidth: const WidgetStatePropertyAll(1),
    thumbIcon: const WidgetStatePropertyAll(null),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFFF5A623),
    linearTrackColor: Color(0xFFE0DDD7),
    linearMinHeight: 8,
    circularTrackColor: Color(0xFFE0DDD7),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Color(0xFF4B45F0),
    unselectedItemColor: Color(0xFF111111),
    selectedIconTheme: IconThemeData(size: 23),
    unselectedIconTheme: IconThemeData(size: 23),
    selectedLabelStyle: TextStyle(fontFamily: _bodyFont, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    unselectedLabelStyle: TextStyle(fontFamily: _bodyFont, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.1),
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    showDragHandle: true,
    dragHandleColor: Color(0xFFD9D6D0),
    dragHandleSize: Size(36, 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFF5A623),
    foregroundColor: Colors.white,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: CircleBorder(),
    iconSize: 44,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF0EDE7),
    side: BorderSide.none,
    labelStyle: const TextStyle(fontFamily: _bodyFont, fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
);
