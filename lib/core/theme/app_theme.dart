import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Color Palette - Slate (Neutral Grays)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Color Palette - Blue
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);
  static const Color blue950 = Color(0xFF172554);

  // Color Palette - Emerald/Green
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald950 = Color(0xFF022C22);

  // Color Palette - Amber
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber950 = Color(0xFF451A03);

  // Color Palette - Red
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);
  static const Color red950 = Color(0xFF450A0A);

  // Color Palette - Indigo
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);
  static const Color indigo950 = Color(0xFF1E1B4B);

  // Color Palette - Purple
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple200 = Color(0xFFE9D5FF);
  static const Color purple300 = Color(0xFFD8B4FE);
  static const Color purple400 = Color(0xFFC084FC);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple600 = Color(0xFF9333EA);
  static const Color purple700 = Color(0xFF7E22CE);
  static const Color purple800 = Color(0xFF6B21A8);
  static const Color purple900 = Color(0xFF581C87);
  static const Color purple950 = Color(0xFF3B0764);

  // Color Palette - Orange
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange300 = Color(0xFFFDBA74);
  static const Color orange400 = Color(0xFFF97316);
  static const Color orange500 = Color(0xFFEA580C);
  static const Color orange600 = Color(0xFFC2410C);
  static const Color orange700 = Color(0xFF9A3412);
  static const Color orange800 = Color(0xFF7C2D12);
  static const Color orange900 = Color(0xFF631A08);
  static const Color orange950 = Color(0xFF431407);

  // Color Palette - Yellow
  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF9C3);
  static const Color yellow200 = Color(0xFFFEF08A);
  static const Color yellow300 = Color(0xFFFDE047);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow500 = Color(0xFFEAB308);
  static const Color yellow600 = Color(0xFFCA8A04);
  static const Color yellow700 = Color(0xFFA16207);
  static const Color yellow800 = Color(0xFF854D0E);
  static const Color yellow900 = Color(0xFF713F12);
  static const Color yellow950 = Color(0xFF422006);

  // Color Palette - White
  static const Color white = Color(0xFFFFFFFF);

  // Color Palette - Cyan
  static const Color cyan50 = Color(0xFFECFEFF);
  static const Color cyan100 = Color(0xFFCFFAFE);
  static const Color cyan200 = Color(0xFFA5F3FC);
  static const Color cyan300 = Color(0xFF67E8F9);
  static const Color cyan400 = Color(0xFF22D3EE);
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color cyan600 = Color(0xFF0891B2);
  static const Color cyan700 = Color(0xFF0E7490);
  static const Color cyan800 = Color(0xFF155E75);
  static const Color cyan900 = Color(0xFF164E63);
  static const Color cyan950 = Color(0xFF083344);

  // Color Palette - Teal
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal200 = Color(0xFF99F6E4);
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal800 = Color(0xFF115E59);
  static const Color teal900 = Color(0xFF134E3A);
  static const Color teal950 = Color(0xFF042F2E);

  // Dark Theme Specific Colors
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkElevatedCard = Color(0xFF0F172A);
  static const Color darkPage = Color(0xFF0F172A);
  static const Color darkInput = Color(0xFF1E293B);
  static const Color darkHover = Color(0xFF334155);

  // PinoyPOS Warm Theme Colors - Replaced warm orange with white/neutral
  static const Color cream50 = Color(0xFFFEFCF5);
  static const Color cream100 = Color(0xFFFEF9E7);
  static const Color cream200 = Color(0xFFFDF2C9);
  static const Color cream300 = Color(0xFFFBE68A);
  static const Color cream400 = Color(0xFFF9D65A);
  static const Color cream500 = Color(0xFFF7C72E);
  static const Color cream600 = Color(0xFFE5B41D);
  static const Color cream700 = Color(0xFFC49312);
  static const Color cream800 = Color(0xFFA3760F);
  static const Color cream900 = Color(0xFF865D12);
  static const Color cream950 = Color(0xFF473308);

  // Replaced warmOrange with neutral white/gray tones
  static const Color neutralWhite50 = Color(0xFFFFFFFF);
  static const Color neutralWhite100 = Color(0xFFFAFAFA);
  static const Color neutralWhite200 = Color(0xFFF5F5F5);
  static const Color neutralWhite300 = Color(0xFFE5E5E5);
  static const Color neutralWhite400 = Color(0xFFD4D4D4);
  static const Color neutralWhite500 = Color(0xFFA3A3A3);
  static const Color neutralWhite600 = Color(0xFF737373);
  static const Color neutralWhite700 = Color(0xFF525252);
  static const Color neutralWhite800 = Color(0xFF404040);
  static const Color neutralWhite900 = Color(0xFF262626);
  static const Color neutralWhite950 = Color(0xFF171717);

  // Bamboo Green - kept as primary green
  static const Color bambooGreen50 = Color(0xFFF0FDF4);
  static const Color bambooGreen100 = Color(0xFFDCFCE7);
  static const Color bambooGreen200 = Color(0xFFBBF7D0);
  static const Color bambooGreen300 = Color(0xFF86EFAC);
  static const Color bambooGreen400 = Color(0xFF4ADE80);
  static const Color bambooGreen500 = Color(0xFF22C55E);
  static const Color bambooGreen600 = Color(0xFF16A34A);
  static const Color bambooGreen700 = Color(0xFF15803D);
  static const Color bambooGreen800 = Color(0xFF166534);
  static const Color bambooGreen900 = Color(0xFF14532D);
  static const Color bambooGreen950 = Color(0xFF052E16);

  // Design Tokens - Spacing
  static const double spacing0 = 0;
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 20;
  static const double spacing6 = 24;
  static const double spacing7 = 28;
  static const double spacing8 = 32;
  static const double spacing9 = 36;
  static const double spacing10 = 40;
  static const double spacing11 = 44;
  static const double spacing12 = 48;
  static const double spacing14 = 56;
  static const double spacing16 = 64;
  static const double spacing20 = 80;
  static const double spacing24 = 96;

  // Legacy spacing aliases for compatibility
  static const double smallSpacing = spacing2;
  static const double mediumSpacing = spacing4;
  static const double largeSpacing = spacing6;
  static const double cardPadding = spacing4;
  static const double borderRadius = roundedLg;

  // Design Tokens - Border Radius
  static const double roundedNone = 0;
  static const double roundedSm = 4;
  static const double rounded = 8;
  static const double roundedMd = 12;
  static const double roundedLg = 16;
  static const double roundedXl = 20;
  static const double rounded2xl = 24;
  static const double rounded3xl = 32;
  static const double roundedFull = 9999;

  // Design Tokens - Typography
  static const double textXxs = 10;
  static const double textXs = 12;
  static const double textSm = 14;
  static const double textBase = 16;
  static const double textLg = 18;
  static const double textXl = 20;
  static const double text2xl = 24;
  static const double text3xl = 30;
  static const double text4xl = 36;
  static const double text5xl = 48;
  static const double text6xl = 60;

  // Design Tokens - Font Weights
  static const FontWeight fontThin = FontWeight.w100;
  static const FontWeight fontExtraLight = FontWeight.w200;
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontNormal = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemiBold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
  static const FontWeight fontExtraBold = FontWeight.w800;
  static const FontWeight fontBlack = FontWeight.w900;

  // Design Tokens - Shadows
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadow2xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 25,
          offset: const Offset(0, 12),
        ),
      ];

  // Dark mode shadows
  static List<BoxShadow> get shadowSmDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMdDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 4,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 2,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLgDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowXlDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadow2xlDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 25,
          offset: const Offset(0, 12),
        ),
      ];

  // Light Theme - White and Green Palette
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: bambooGreen600,
        onPrimary: Colors.white,
        primaryContainer: bambooGreen50,
        onPrimaryContainer: bambooGreen900,
        secondary: slate600,
        onSecondary: Colors.white,
        secondaryContainer: slate100,
        onSecondaryContainer: slate900,
        tertiary: emerald600,
        onTertiary: Colors.white,
        tertiaryContainer: emerald50,
        onTertiaryContainer: emerald900,
        error: red600,
        onError: Colors.white,
        errorContainer: red100,
        onErrorContainer: red900,
        surface: neutralWhite50,
        onSurface: slate900,
        surfaceContainerHighest: neutralWhite200,
        onSurfaceVariant: slate600,
        outline: slate300,
        outlineVariant: slate200,
        inverseSurface: slate800,
        onInverseSurface: slate100,
        inversePrimary: bambooGreen500,
        shadow: slate900,
        scrim: Colors.black.withValues(alpha: 0.5),
      ),
      scaffoldBackgroundColor: neutralWhite50,
      cardColor: Colors.white,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundedLg),
        ),
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: slate900,
        iconTheme: IconThemeData(color: slate700),
        titleTextStyle: TextStyle(
          color: slate900,
          fontSize: textLg,
          fontWeight: fontSemiBold,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        actionsIconTheme: IconThemeData(color: slate700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundedLg),
          ),
          textStyle: const TextStyle(
            fontSize: textSm,
            fontWeight: fontSemiBold,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundedLg),
          ),
          side: const BorderSide(color: slate300, width: 1),
          textStyle: const TextStyle(
            fontSize: textSm,
            fontWeight: fontSemiBold,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundedLg),
          ),
          textStyle: const TextStyle(
            fontSize: textSm,
            fontWeight: fontSemiBold,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: slate300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: slate300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: bambooGreen500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: red500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: red500, width: 2),
        ),
        labelStyle: const TextStyle(
          color: slate600,
          fontSize: textSm,
        ),
        hintStyle: const TextStyle(
          color: slate400,
          fontSize: textSm,
        ),
        errorStyle: const TextStyle(
          color: red600,
          fontSize: textXs,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate100,
        deleteIconColor: slate600,
        disabledColor: slate200,
        selectedColor: bambooGreen100,
        secondarySelectedColor: bambooGreen200,
        padding: const EdgeInsets.symmetric(horizontal: spacing3, vertical: spacing2),
        labelStyle: const TextStyle(
          color: slate700,
          fontSize: textSm,
        ),
        secondaryLabelStyle: const TextStyle(
          color: slate700,
          fontSize: textSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rounded),
        ),
      ),
      iconTheme: const IconThemeData(
        color: slate600,
        size: 20,
      ),
      dividerTheme: const DividerThemeData(
        color: slate200,
        thickness: 1,
        space: spacing4,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: bambooGreen500,
        onPrimary: Colors.white,
        primaryContainer: bambooGreen900,
        onPrimaryContainer: bambooGreen100,
        secondary: slate400,
        onSecondary: slate900,
        secondaryContainer: slate800,
        onSecondaryContainer: slate100,
        tertiary: emerald400,
        onTertiary: slate900,
        tertiaryContainer: emerald900,
        onTertiaryContainer: emerald100,
        error: red400,
        onError: slate900,
        errorContainer: red900,
        onErrorContainer: red100,
        surface: slate900,
        onSurface: slate100,
        surfaceContainerHighest: slate800,
        onSurfaceVariant: slate400,
        outline: slate700,
        outlineVariant: slate800,
        inverseSurface: slate100,
        onInverseSurface: slate900,
        inversePrimary: bambooGreen600,
        shadow: Colors.black,
        scrim: Colors.black.withValues(alpha: 0.5),
      ),
      scaffoldBackgroundColor: slate950,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundedLg),
        ),
        color: slate900,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: slate900,
        foregroundColor: slate100,
        iconTheme: IconThemeData(color: slate400),
        titleTextStyle: TextStyle(
          color: slate100,
          fontSize: textLg,
          fontWeight: fontSemiBold,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        actionsIconTheme: IconThemeData(color: slate400),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundedLg),
          ),
          textStyle: const TextStyle(
            fontSize: textSm,
            fontWeight: fontSemiBold,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundedLg),
          ),
          side: const BorderSide(color: slate700, width: 1),
          textStyle: const TextStyle(
            fontSize: textSm,
            fontWeight: fontSemiBold,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(roundedLg),
          ),
          textStyle: const TextStyle(
            fontSize: textSm,
            fontWeight: fontSemiBold,
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: bambooGreen400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: red400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(roundedLg),
          borderSide: const BorderSide(color: red400, width: 2),
        ),
        labelStyle: const TextStyle(
          color: slate400,
          fontSize: textSm,
        ),
        hintStyle: const TextStyle(
          color: slate500,
          fontSize: textSm,
        ),
        errorStyle: const TextStyle(
          color: red400,
          fontSize: textXs,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate800,
        deleteIconColor: slate400,
        disabledColor: slate700,
        selectedColor: bambooGreen900,
        secondarySelectedColor: bambooGreen800,
        padding: const EdgeInsets.symmetric(horizontal: spacing3, vertical: spacing2),
        labelStyle: const TextStyle(
          color: slate300,
          fontSize: textSm,
        ),
        secondaryLabelStyle: const TextStyle(
          color: slate300,
          fontSize: textSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rounded),
        ),
      ),
      iconTheme: const IconThemeData(
        color: slate400,
        size: 20,
      ),
      dividerTheme: const DividerThemeData(
        color: slate800,
        thickness: 1,
        space: spacing4,
      ),
    );
  }
}
