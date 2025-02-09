library custom_suncalc;

import 'dart:math' as math;

// llm generated suncalc, all the dart libraries had bugs / old.
// will make this a proper library later, famous last words

class SunCalc {
  // Constants
  static const double _pi = math.pi;
  static const double _rad = _pi / 180.0;
  static final double _dayMs = 1000 * 60 * 60 * 24;
  static final double _j1970 = 2440588;
  static final double _j2000 = 2451545;
  static final double _e = _rad * 23.4397; // obliquity of the Earth

  // Date/Time Conversions
  static double _toJulian(DateTime date) =>
      date.millisecondsSinceEpoch / _dayMs - 0.5 + _j1970;
  static DateTime _fromJulian(double j) => DateTime.fromMillisecondsSinceEpoch(
      ((j + 0.5 - _j1970) * _dayMs).round());
  static double _toDays(DateTime date) => _toJulian(date) - _j2000;

  // General Calculations
  static double _rightAscension(double l, double b) => math.atan2(
      math.sin(l) * math.cos(_e) - math.tan(b) * math.sin(_e), math.cos(l));
  static double _declination(double l, double b) => math.asin(
      math.sin(b) * math.cos(_e) + math.cos(b) * math.sin(_e) * math.sin(l));
  static double _azimuth(double h, double phi, double dec) => math.atan2(
      math.sin(h), math.cos(h) * math.sin(phi) - math.tan(dec) * math.cos(phi));
  static double _altitude(double h, double phi, double dec) =>
      math.asin(math.sin(phi) * math.sin(dec) +
          math.cos(phi) * math.cos(dec) * math.cos(h));
  static double _siderealTime(double d, double lw) =>
      _rad * (280.16 + 360.9856235 * d) - lw;
  static double _astroRefraction(double h) {
    double h0 = (h < 0) ? 0 : h;
    return 0.0002967 / math.tan(h0 + 0.00312536 / (h0 + 0.08901179));
  }

  // Sun Calculations
  static double _solarMeanAnomaly(double d) =>
      _rad * (357.5291 + 0.98560028 * d);
  static double _eclipticLongitude(double m) {
    double c = _rad *
        (1.9148 * math.sin(m) +
            0.02 * math.sin(2 * m) +
            0.0003 * math.sin(3 * m));
    double p = _rad * 102.9372;
    return m + c + p + _pi;
  }

  static Map<String, double> _sunCoords(double d) {
    double m = _solarMeanAnomaly(d);
    double l = _eclipticLongitude(m);
    return {
      'dec': _declination(l, 0),
      'ra': _rightAscension(l, 0),
    };
  }

  // Public API: Sun Position
  static Map<String, double> getPosition(
      DateTime date, double lat, double lng) {
    double lw = _rad * -lng;
    double phi = _rad * lat;
    double d = _toDays(date);
    Map<String, double> c = _sunCoords(d);
    double h = _siderealTime(d, lw) - c['ra']!;
    return {
      'azimuth': _azimuth(h, phi, c['dec']!),
      'altitude': _altitude(h, phi, c['dec']!),
    };
  }

  // Sun Times Configuration
  static final List<List<dynamic>> _times = [
    [-0.833, 'sunrise', 'sunset'],
    [-0.3, 'sunriseEnd', 'sunsetStart'],
    [-6, 'dawn', 'dusk'],
    [-12, 'nauticalDawn', 'nauticalDusk'],
    [-18, 'nightEnd', 'night'],
    [6, 'goldenHourEnd', 'goldenHour']
  ];

  // Sun Times Calculations
  static final double _j0 = 0.0009;
  static double _julianCycle(double d, double lw) =>
      (d - _j0 - lw / (2 * _pi)).roundToDouble();
  static double _approxTransit(double ht, double lw, double n) =>
      _j0 + (ht + lw) / (2 * _pi) + n;
  static double _solarTransitJ(double ds, double m, double l) =>
      _j2000 + ds + 0.0053 * math.sin(m) - 0.0069 * math.sin(2 * l);
  static double _hourAngle(double h, double phi, double d) =>
      math.acos((math.sin(h) - math.sin(phi) * math.sin(d)) /
          (math.cos(phi) * math.cos(d)));
  static double _getSetJ(double h, double lw, double phi, double dec, double n,
      double m, double l) {
    double w = _hourAngle(h, phi, dec);
    double a = _approxTransit(w, lw, n);
    return _solarTransitJ(a, m, l);
  }

  // Public API: Sun Times
  static Map<String, DateTime> getTimes(DateTime date, double lat, double lng,
      [double? height]) {
    height ??= 0;

    double lw = _rad * -lng;
    double phi = _rad * lat;
    double dh = -2.076 * math.sqrt(height) / 60 * _rad; // Observer angle
    double d = _toDays(date);
    double n = _julianCycle(d, lw);
    double ds = _approxTransit(0, lw, n);
    double m = _solarMeanAnomaly(ds);
    double l = _eclipticLongitude(m);
    double dec = _declination(l, 0);
    double jNoon = _solarTransitJ(ds, m, l);

    Map<String, DateTime> result = {
      'solarNoon': _fromJulian(jNoon),
      'nadir': _fromJulian(jNoon - 0.5),
    };

    for (List<dynamic> time in _times) {
      double h0 = (time[0] + dh) * _rad;
      double jSet = _getSetJ(h0, lw, phi, dec, n, m, l);
      double jRise = jNoon - (jSet - jNoon);
      result[time[1]] = _fromJulian(jRise);
      result[time[2]] = _fromJulian(jSet);
    }

    return result;
  }

