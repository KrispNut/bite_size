import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show Color, HSLColor, ChangeNotifier, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class Currency {
  final String code;
  final String symbol;
  final int minorExponent;

  const Currency({
    required this.code,
    required this.symbol,
    this.minorExponent = 2,
  });

  static const pkr = Currency(code: 'PKR', symbol: 'Rs');
  static const inr = Currency(code: 'INR', symbol: '₹');
  static const usd = Currency(code: 'USD', symbol: '\$');
  static const gbp = Currency(code: 'GBP', symbol: '£');
  static const eur = Currency(code: 'EUR', symbol: '€');
  static const aed = Currency(code: 'AED', symbol: 'AED');

  static const _all = [pkr, inr, usd, gbp, eur, aed];

  static Currency fromCode(String? code) {
    if (code == null) return pkr;
    final wanted = code.toUpperCase();
    for (final c in _all) {
      if (c.code == wanted) return c;
    }
    return pkr;
  }

  int get minorPerMajor {
    var n = 1;
    for (var i = 0; i < minorExponent; i++) {
      n *= 10;
    }
    return n;
  }

  double toMajor(int minor) => minor / minorPerMajor;
  int toMinor(num major) => (major * minorPerMajor).round();

  String format(int minor, {bool withSymbol = true, bool decimals = true}) {
    final showFraction = decimals && minorExponent > 0;
    final negative = minor < 0;
    final abs = minor.abs();
    final whole = showFraction
        ? abs ~/ minorPerMajor
        : (abs / minorPerMajor).round();
    final body = StringBuffer(_group(whole));

    if (showFraction) {
      final frac = (abs % minorPerMajor).toString().padLeft(minorExponent, '0');
      body.write('.$frac');
    }

    final sign = negative ? '-' : '';
    return withSymbol ? '$sign$symbol ${body.toString()}' : '$sign$body';
  }

  String formatMajor(
    num major, {
    bool withSymbol = true,
    bool decimals = true,
  }) => format(toMinor(major), withSymbol: withSymbol, decimals: decimals);

  static String _group(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}

enum ShapeDepth {
  soft,
  hard,
  flat;

  static ShapeDepth fromString(String? value) => ShapeDepth.values.firstWhere(
    (d) => d.name == value,
    orElse: () => ShapeDepth.soft,
  );
}

class PackShape {
  final double radiusScale;
  final double strokeWidth;
  final ShapeDepth depth;

  const PackShape({
    this.radiusScale = 1.0,
    this.strokeWidth = 1.0,
    this.depth = ShapeDepth.soft,
  });
  static const standard = PackShape();
  static const brutalist = PackShape(
    radiusScale: 0.35,
    strokeWidth: 2.0,
    depth: ShapeDepth.hard,
  );
  static const rounded = PackShape(radiusScale: 1.6);
  static const document = PackShape(radiusScale: 0.6, depth: ShapeDepth.flat);

  double scale(double base) => (base * radiusScale).clamp(0.0, base * 2.5);

  factory PackShape.fromJson(Map<String, dynamic> json) => PackShape(
    radiusScale:
        (json['radiusScale'] as num?)?.toDouble().clamp(0.0, 2.5) ?? 1.0,
    strokeWidth:
        (json['strokeWidth'] as num?)?.toDouble().clamp(0.5, 4.0) ?? 1.0,
    depth: ShapeDepth.fromString(json['depth'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'radiusScale': radiusScale,
    'strokeWidth': strokeWidth,
    'depth': depth.name,
  };
}

class PackModules {
  final bool roster, coverage, units, errand, advisor, ping;
  const PackModules({
    this.roster = false,
    this.coverage = false,
    this.units = false,
    this.errand = false,
    this.advisor = false,
    this.ping = false,
  });

  PackModules get normalised => PackModules(
    roster: roster,
    coverage: coverage && roster,
    units: units,
    errand: errand,
    advisor: advisor && roster,
    ping: ping,
  );

  factory PackModules.fromJson(Map<String, dynamic> json) => PackModules(
    roster: json['roster'] == true,
    coverage: json['coverage'] == true,
    units: json['units'] == true,
    errand: json['errand'] == true,
    advisor: json['advisor'] == true,
    ping: json['ping'] == true,
  );
  Map<String, dynamic> toJson() => {
    'roster': roster,
    'coverage': coverage,
    'units': units,
    'errand': errand,
    'advisor': advisor,
    'ping': ping,
  };
}

class PackLabels {
  final String activityName,
      sessionNoun,
      unit,
      unitPlural,
      contribution,
      contributionVerb,
      coverage,
      errand,
      runner,
      outsider,
      expense,
      expensePlural,
      arrival,
      attendingOnly,
      tagline,
      advisorName;
  final List<String> taglines;

  const PackLabels({
    this.activityName = 'Shared Costs',
    this.sessionNoun = 'session',
    this.unit = 'item',
    this.unitPlural = 'items',
    this.contribution = 'contribution',
    this.contributionVerb = 'brought',
    this.coverage = 'portions',
    this.errand = 'run',
    this.runner = 'runner',
    this.outsider = 'helper',
    this.expense = 'shared cost',
    this.expensePlural = 'shared costs',
    this.attendingOnly = 'Taking part only',
    this.tagline = 'SHARED COSTS, SETTLED FAIRLY',
    this.taglines = const [],
    this.arrival = 'Everything arrived',
    this.advisorName = 'Advisor',
  });

  String get unitCaps => unitPlural.toUpperCase();
  String get coverageCaps => coverage.toUpperCase();
  String unitCount(int n) => '$n ${n == 1 ? unit : unitPlural}';
  String expenseCount(int n) => '$n ${n == 1 ? expense : expensePlural}';
  String get coverageSingular => coverage.endsWith('s')
      ? coverage.substring(0, coverage.length - 1)
      : coverage;
  String coverCount(int n) => '$n ${n == 1 ? coverageSingular : coverage}';
  String get unitPluralTitle => _titleCase(unitPlural);
  String get expensePluralTitle => _titleCase(expensePlural);
  String get expenseTitle => _titleCase(expense);
  String get errandTitle => _titleCase(errand);
  String get runnerTitle => _titleCase(runner);
  static String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  factory PackLabels.fromJson(Map<String, dynamic> json) {
    const d = PackLabels();
    String s(String key, String fallback) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : fallback;
    }

    return PackLabels(
      activityName: s('activityName', d.activityName),
      sessionNoun: s('sessionNoun', d.sessionNoun),
      unit: s('unit', d.unit),
      unitPlural: s('unitPlural', d.unitPlural),
      contribution: s('contribution', d.contribution),
      contributionVerb: s('contributionVerb', d.contributionVerb),
      coverage: s('coverage', d.coverage),
      errand: s('errand', d.errand),
      runner: s('runner', d.runner),
      outsider: s('outsider', d.outsider),
      expense: s('expense', d.expense),
      expensePlural: s('expensePlural', d.expensePlural),
      attendingOnly: s('attendingOnly', d.attendingOnly),
      tagline: s('tagline', d.tagline),
      taglines:
          (json['taglines'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          d.taglines,
      arrival: s('arrival', d.arrival),
      advisorName: s('advisorName', d.advisorName),
    );
  }
  Map<String, dynamic> toJson() => {
    'activityName': activityName,
    'sessionNoun': sessionNoun,
    'unit': unit,
    'unitPlural': unitPlural,
    'contribution': contribution,
    'contributionVerb': contributionVerb,
    'coverage': coverage,
    'errand': errand,
    'runner': runner,
    'outsider': outsider,
    'expense': expense,
    'expensePlural': expensePlural,
    'attendingOnly': attendingOnly,
    'tagline': tagline,
    'taglines': taglines,
    'arrival': arrival,
    'advisorName': advisorName,
  };
}

class PackPalette {
  final Color primary,
      primaryDark,
      primaryDeep,
      primaryDeepDark,
      primarySoft,
      primarySoftDark,
      primaryFixed;
  final Color accent,
      accentDark,
      accentFill,
      accentSoft,
      accentSoftDark,
      onAccent,
      onAccentDark,
      secondary,
      secondaryDark;

  const PackPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryDeep,
    required this.primaryDeepDark,
    required this.primarySoft,
    required this.primarySoftDark,
    required this.primaryFixed,
    required this.accent,
    required this.accentDark,
    required this.accentFill,
    required this.accentSoft,
    required this.accentSoftDark,
    required this.onAccent,
    required this.onAccentDark,
    required this.secondary,
    required this.secondaryDark,
  });

  /// Derives the full ramp from two seeds.
  ///
  /// Every role is anchored to a target *relative luminance* — the quantity
  /// WCAG contrast is computed from — not to an HSL lightness. HSL lightness
  /// lies: at the same L a yellow is far brighter than a blue, so a gold tile
  /// came out washed while a copper one came out heavy, and text contrast
  /// swung with whichever hue you picked. Anchoring on luminance means both
  /// packs land at the same perceived weight in every role, and the contrast
  /// ratios the tests assert are properties of these targets — they hold for
  /// any seed, not just the two that ship.
  ///
  /// The seed contributes hue and saturation only; the role multiplies the
  /// saturation (washes are muted, fills are full) and the target sets how
  /// dark it lands.
  factory PackPalette.seeded({required Color primary, required Color accent}) {
    return PackPalette(
      // Buttons and links: dark enough for white text, distinct on the page.
      primary: _at(primary, luminance: 0.09, saturation: 1.0),
      primaryDark: _at(primary, luminance: 0.30, saturation: 0.90),
      // Filled tiles that always carry white text.
      primaryDeep: _at(primary, luminance: 0.045, saturation: 1.0),
      primaryDeepDark: _at(primary, luminance: 0.10, saturation: 0.95),
      // The "this row is yours" wash — body copy has to read on it.
      primarySoft: _at(primary, luminance: 0.88, saturation: 0.50),
      primarySoftDark: _at(primary, luminance: 0.02, saturation: 0.70),
      // Small filled elements under ink text: mid-light, no longer pastel.
      primaryFixed: _at(primary, luminance: 0.45, saturation: 0.80),
      // Accent as a text/icon colour on the page, either mode.
      accent: _at(accent, luminance: 0.11, saturation: 0.90),
      accentDark: _at(accent, luminance: 0.36, saturation: 0.95),
      // The solid accent tile. 0.30 against onAccent's 0.025 is 4.7:1 for
      // every hue — the ratio is fixed by the targets, not by the colour.
      accentFill: _at(accent, luminance: 0.30, saturation: 0.95),
      accentSoft: _at(accent, luminance: 0.85, saturation: 0.90),
      accentSoftDark: _at(accent, luminance: 0.04, saturation: 0.80),
      onAccent: _at(accent, luminance: 0.025, saturation: 0.85),
      onAccentDark: AppColors.white,
      secondary: _at(primary, luminance: 0.45, saturation: 0.80),
      secondaryDark: _at(primary, luminance: 0.10, saturation: 0.95),
    );
  }

  /// The colour with [seed]'s hue, [seed]'s saturation × [saturation], at
  /// exactly the requested relative [luminance].
  ///
  /// Luminance rises monotonically with HSL lightness for a fixed hue and
  /// saturation, so a bisection on lightness finds it; 24 steps is well past
  /// 8-bit colour precision.
  static Color _at(
    Color seed, {
    required double luminance,
    required double saturation,
  }) {
    final hsl = HSLColor.fromColor(seed);
    final sat = (hsl.saturation * saturation).clamp(0.0, 1.0);
    final base = hsl.withSaturation(sat);
    var lo = 0.0;
    var hi = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (relativeLuminance(base.withLightness(mid).toColor()) < luminance) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return base.withLightness((lo + hi) / 2).toColor();
  }

  /// WCAG 2.1 relative luminance — the same formula the contrast tests use,
  /// exposed so they can assert the anchoring rather than re-derive it.
  static double relativeLuminance(Color c) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  List<Color> get swatch => [primaryDeep, primary, accentFill, primaryFixed];

  /// The Bite Size ramp, derived from its two seeds in [AppColors] — also the
  /// default for any pack that names no palette of its own.
  static PackPalette get biteSize => PackPalette.seeded(
    primary: AppColors.biteSizePrimary,
    accent: AppColors.biteSizeAccent,
  );

  static Color get _fallbackPrimary => AppColors.biteSizePrimary;
  static Color get _fallbackAccent => AppColors.biteSizeAccent;

  static PackPalette fromJson(Map<String, dynamic> json) {
    Color parse(Object? v, Color fallback) {
      if (v is int) return Color(v);
      if (v is String) {
        final hex = v.replaceFirst('#', '').padLeft(8, 'F');
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed != null) return Color(parsed);
      }
      return fallback;
    }

    return PackPalette.seeded(
      primary: parse(json['primary'], _fallbackPrimary),
      accent: parse(json['accent'], _fallbackAccent),
    );
  }

  Map<String, dynamic> toJson() => {
    'primary': primary.value,
    'accent': accentFill.value,
  };
}

enum PackRecurrence {
  daily,
  adhoc;

  static PackRecurrence fromString(String? value) => PackRecurrence.values
      .firstWhere((r) => r.name == value, orElse: () => PackRecurrence.daily);
}

class ActivityPack {
  final String id;
  final PackModules modules;
  final PackLabels labels;

  /// Stored ramp; null means "use the default". Nullable because the default
  /// is derived through getters at runtime and so can't be a const parameter
  /// default — see [palette].
  final PackPalette? _palette;
  final PackShape shape;
  final Currency currency;
  final PackRecurrence recurrence;
  final String advisorBrief;
  final List<String> externalRunners;

  const ActivityPack({
    required this.id,
    this.modules = const PackModules(),
    this.labels = const PackLabels(),
    PackPalette? palette,
    this.shape = PackShape.standard,
    this.currency = Currency.pkr,
    this.recurrence = PackRecurrence.daily,
    this.advisorBrief = '',
    this.externalRunners = const [],
  }) : _palette = palette;

  /// The brand ramp. Falls back to the Bite Size ramp.
  PackPalette get palette => _palette ?? PackPalette.biteSize;

  /// The prefix this pack's sessions carry. Empty for the lunch pack, which
  /// predates packs: its rows are bare dates, and they stay that way so
  /// nothing already in the database moves.
  String get sessionPrefix => id == 'office_lunch' ? '' : '$id:';

  /// The `sessions.id` for [day] under this pack — `2026-09-14` for lunch,
  /// `ground_booking:2026-09-14` for cricket.
  ///
  /// This is what gives each pack its own roster, orders, runner and reset
  /// on the same calendar day. Two packs on one device used to share the
  /// day's row because the key was the date alone; a reset under one wiped
  /// the other. `ensure_session()` in Postgres reads the date back off the end
  /// of the id, so nothing else about the schema changes.
  String sessionIdFor(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$sessionPrefix$y-$m-$d';
  }

  /// The bare `yyyy-MM-dd` behind a session id, whichever pack made it.
  static String dateOfSession(String sessionId) =>
      sessionId.contains(':') ? sessionId.split(':').last : sessionId;

  factory ActivityPack.fromJson(Map<String, dynamic> json) => ActivityPack(
    id: (json['id'] as String?) ?? 'custom',
    modules: PackModules.fromJson(
      Map<String, dynamic>.from(json['modules'] as Map? ?? const {}),
    ).normalised,
    labels: PackLabels.fromJson(
      Map<String, dynamic>.from(json['labels'] as Map? ?? const {}),
    ),
    palette: json['palette'] is Map
        ? PackPalette.fromJson(
            Map<String, dynamic>.from(json['palette'] as Map),
          )
        : PackPalette.biteSize,
    shape: json['shape'] is Map
        ? PackShape.fromJson(Map<String, dynamic>.from(json['shape'] as Map))
        : PackShape.standard,
    currency: Currency.fromCode(json['currency'] as String?),
    recurrence: PackRecurrence.fromString(json['recurrence'] as String?),
    advisorBrief: (json['advisorBrief'] as String?) ?? '',
    externalRunners:
        (json['externalRunners'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'modules': modules.toJson(),
    'labels': labels.toJson(),
    'palette': palette.toJson(),
    'shape': shape.toJson(),
    'currency': currency.code,
    'recurrence': recurrence.name,
    'advisorBrief': advisorBrief,
    'externalRunners': externalRunners,
  };
}

class Packs {
  const Packs._();

  static final officeLunch = ActivityPack(
    id: 'office_lunch',
    modules: const PackModules(
      roster: true,
      coverage: false,
      units: true,
      errand: true,
      advisor: true,
      // The Ping is a lunch thing: one person gets nagged to come and sort
      // the food out. The flag that names them is project-wide, so without
      // this switch every pack would show the same button.
      ping: true,
    ),
    labels: const PackLabels(
      activityName: 'Bite Size',
      sessionNoun: 'lunch',
      unit: 'roti',
      unitPlural: 'rotis',
      contribution: 'dish',
      contributionVerb: 'brought',
      coverage: 'portions',
      errand: 'tandoor run',
      runner: 'runner',
      outsider: 'office boy',
      expense: 'shared meal',
      expensePlural: 'shared meals',
      attendingOnly: 'Eating only',
      tagline: 'OFFICE LUNCH LOGISTICS, SORTED BEFORE NOON',
      taglines: [
        'Chomp! 🥖',
        'Yum! 😋',
        'Nom Nom! 🥨',
        'Crunch! 🌾',
        'Garlic Naan! 🧄',
        'Tandoori Fresh! 🔥',
        'Bite Size! 🥪',
        'Roti Squad! 👥',
      ],
      arrival: 'Food arrived',
      advisorName: 'Chef AI',
    ),
    palette: PackPalette.biteSize,
    currency: Currency.pkr,
    recurrence: PackRecurrence.daily,
    advisorBrief:
        'Act as an expert office lunch coordinator. Judge whether the food brought will comfortably feed everyone eating. If it will, say so plainly. If it will not, name what to order from outside to close the gap — more bread, or a dish like Karahi or Daal.',
    externalRunners: const ['Office Boy', 'Rana'],
  );

  static final groundBooking = ActivityPack(
    id: 'ground_booking',
    modules: const PackModules(units: true, errand: true),
    labels: const PackLabels(
      activityName: 'Ground Booking',
      sessionNoun: 'match',
      unit: 'hour',
      unitPlural: 'hours',
      contribution: 'gear',
      contributionVerb: 'brought',
      coverage: 'players',
      errand: 'ground booking',
      runner: 'payer',
      outsider: 'groundsman',
      expense: 'shared cost',
      expensePlural: 'shared costs',
      tagline: 'BOOK THE GROUND, SPLIT THE BILL',
      arrival: 'Ground booked',
    ),
    palette: PackPalette.seeded(
      primary: AppColors.groundPrimary,
      accent: AppColors.groundAccent,
    ),
    externalRunners: const ['Groundsman'],
    currency: Currency.pkr,
    recurrence: PackRecurrence.adhoc,
  );

  static final all = [officeLunch, groundBooking];
  static final fallback = officeLunch;
  static ActivityPack byId(String? id) => byIdOrNull(id) ?? fallback;

  static ActivityPack? byIdOrNull(String? id) {
    if (id == null || id.isEmpty) return null;
    final wanted = id.trim().toLowerCase();
    for (final p in all) {
      if (p.id == wanted) return p;
    }
    return null;
  }
}

class PackService extends ChangeNotifier {
  static final PackService instance = PackService._internal();
  factory PackService() => instance;
  PackService._internal();
  static const _prefsKey = 'activity_pack_id';

  ActivityPack _pack = Packs.fallback;
  ActivityPack get pack => _pack;

  static PackLabels get labels => instance._pack.labels;
  static PackModules get modules => instance._pack.modules;
  static PackPalette get palette => instance._pack.palette;
  static PackShape get shape => instance._pack.shape;
  static Currency get currency => instance._pack.currency;

  /// Today's `sessions.id` for the running pack. See
  /// [ActivityPack.sessionIdFor].
  static String todaySessionId() => instance._pack.sessionIdFor(DateTime.now());

  /// Session id for any day under the running pack.
  static String sessionIdFor(DateTime day) => instance._pack.sessionIdFor(day);

  List<ActivityPack> get selectable => Packs.all;

  Future<void> load() async {
    final saved = await _readSavedId();
    if (saved != null) {
      final match = Packs.byIdOrNull(saved);
      if (match != null) {
        _pack = match;
        debugPrint('📦 [PACK] Restored "${_pack.id}" from this device');
        notifyListeners();
        return;
      }
      debugPrint('⚠️ [PACK] Saved pack "$saved" no longer exists — ignoring');
    }
    loadFromEnv();
  }

  void loadFromEnv() {
    final inline = dotenv.env['ACTIVITY_PACK_JSON'];
    if (inline != null && inline.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(inline) as Map<String, dynamic>;
        _pack = ActivityPack.fromJson(decoded);
        debugPrint('📦 [PACK] Loaded inline pack "${_pack.id}"');
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('⚠️ [PACK] ACTIVITY_PACK_JSON is not valid JSON: $e');
      }
    }

    final id = dotenv.env['ACTIVITY_PACK'];
    _pack = Packs.byId(id);
    if (id != null && id.isNotEmpty && _pack.id != id.trim().toLowerCase()) {
      debugPrint('⚠️ [PACK] Unknown pack "$id" — falling back to ${_pack.id}');
    } else {
      debugPrint('📦 [PACK] Running as "${_pack.id}"');
    }
    notifyListeners();
  }

  Future<void> select(ActivityPack next) async {
    if (next.id == _pack.id) return;
    debugPrint('📦 [PACK] Switching ${_pack.id} → ${next.id}');
    _pack = next;
    notifyListeners();
    await _saveId(next.id);
  }

  Future<void> resetToEnv() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint('⚠️ [PACK] Could not clear saved pack: $e');
    }
    loadFromEnv();
  }

  Future<String?> _readSavedId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefsKey);
      return (id == null || id.isEmpty) ? null : id;
    } catch (e) {
      debugPrint('⚠️ [PACK] Could not read saved pack: $e');
      return null;
    }
  }

  Future<void> _saveId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, id);
    } catch (e) {
      debugPrint('⚠️ [PACK] Could not save pack "$id": $e');
    }
  }
}
