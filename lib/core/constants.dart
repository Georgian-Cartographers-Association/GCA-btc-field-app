import 'package:latlong2/latlong.dart';

class AppConstants {
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String topoTileUrl =
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  static const List<String> topoSubdomains = ['a', 'b', 'c'];

  // Expedition code characters — ambiguous chars (0/O, 1/I/L) excluded
  static const String expeditionCodeChars =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int expeditionCodeLength = 6;

  // Georgian month abbreviations (index 0 = January)
  static const List<String> georgianMonths = [
    'იანვ', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
    'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ',
  ];

  // Georgia center
  static const LatLng georgiaCenter = LatLng(42.315407, 43.356892);
  static const double defaultZoom = 7.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;

  static const String pdfAssetPath = 'assets/pdf/methodology.pdf';
  static const String geojsonAssetPath = 'assets/geojson/georgia.geojson';
  static const String regionsGeojsonPath = 'assets/geojson/Regions.geojson';
  static const String municipalitiesGeojsonPath = 'assets/geojson/Municipalities.geojson';

  static const String prefRecords = 'btk_records';
  static const String prefTheme = 'theme_mode';
  static const String prefLocale = 'locale';
  static const String prefEmail = 'default_email';    // legacy — migration only
  static const String prefEmails = 'emails_list';     // new JSON list
  static const String prefPdfPage = 'pdf_page';
  static const String prefShowOsm = 'layer_osm';
  static const String prefShowTopo = 'layer_topo';
  static const String prefShowBoundary = 'layer_boundary';
  static const String prefShowRegions = 'layer_regions';
  static const String prefShowMunicipalities = 'layer_municipalities';
  static const String prefShowPoints = 'layer_points';
}