  // Public API: Nadir
  static DateTime getNadir(DateTime date, double lat, double lng) {
    double lw = _rad * -lng;
    double d = _toDays(date);
    double n = _julianCycle(d, lw);
    double ds = _approxTransit(0, lw, n);
    double m = _solarMeanAnomaly(ds);
    double l = _eclipticLongitude(m);
    double jNoon = _solarTransitJ(ds, m, l);
    return _fromJulian(jNoon - 0.5);
  }

  // Moon Calculations
  static Map<String, double> _moonCoords(double d) {
    double l = _rad * (218.316 + 13.176396 * d);
    double m = _rad * (134.963 + 13.064993 * d);
    double f = _rad * (93.272 + 13.229350 * d);
    double lon = l + _rad * 6.289 * math.sin(m);
    double lat = _rad * 5.128 * math.sin(f);
    double dt = 385001 - 20905 * math.cos(m);
    return {
      'ra': _rightAscension(lon, lat),
      'dec': _declination(lon, lat),
      'dist': dt,
    };
  }

  // Public API: Moon Position
  static Map<String, double> getMoonPosition(
      DateTime date, double lat, double lng) {
    double lw = _rad * -lng;
    double phi = _rad * lat;
    double d = _toDays(date);
    Map<String, double> c = _moonCoords(d);
    double h = _siderealTime(d, lw) - c['ra']!;
    double alt = _altitude(h, phi, c['dec']!);
    double pa = math.atan2(
        math.sin(h),
        math.tan(phi) * math.cos(c['dec']!) -
            math.sin(c['dec']!) * math.cos(h));

    alt = alt + _astroRefraction(alt);
    return {
      'azimuth': _azimuth(h, phi, c['dec']!),
      'altitude': alt,
      'distance': c['dist']!,
      'parallacticAngle': pa,
    };
  }

  // Public API: Moon Illumination
  static Map<String, double> getMoonIllumination(DateTime date) {
    final d = _toDays(date);
    final s = _sunCoords(d);
    final m = _moonCoords(d);

    const sdist = 149598000; // Earth-Sun distance

    final phi = math.acos(math.sin(s['dec']!) * math.sin(m['dec']!) +
        math.cos(s['dec']!) *
            math.cos(m['dec']!) *
            math.cos(s['ra']! - m['ra']!));
    final inc =
        math.atan2(sdist * math.sin(phi), m['dist']! - sdist * math.cos(phi));
    final angle = math.atan2(
        math.cos(s['dec']!) * math.sin(s['ra']! - m['ra']!),
        math.sin(s['dec']!) * math.cos(m['dec']!) -
            math.cos(s['dec']!) *
                math.sin(m['dec']!) *
                math.cos(s['ra']! - m['ra']!));

    return {
      'fraction': (1 + math.cos(inc)) / 2,
      'phase': 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / _pi,
      'angle': angle,
    };
  }

  // Public API: Moon Times
  static Map<String, dynamic> getMoonTimes(
      DateTime date, double lat, double lng,
      {bool inUtc = false}) {
    DateTime t = inUtc
        ? DateTime.utc(date.year, date.month, date.day)
        : DateTime(date.year, date.month, date.day);

    const hc = 0.133 * _rad;
    double h0 = getMoonPosition(t, lat, lng)['altitude']! - hc;

    double? rise;
    double? set;
    bool? alwaysUp;
    bool? alwaysDown;
    double xe = 0.0; // Initialize xe
    double ye = 0.0; // Initialize ye

    for (int i = 1; i <= 24; i += 2) {
      final h1 =
          getMoonPosition(_hoursLater(t, i.toDouble()), lat, lng)['altitude']! -
              hc; // Convert i to double
      final h2 = getMoonPosition(
              _hoursLater(t, (i + 1).toDouble()), lat, lng)['altitude']! -
          hc; // Convert i+1 to double

      final a = (h0 + h2) / 2 - h1;
      final b = (h2 - h0) / 2;
      xe = -b / (2 * a); //now it is assigned
      ye = (a * xe + b) * xe + h1; //now it is assigned
      final d = b * b - 4 * a * h1;
      int roots = 0;

      if (d >= 0) {
        final dx = math.sqrt(d) / (a.abs() * 2);
        double x1 = xe - dx;
        double x2 = xe + dx;
        if (x1.abs() <= 1) roots++;
        if (x2.abs() <= 1) roots++;
        if (x1 < -1) x1 = x2;

        if (roots == 1) {
          if (h0 < 0) {
            rise = i + x1;
          } else {
            set = i + x1;
          }
        } else if (roots == 2) {
          rise = i + (ye < 0 ? x2 : x1);
          set = i + (ye < 0 ? x1 : x2);
        }

        if (rise != null && set != null) break;
      }

      h0 = h2;
    }

    if (rise == null && set == null) {
      if (ye > 0) {
        alwaysUp = true;
      } else {
        alwaysDown = true;
      }
    }

    return {
      'rise': rise == null ? null : _hoursLater(t, rise), //rise is double
      'set': set == null ? null : _hoursLater(t, set), //set is double
      'alwaysUp': alwaysUp ?? false,
      'alwaysDown': alwaysDown ?? false,
    };
  }

  static DateTime _hoursLater(DateTime date, double h) {
    return date.add(Duration(milliseconds: (h * 60 * 60 * 1000).round()));
  }

  // Helper function to add a custom time
  static void addTime(double angle, String riseName, String setName) {
    _times.add([angle, riseName, setName]);
  }
}
