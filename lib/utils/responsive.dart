import 'package:flutter/material.dart';

/// Breakpoints (width in logical pixels)
///   xs  : < 360     → very small phones
///   sm  : 360-599   → normal phones (iPhone 14, Pixel)
///   md  : 600-899   → small tablets / phone landscape
///   lg  : 900-1199  → tablets (iPad, Tab S)
///   xl  : >= 1200   → large tablets / desktop

class Responsive {
  final BuildContext _ctx;
  const Responsive._(this._ctx);

  static Responsive of(BuildContext ctx) => Responsive._(ctx);

  double get screenWidth  => MediaQuery.sizeOf(_ctx).width;
  double get screenHeight => MediaQuery.sizeOf(_ctx).height;
  bool   get isLandscape  => MediaQuery.orientationOf(_ctx) == Orientation.landscape;

  bool get isXSmall  => screenWidth < 360;
  bool get isSmall   => screenWidth >= 360  && screenWidth < 600;
  bool get isMedium  => screenWidth >= 600  && screenWidth < 900;
  bool get isLarge   => screenWidth >= 900  && screenWidth < 1200;
  bool get isXLarge  => screenWidth >= 1200;
  bool get isMobile  => screenWidth < 600;
  bool get isTablet  => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  T val<T>({T? xs, required T sm, T? md, T? lg, T? xl}) {
    if (isXLarge)  return xl ?? lg ?? md ?? sm;
    if (isLarge)   return lg ?? md ?? sm;
    if (isMedium)  return md ?? sm;
    if (isXSmall)  return xs ?? sm;
    return sm;
  }

  double get pagePaddingH => val(xs: 12.0, sm: 16.0, md: 24.0, lg: 32.0);
  double get sectionSpacing => val(xs: 20.0, sm: 28.0, md: 36.0, lg: 44.0);

  double get bannerHeight {
    if (isLandscape && isMobile) return screenHeight * 0.60;
    if (isMedium) return screenHeight * 0.42;
    if (isLarge || isXLarge) return screenHeight * 0.40;
    return screenHeight * 0.38;
  }

  double get categoryCardHeight => val(xs: 140.0, sm: 176.0, md: 160.0, lg: 180.0);
  double get categoryCardWidth  => val(xs: 110.0, sm: 144.0, md: 140.0, lg: 160.0);

  int get productGridColumns {
    if (isXLarge)  return 5;
    if (isLarge)   return 4;
    if (isMedium || (isLandscape && isMobile)) return 3;
    return 2;
  }

  double get productGridAspectRatio {
    if (isLandscape && isMobile) return 0.65;
    if (isMedium) return 0.58;
    if (isLarge)  return 0.56;
    return 0.52;
  }

  double get formMaxWidth => val(sm: 420.0, md: 480.0, lg: 520.0, xl: 560.0);
  double get cardRadius   => val(xs: 12.0, sm: 16.0, md: 18.0, lg: 20.0);

  double get fontXs => val(xs: 9.0,  sm: 10.0, md: 11.0, lg: 12.0);
  double get fontSm => val(xs: 11.0, sm: 12.0, md: 13.0, lg: 14.0);
  double get fontMd => val(xs: 13.0, sm: 14.0, md: 15.0, lg: 16.0);
  double get fontLg => val(xs: 15.0, sm: 16.0, md: 18.0, lg: 20.0);
  double get fontXl => val(xs: 18.0, sm: 22.0, md: 26.0, lg: 30.0);
  double get fontH1 => val(xs: 22.0, sm: 28.0, md: 32.0, lg: 36.0);

  double get iconSm    => val(xs: 16.0, sm: 18.0, md: 20.0, lg: 22.0);
  double get iconMd    => val(xs: 20.0, sm: 22.0, md: 24.0, lg: 26.0);
  double get spacingXs => val(xs: 4.0,  sm: 6.0,  md: 8.0,  lg: 10.0);
  double get spacingSm => val(xs: 8.0,  sm: 10.0, md: 12.0, lg: 14.0);
  double get spacingMd => val(xs: 12.0, sm: 16.0, md: 20.0, lg: 24.0);
  double get spacingLg => val(xs: 20.0, sm: 28.0, md: 32.0, lg: 40.0);
}
