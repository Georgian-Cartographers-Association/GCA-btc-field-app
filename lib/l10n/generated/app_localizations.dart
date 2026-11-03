import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ka.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ka'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ საველე აპლიკაცია'**
  String get appTitle;

  /// No description provided for @mapTitle.
  ///
  /// In ka, this message translates to:
  /// **'რუკა'**
  String get mapTitle;

  /// No description provided for @addPoint.
  ///
  /// In ka, this message translates to:
  /// **'წერტილის დამატება'**
  String get addPoint;

  /// No description provided for @myLocation.
  ///
  /// In ka, this message translates to:
  /// **'ჩემი მდებარეობა'**
  String get myLocation;

  /// No description provided for @layers.
  ///
  /// In ka, this message translates to:
  /// **'შრეები'**
  String get layers;

  /// No description provided for @methodology.
  ///
  /// In ka, this message translates to:
  /// **'მეთოდური მითითება'**
  String get methodology;

  /// No description provided for @records.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები'**
  String get records;

  /// No description provided for @settings.
  ///
  /// In ka, this message translates to:
  /// **'პარამეტრები'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In ka, this message translates to:
  /// **'შენახვა'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ka, this message translates to:
  /// **'გაუქმება'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა'**
  String get delete;

  /// No description provided for @send.
  ///
  /// In ka, this message translates to:
  /// **'გაგზავნა'**
  String get send;

  /// No description provided for @email.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტა'**
  String get email;

  /// No description provided for @copyToClipboard.
  ///
  /// In ka, this message translates to:
  /// **'კოპირება'**
  String get copyToClipboard;

  /// No description provided for @language.
  ///
  /// In ka, this message translates to:
  /// **'ენა'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ka, this message translates to:
  /// **'ფონი'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In ka, this message translates to:
  /// **'ღია'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ka, this message translates to:
  /// **'მუქი'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In ka, this message translates to:
  /// **'სისტემა'**
  String get systemTheme;

  /// No description provided for @layerOsm.
  ///
  /// In ka, this message translates to:
  /// **'OpenStreetMap'**
  String get layerOsm;

  /// No description provided for @layerTopo.
  ///
  /// In ka, this message translates to:
  /// **'OpenTopoMap'**
  String get layerTopo;

  /// No description provided for @layerBoundary.
  ///
  /// In ka, this message translates to:
  /// **'საქართველოს საზღვარი'**
  String get layerBoundary;

  /// No description provided for @layerPoints.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ წერტილები'**
  String get layerPoints;

  /// No description provided for @btkFormTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ-ის აღწერა'**
  String get btkFormTitle;

  /// No description provided for @btkId.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ID'**
  String get btkId;

  /// No description provided for @date.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი'**
  String get date;

  /// No description provided for @location.
  ///
  /// In ka, this message translates to:
  /// **'ადგილმდებარეობა'**
  String get location;

  /// No description provided for @coordinates.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატები'**
  String get coordinates;

  /// No description provided for @latitude.
  ///
  /// In ka, this message translates to:
  /// **'განედი (lat)'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In ka, this message translates to:
  /// **'გრძედი (lon)'**
  String get longitude;

  /// No description provided for @useGps.
  ///
  /// In ka, this message translates to:
  /// **'GPS-ით დადგენა'**
  String get useGps;

  /// No description provided for @enterManually.
  ///
  /// In ka, this message translates to:
  /// **'ხელით შეყვანა'**
  String get enterManually;

  /// No description provided for @physGeoDesc.
  ///
  /// In ka, this message translates to:
  /// **'ფიზიკურ-გეოგრაფიული დახასიათება'**
  String get physGeoDesc;

  /// No description provided for @geologicalFormation.
  ///
  /// In ka, this message translates to:
  /// **'გეოლოგიური ფორმაცია'**
  String get geologicalFormation;

  /// No description provided for @reliefType.
  ///
  /// In ka, this message translates to:
  /// **'რელიეფის ტიპი'**
  String get reliefType;

  /// No description provided for @morphologicalDesc.
  ///
  /// In ka, this message translates to:
  /// **'მორფოლოგიური დახასიათება'**
  String get morphologicalDesc;

  /// No description provided for @geomorphProcesses.
  ///
  /// In ka, this message translates to:
  /// **'თანამედროვე გეომორფოლოგიური პროცესები'**
  String get geomorphProcesses;

  /// No description provided for @migrationRegime.
  ///
  /// In ka, this message translates to:
  /// **'მიგრაციის რეჟიმი'**
  String get migrationRegime;

  /// No description provided for @moistureDegree.
  ///
  /// In ka, this message translates to:
  /// **'დატენიანების ხარისხი'**
  String get moistureDegree;

  /// No description provided for @vegetation.
  ///
  /// In ka, this message translates to:
  /// **'მცენარეულობა'**
  String get vegetation;

  /// No description provided for @vegTier.
  ///
  /// In ka, this message translates to:
  /// **'იარუსი'**
  String get vegTier;

  /// No description provided for @vegHeight.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლე'**
  String get vegHeight;

  /// No description provided for @vegDensity.
  ///
  /// In ka, this message translates to:
  /// **'სიმძლ.'**
  String get vegDensity;

  /// No description provided for @vegPhenophase.
  ///
  /// In ka, this message translates to:
  /// **'ფენოფაზა'**
  String get vegPhenophase;

  /// No description provided for @vegSpecies.
  ///
  /// In ka, this message translates to:
  /// **'სახეობა'**
  String get vegSpecies;

  /// No description provided for @addRow.
  ///
  /// In ka, this message translates to:
  /// **'სტრიქონის დამატება'**
  String get addRow;

  /// No description provided for @removeRow.
  ///
  /// In ka, this message translates to:
  /// **'სტრიქონის წაშლა'**
  String get removeRow;

  /// No description provided for @soil.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგი'**
  String get soil;

  /// No description provided for @soilTypeName.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის ტიპის სახელწოდება'**
  String get soilTypeName;

  /// No description provided for @soilProfileDesc.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის პროფილის მორფოლოგიური დახასიათება'**
  String get soilProfileDesc;

  /// No description provided for @soilHorizons.
  ///
  /// In ka, this message translates to:
  /// **'გენეტიკური ჰორიზონტები'**
  String get soilHorizons;

  /// No description provided for @soilHorizonName.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტი'**
  String get soilHorizonName;

  /// No description provided for @soilHorizonDesc.
  ///
  /// In ka, this message translates to:
  /// **'დახასიათება (ფ., მ.შ., სტ., ფ., სმ., ახ., ხ., ფ., ტ., ჰ., ქ.საზ.)'**
  String get soilHorizonDesc;

  /// No description provided for @geohorizonIndex.
  ///
  /// In ka, this message translates to:
  /// **'გეოჰორიზონტის ინდექსი'**
  String get geohorizonIndex;

  /// No description provided for @soilSurfaceFormation.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგ ზედაპირული ფორმაციის ტიპი'**
  String get soilSurfaceFormation;

  /// No description provided for @geomasses.
  ///
  /// In ka, this message translates to:
  /// **'გეომასების კვლევა'**
  String get geomasses;

  /// No description provided for @geomassSection.
  ///
  /// In ka, this message translates to:
  /// **'სექცია'**
  String get geomassSection;

  /// No description provided for @geomassDepth.
  ///
  /// In ka, this message translates to:
  /// **'სიღრმე (სმ)'**
  String get geomassDepth;

  /// No description provided for @pedomass.
  ///
  /// In ka, this message translates to:
  /// **'პედომასა'**
  String get pedomass;

  /// No description provided for @lithomass.
  ///
  /// In ka, this message translates to:
  /// **'ლითომასა'**
  String get lithomass;

  /// No description provided for @hydromass.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდრომასა'**
  String get hydromass;

  /// No description provided for @phytomass.
  ///
  /// In ka, this message translates to:
  /// **'ფიტომასა'**
  String get phytomass;

  /// No description provided for @bulkDensity.
  ///
  /// In ka, this message translates to:
  /// **'მოც.წ.'**
  String get bulkDensity;

  /// No description provided for @quantity.
  ///
  /// In ka, this message translates to:
  /// **'რაოდ.'**
  String get quantity;

  /// No description provided for @density.
  ///
  /// In ka, this message translates to:
  /// **'სიმკვ.'**
  String get density;

  /// No description provided for @moisture.
  ///
  /// In ka, this message translates to:
  /// **'სინოტ.'**
  String get moisture;

  /// No description provided for @wet.
  ///
  /// In ka, this message translates to:
  /// **'სველი'**
  String get wet;

  /// No description provided for @dry.
  ///
  /// In ka, this message translates to:
  /// **'მშრალი'**
  String get dry;

  /// No description provided for @treeVegTaxation.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეულობის ტაქსაცია'**
  String get treeVegTaxation;

  /// No description provided for @experimentPlotSize.
  ///
  /// In ka, this message translates to:
  /// **'ექსპ. ნაკვ. ზომა'**
  String get experimentPlotSize;

  /// No description provided for @species.
  ///
  /// In ka, this message translates to:
  /// **'სახეობა'**
  String get species;

  /// No description provided for @volume.
  ///
  /// In ka, this message translates to:
  /// **'მოცულობა'**
  String get volume;

  /// No description provided for @treePhytomass.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეების ფიტომასა'**
  String get treePhytomass;

  /// No description provided for @wood.
  ///
  /// In ka, this message translates to:
  /// **'მერქ.'**
  String get wood;

  /// No description provided for @leaves.
  ///
  /// In ka, this message translates to:
  /// **'ფოთლ.'**
  String get leaves;

  /// No description provided for @branches.
  ///
  /// In ka, this message translates to:
  /// **'ტოტ.'**
  String get branches;

  /// No description provided for @roots.
  ///
  /// In ka, this message translates to:
  /// **'ფესვ.'**
  String get roots;

  /// No description provided for @total.
  ///
  /// In ka, this message translates to:
  /// **'ჯამი'**
  String get total;

  /// No description provided for @verticalStructure.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ-ის ვერტიკალური სტრუქტურა'**
  String get verticalStructure;

  /// No description provided for @vertStructTypeName.
  ///
  /// In ka, this message translates to:
  /// **'ვ.ს. ტიპის სახელწოდება'**
  String get vertStructTypeName;

  /// No description provided for @vertStructIndex.
  ///
  /// In ka, this message translates to:
  /// **'ინდექსი'**
  String get vertStructIndex;

  /// No description provided for @vertStructHeight.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლე'**
  String get vertStructHeight;

  /// No description provided for @vertStructDesc.
  ///
  /// In ka, this message translates to:
  /// **'ვ.პ. მიწისზედა ნ. დამოკიდებულება მიწისქვედა ნ.თ.'**
  String get vertStructDesc;

  /// No description provided for @geohorizons.
  ///
  /// In ka, this message translates to:
  /// **'გეოჰორიზონტები'**
  String get geohorizons;

  /// No description provided for @geohorizonRow.
  ///
  /// In ka, this message translates to:
  /// **'გეოჰ. ინდ.'**
  String get geohorizonRow;

  /// No description provided for @noRecords.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები არ მოიძებნა'**
  String get noRecords;

  /// No description provided for @deleteConfirm.
  ///
  /// In ka, this message translates to:
  /// **'დარწმუნებული ხართ წაშლაში?'**
  String get deleteConfirm;

  /// No description provided for @yes.
  ///
  /// In ka, this message translates to:
  /// **'კი'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ka, this message translates to:
  /// **'არა'**
  String get no;

  /// No description provided for @recordDetails.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერის დეტალები'**
  String get recordDetails;

  /// No description provided for @editRecord.
  ///
  /// In ka, this message translates to:
  /// **'რედაქტირება'**
  String get editRecord;

  /// No description provided for @pdfViewer.
  ///
  /// In ka, this message translates to:
  /// **'PDF ნახვა'**
  String get pdfViewer;

  /// No description provided for @pdfScrollRemembered.
  ///
  /// In ka, this message translates to:
  /// **'PDF გახსნის ადგილი დამახსოვრდა'**
  String get pdfScrollRemembered;

  /// No description provided for @aboutApp.
  ///
  /// In ka, this message translates to:
  /// **'აპლიკაციის შესახებ'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In ka, this message translates to:
  /// **'ვერსია'**
  String get version;

  /// No description provided for @organization.
  ///
  /// In ka, this message translates to:
  /// **'ალ. ასლანიკაშვილის სახ. საქართველოს კარტოგრაფთა ასოციაცია'**
  String get organization;

  /// No description provided for @locationDetecting.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების დადგენა...'**
  String get locationDetecting;

  /// No description provided for @locationError.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების დადგენა ვერ მოხდა'**
  String get locationError;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ka, this message translates to:
  /// **'ლოკაციის ნებართვა არ არის'**
  String get locationPermissionDenied;

  /// No description provided for @signIn.
  ///
  /// In ka, this message translates to:
  /// **'შესვლა'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ka, this message translates to:
  /// **'რეგისტრაცია'**
  String get signUp;

  /// No description provided for @cloudSync.
  ///
  /// In ka, this message translates to:
  /// **'Cloud სინქრონიზაცია'**
  String get cloudSync;

  /// No description provided for @cloudSyncDesc.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები ინახება Firebase-ში\nდა ხელმისაწვდომია ნებისმიერი მოწყობილობიდან'**
  String get cloudSyncDesc;

  /// No description provided for @password.
  ///
  /// In ka, this message translates to:
  /// **'პაროლი'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In ka, this message translates to:
  /// **'პაროლი დამავიწყდა'**
  String get forgotPassword;

  /// No description provided for @noAccountSignUp.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში არ გაქვთ? რეგისტრაცია'**
  String get noAccountSignUp;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In ka, this message translates to:
  /// **'უკვე გაქვთ ანგარიში? შესვლა'**
  String get haveAccountSignIn;

  /// No description provided for @passwordResetSent.
  ///
  /// In ka, this message translates to:
  /// **'პაროლის აღდგენის ბმული გაიგზავნა ✓'**
  String get passwordResetSent;

  /// No description provided for @enterEmail.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ ელ-ფოსტა'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ პაროლი'**
  String get enterPassword;

  /// No description provided for @minSixChars.
  ///
  /// In ka, this message translates to:
  /// **'მინიმუმ 6 სიმბოლო'**
  String get minSixChars;

  /// No description provided for @invalidEmail.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტა არასწორია'**
  String get invalidEmail;

  /// No description provided for @accessDenied.
  ///
  /// In ka, this message translates to:
  /// **'წვდომა შეზღუდულია. ადმინისტრატორს მიმართეთ ამ ელ-ფოსტის დასამატებლად.'**
  String get accessDenied;

  /// No description provided for @migrateLocalTitle.
  ///
  /// In ka, this message translates to:
  /// **'ლოკალური მონაცემები'**
  String get migrateLocalTitle;

  /// No description provided for @migrateLocalContent.
  ///
  /// In ka, this message translates to:
  /// **'გსურთ ამ მოწყობილობაზე შენახული ჩანაწერები Cloud-ში ატვირთოთ?'**
  String get migrateLocalContent;

  /// No description provided for @upload.
  ///
  /// In ka, this message translates to:
  /// **'ატვირთვა'**
  String get upload;

  /// No description provided for @uploadSuccess.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჩანაწერი ატვირთულია ✓'**
  String uploadSuccess(int count);

  /// No description provided for @uploadFailed.
  ///
  /// In ka, this message translates to:
  /// **'ატვირთვა ვერ მოხდა'**
  String get uploadFailed;

  /// No description provided for @expeditionMode.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის რეჟიმი'**
  String get expeditionMode;

  /// No description provided for @createTab.
  ///
  /// In ka, this message translates to:
  /// **'შექმნა'**
  String get createTab;

  /// No description provided for @joinTab.
  ///
  /// In ka, this message translates to:
  /// **'შეერთება'**
  String get joinTab;

  /// No description provided for @newExpeditionTitle.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ექსპედიცია'**
  String get newExpeditionTitle;

  /// No description provided for @newExpeditionDesc.
  ///
  /// In ka, this message translates to:
  /// **'შეიქმნება 6-სიმბოლოიანი კოდი. გაუზიარეთ კოლეგებს — მათ შეუძლიათ \"შეერთება\" ჩანართით შეუერთდნენ და ერთად ამუშაონ ჩანაწერები.'**
  String get newExpeditionDesc;

  /// No description provided for @expeditionCodeLabel.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის კოდი'**
  String get expeditionCodeLabel;

  /// No description provided for @codeCopied.
  ///
  /// In ka, this message translates to:
  /// **'კოდი კოპირდა ✓'**
  String get codeCopied;

  /// No description provided for @tapToCopy.
  ///
  /// In ka, this message translates to:
  /// **'დაჭირეთ კოდზე კოპირებისთვის'**
  String get tapToCopy;

  /// No description provided for @confirmExpedition.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციაში შესვლა'**
  String get confirmExpedition;

  /// No description provided for @generateCode.
  ///
  /// In ka, this message translates to:
  /// **'ახალი კოდის გენერაცია'**
  String get generateCode;

  /// No description provided for @createExpedition.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის შექმნა'**
  String get createExpedition;

  /// No description provided for @joinExistingTitle.
  ///
  /// In ka, this message translates to:
  /// **'არსებულ ექსპედიციაში შეერთება'**
  String get joinExistingTitle;

  /// No description provided for @joinExistingDesc.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ კოლეგისგან მიღებული 6-სიმბოლოიანი კოდი.'**
  String get joinExistingDesc;

  /// No description provided for @invalidCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდი უნდა შედგებოდეს {length} სიმბოლოსგან'**
  String invalidCode(int length);

  /// No description provided for @expeditionNotFound.
  ///
  /// In ka, this message translates to:
  /// **'ასეთი ექსპედიცია არ მოიძებნა'**
  String get expeditionNotFound;

  /// No description provided for @gpsTrackHistory.
  ///
  /// In ka, this message translates to:
  /// **'GPS ტრეკების ისტორია'**
  String get gpsTrackHistory;

  /// No description provided for @noTracksFound.
  ///
  /// In ka, this message translates to:
  /// **'ჩაწერილი ტრეკი არ არის'**
  String get noTracksFound;

  /// No description provided for @noTracksHint.
  ///
  /// In ka, this message translates to:
  /// **'რუკაზე  ➤  ▶ ღილაკი'**
  String get noTracksHint;

  /// No description provided for @deleteTrackTitle.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკის წაშლა'**
  String get deleteTrackTitle;

  /// No description provided for @confirmDeleteTrack.
  ///
  /// In ka, this message translates to:
  /// **'გსურთ ამ ტრეკის წაშლა?'**
  String get confirmDeleteTrack;

  /// No description provided for @trackRecording.
  ///
  /// In ka, this message translates to:
  /// **'● ჩაწერა მიმდინარეობს'**
  String get trackRecording;

  /// No description provided for @exportGpx.
  ///
  /// In ka, this message translates to:
  /// **'GPX გადმოტვირთვა'**
  String get exportGpx;

  /// No description provided for @refresh.
  ///
  /// In ka, this message translates to:
  /// **'განახლება'**
  String get refresh;

  /// No description provided for @appearance.
  ///
  /// In ka, this message translates to:
  /// **'გარეგნობა'**
  String get appearance;

  /// No description provided for @keepScreenOn.
  ///
  /// In ka, this message translates to:
  /// **'ეკრანი ნუ ჩაქრება'**
  String get keepScreenOn;

  /// No description provided for @keepScreenOnSub.
  ///
  /// In ka, this message translates to:
  /// **'რუკაზე მუშაობისას'**
  String get keepScreenOnSub;

  /// No description provided for @newEmailHint.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ელ-ფოსტა'**
  String get newEmailHint;

  /// No description provided for @addEmail.
  ///
  /// In ka, this message translates to:
  /// **'დამატება'**
  String get addEmail;

  /// No description provided for @storageTitle.
  ///
  /// In ka, this message translates to:
  /// **'მონაცემების შენახვა'**
  String get storageTitle;

  /// No description provided for @storageLocal.
  ///
  /// In ka, this message translates to:
  /// **'ლოკ.'**
  String get storageLocal;

  /// No description provided for @storageCloud.
  ///
  /// In ka, this message translates to:
  /// **'Cloud'**
  String get storageCloud;

  /// No description provided for @storageExpedition.
  ///
  /// In ka, this message translates to:
  /// **'ექსპ.'**
  String get storageExpedition;

  /// No description provided for @signOut.
  ///
  /// In ka, this message translates to:
  /// **'გამოსვლა'**
  String get signOut;

  /// No description provided for @account.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში'**
  String get account;

  /// No description provided for @syncCloudToLocal.
  ///
  /// In ka, this message translates to:
  /// **'Cloud → ლოკალური'**
  String get syncCloudToLocal;

  /// No description provided for @syncCloudToLocalDesc.
  ///
  /// In ka, this message translates to:
  /// **'Cloud-ის ჩანაწერები ამ მოწყობილობაზე'**
  String get syncCloudToLocalDesc;

  /// No description provided for @leaveExpeditionTitle.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის დატოვება'**
  String get leaveExpeditionTitle;

  /// No description provided for @leaveExpeditionContent.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის რეჟიმიდან გამოხვალთ და Cloud (პირადი) რეჟიმზე გადაინაცვლებთ. ექსპედიციის მონაცემები სერვერზე რჩება.'**
  String get leaveExpeditionContent;

  /// No description provided for @leave.
  ///
  /// In ka, this message translates to:
  /// **'დატოვება'**
  String get leave;

  /// No description provided for @switchToLocal.
  ///
  /// In ka, this message translates to:
  /// **'ლოკალური შენახვა'**
  String get switchToLocal;

  /// No description provided for @switchToLocalContent.
  ///
  /// In ka, this message translates to:
  /// **'Cloud-ის ნაცვლად ლოკალური SQLite გამოყენება. Cloud-ში ჩანაწერები არ წაიშლება.'**
  String get switchToLocalContent;

  /// No description provided for @switchToLocalBtn.
  ///
  /// In ka, this message translates to:
  /// **'გადართვა'**
  String get switchToLocalBtn;

  /// No description provided for @localModeInfo.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები ინახება მხოლოდ ამ მოწყობილობაზე'**
  String get localModeInfo;

  /// No description provided for @expeditionCodeShort.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის კოდი'**
  String get expeditionCodeShort;

  /// No description provided for @copyCode.
  ///
  /// In ka, this message translates to:
  /// **'კოდის კოპირება'**
  String get copyCode;

  /// No description provided for @leaveExpeditionShort.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის დატოვება'**
  String get leaveExpeditionShort;

  /// No description provided for @leaveExpeditionSub.
  ///
  /// In ka, this message translates to:
  /// **'Cloud (პირადი) რეჟიმზე დაბრუნება'**
  String get leaveExpeditionSub;

  /// No description provided for @confirmSignOut.
  ///
  /// In ka, this message translates to:
  /// **'Cloud სინქრონიზაცია შეჩერდება. გამოსვლა?'**
  String get confirmSignOut;

  /// No description provided for @expeditionShortcut.
  ///
  /// In ka, this message translates to:
  /// **'ექსპედიციის რეჟიმი'**
  String get expeditionShortcut;

  /// No description provided for @expeditionShortcutSub.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფური ერთობლივი მუშაობა'**
  String get expeditionShortcutSub;

  /// No description provided for @trackHistory.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკების ისტორია'**
  String get trackHistory;

  /// No description provided for @map.
  ///
  /// In ka, this message translates to:
  /// **'რუკა'**
  String get map;

  /// No description provided for @methodologyShort.
  ///
  /// In ka, this message translates to:
  /// **'მეთოდიკა'**
  String get methodologyShort;

  /// No description provided for @paramsShort.
  ///
  /// In ka, this message translates to:
  /// **'პარამ.'**
  String get paramsShort;

  /// No description provided for @deleteAccount.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიშის წაშლა'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSub.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში და ღრუბელში შენახული ჩანაწერები სამუდამოდ წაიშლება'**
  String get deleteAccountSub;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In ka, this message translates to:
  /// **'წაიშლება თქვენი ანგარიში და ღრუბელში შენახული ყველა ჩანაწერი. მოწყობილობაზე შენახული ჩანაწერები და ექსპედიციაში გაზიარებული ჩანაწერები დარჩება. ეს მოქმედება შეუქცევადია.\n\nდასადასტურებლად შეიყვანეთ პაროლი:'**
  String get deleteAccountWarning;

  /// No description provided for @accountDeleted.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში წაიშალა'**
  String get accountDeleted;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში ვერ წაიშალა: {error}'**
  String deleteAccountFailed(String error);

  /// No description provided for @close.
  ///
  /// In ka, this message translates to:
  /// **'დახურვა'**
  String get close;

  /// No description provided for @search.
  ///
  /// In ka, this message translates to:
  /// **'ძებნა'**
  String get search;

  /// No description provided for @searchEllipsis.
  ///
  /// In ka, this message translates to:
  /// **'ძებნა...'**
  String get searchEllipsis;

  /// No description provided for @error.
  ///
  /// In ka, this message translates to:
  /// **'შეცდომა'**
  String get error;

  /// No description provided for @unknownError.
  ///
  /// In ka, this message translates to:
  /// **'უცნობი შეცდომა'**
  String get unknownError;

  /// No description provided for @ok.
  ///
  /// In ka, this message translates to:
  /// **'კარგი'**
  String get ok;

  /// No description provided for @name.
  ///
  /// In ka, this message translates to:
  /// **'სახელი'**
  String get name;

  /// No description provided for @type.
  ///
  /// In ka, this message translates to:
  /// **'ტიპი'**
  String get type;

  /// No description provided for @description.
  ///
  /// In ka, this message translates to:
  /// **'დახასიათება'**
  String get description;

  /// No description provided for @zoomIn.
  ///
  /// In ka, this message translates to:
  /// **'გადიდება'**
  String get zoomIn;

  /// No description provided for @copied.
  ///
  /// In ka, this message translates to:
  /// **'კოპირებულია'**
  String get copied;

  /// No description provided for @copiedClipboard.
  ///
  /// In ka, this message translates to:
  /// **'კოპირებულია 📋'**
  String get copiedClipboard;

  /// No description provided for @statistics.
  ///
  /// In ka, this message translates to:
  /// **'სტატისტიკა'**
  String get statistics;

  /// No description provided for @photos.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოები'**
  String get photos;

  /// No description provided for @camera.
  ///
  /// In ka, this message translates to:
  /// **'კამერა'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In ka, this message translates to:
  /// **'გალერეა'**
  String get gallery;

  /// No description provided for @recordDuplicated.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერი გადაიწერა ✓'**
  String get recordDuplicated;

  /// No description provided for @fileType.
  ///
  /// In ka, this message translates to:
  /// **'ფაილის ტიპი'**
  String get fileType;

  /// No description provided for @btkFileTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ჩანაწერი (.btk)'**
  String get btkFileTitle;

  /// No description provided for @btkFileSub.
  ///
  /// In ka, this message translates to:
  /// **'ტექსტური მონაცემები'**
  String get btkFileSub;

  /// No description provided for @btkzFileTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ფოტოებით (.btkz)'**
  String get btkzFileTitle;

  /// No description provided for @btkzFileSub.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები + ფოტოები'**
  String get btkzFileSub;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In ka, this message translates to:
  /// **'დარწმუნებული ხართ ამ ჩანაწერის წაშლაში?'**
  String get deleteRecordConfirm;

  /// No description provided for @exportBtc.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ექსპორტი'**
  String get exportBtc;

  /// No description provided for @savedRecords.
  ///
  /// In ka, this message translates to:
  /// **'შენახული ჩანაწერები'**
  String get savedRecords;

  /// No description provided for @importAction.
  ///
  /// In ka, this message translates to:
  /// **'იმპორტი'**
  String get importAction;

  /// No description provided for @exportAction.
  ///
  /// In ka, this message translates to:
  /// **'ექსპორტი'**
  String get exportAction;

  /// No description provided for @pdfDocument.
  ///
  /// In ka, this message translates to:
  /// **'PDF დოკუმენტი'**
  String get pdfDocument;

  /// No description provided for @recordsSearchHint.
  ///
  /// In ka, this message translates to:
  /// **'ძებნა: სახელი, ID, ლოკაცია, თარიღი...'**
  String get recordsSearchHint;

  /// No description provided for @share.
  ///
  /// In ka, this message translates to:
  /// **'გაზიარება'**
  String get share;

  /// No description provided for @saveAsFile.
  ///
  /// In ka, this message translates to:
  /// **'ფაილად შენახვა'**
  String get saveAsFile;

  /// No description provided for @pdfPreparing.
  ///
  /// In ka, this message translates to:
  /// **'PDF მზადდება...'**
  String get pdfPreparing;

  /// No description provided for @pdfPreview.
  ///
  /// In ka, this message translates to:
  /// **'PDF-ის გადახედვა'**
  String get pdfPreview;

  /// No description provided for @pdfBuildFailed.
  ///
  /// In ka, this message translates to:
  /// **'PDF ვერ შეიქმნა'**
  String get pdfBuildFailed;

  /// No description provided for @duplicate.
  ///
  /// In ka, this message translates to:
  /// **'დუბლირება'**
  String get duplicate;

  /// No description provided for @dataLayers.
  ///
  /// In ka, this message translates to:
  /// **'მონაცემთა შრეები'**
  String get dataLayers;

  /// No description provided for @rasters.
  ///
  /// In ka, this message translates to:
  /// **'რასტრები'**
  String get rasters;

  /// No description provided for @webServices.
  ///
  /// In ka, this message translates to:
  /// **'ვებ სერვისები'**
  String get webServices;

  /// No description provided for @fromDevice.
  ///
  /// In ka, this message translates to:
  /// **'მოწყობილობიდან (PNG/JPG/WebP/TIFF)'**
  String get fromDevice;

  /// No description provided for @rasterBounds.
  ///
  /// In ka, this message translates to:
  /// **'რასტრის საზღვრები'**
  String get rasterBounds;

  /// No description provided for @boundNorth.
  ///
  /// In ka, this message translates to:
  /// **'ჩრდ. (N)'**
  String get boundNorth;

  /// No description provided for @boundSouth.
  ///
  /// In ka, this message translates to:
  /// **'სამ. (S)'**
  String get boundSouth;

  /// No description provided for @boundEast.
  ///
  /// In ka, this message translates to:
  /// **'აღმ. (E)'**
  String get boundEast;

  /// No description provided for @boundWest.
  ///
  /// In ka, this message translates to:
  /// **'დას. (W)'**
  String get boundWest;

  /// No description provided for @boundsExample.
  ///
  /// In ka, this message translates to:
  /// **'მაგ.: N:43.5  S:41.0  E:46.8  W:40.0'**
  String get boundsExample;

  /// No description provided for @noRasterLayers.
  ///
  /// In ka, this message translates to:
  /// **'რასტრული შრეები არ არის'**
  String get noRasterLayers;

  /// No description provided for @fromTemplate.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონიდან'**
  String get fromTemplate;

  /// No description provided for @noWebServices.
  ///
  /// In ka, this message translates to:
  /// **'ვებ სერვისები არ არის'**
  String get noWebServices;

  /// No description provided for @saveAsTemplate.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონად შენახვა'**
  String get saveAsTemplate;

  /// No description provided for @deleteServiceConfirm.
  ///
  /// In ka, this message translates to:
  /// **'ამ სერვისის წაშლა გსურთ?'**
  String get deleteServiceConfirm;

  /// No description provided for @chooseTemplate.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონის არჩევა'**
  String get chooseTemplate;

  /// No description provided for @nameOptional.
  ///
  /// In ka, this message translates to:
  /// **'სახელი (სურვილისამებრ)'**
  String get nameOptional;

  /// No description provided for @addService.
  ///
  /// In ka, this message translates to:
  /// **'სერვისის დამატება'**
  String get addService;

  /// No description provided for @editService.
  ///
  /// In ka, this message translates to:
  /// **'სერვისის რედ.'**
  String get editService;

  /// No description provided for @urlTemplate.
  ///
  /// In ka, this message translates to:
  /// **'URL შაბლონი'**
  String get urlTemplate;

  /// No description provided for @subdomains.
  ///
  /// In ka, this message translates to:
  /// **'Subdomains (მძიმით)'**
  String get subdomains;

  /// No description provided for @subdomainsHint.
  ///
  /// In ka, this message translates to:
  /// **'a,b,c  — სურვილისამებრ'**
  String get subdomainsHint;

  /// No description provided for @wmsServiceUrl.
  ///
  /// In ka, this message translates to:
  /// **'WMS სერვისის URL'**
  String get wmsServiceUrl;

  /// No description provided for @wmsLayers.
  ///
  /// In ka, this message translates to:
  /// **'შრეები (მძიმით)'**
  String get wmsLayers;

  /// No description provided for @wmsAutoRequest.
  ///
  /// In ka, this message translates to:
  /// **'WMS GetMap მოთხოვნა ავტომატურად შეიქმნება'**
  String get wmsAutoRequest;

  /// No description provided for @zoomOutSmall.
  ///
  /// In ka, this message translates to:
  /// **'დაპატარავება'**
  String get zoomOutSmall;

  /// No description provided for @closeSearch.
  ///
  /// In ka, this message translates to:
  /// **'ძებნის დახურვა'**
  String get closeSearch;

  /// No description provided for @notFound.
  ///
  /// In ka, this message translates to:
  /// **'ვერ მოიძებნა'**
  String get notFound;

  /// No description provided for @previous.
  ///
  /// In ka, this message translates to:
  /// **'წინა'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგი'**
  String get next;

  /// No description provided for @goToPage.
  ///
  /// In ka, this message translates to:
  /// **'გვერდზე გადასვლა'**
  String get goToPage;

  /// No description provided for @goAction.
  ///
  /// In ka, this message translates to:
  /// **'გადასვლა'**
  String get goAction;

  /// No description provided for @noRecordsYet.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები არ არის'**
  String get noRecordsYet;

  /// No description provided for @statsTotal.
  ///
  /// In ka, this message translates to:
  /// **'სულ'**
  String get statsTotal;

  /// No description provided for @statsNoGps.
  ///
  /// In ka, this message translates to:
  /// **'GPS გარეშე'**
  String get statsNoGps;

  /// No description provided for @statsLast6Months.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო 6 თვე'**
  String get statsLast6Months;

  /// No description provided for @statsGeoFormations.
  ///
  /// In ka, this message translates to:
  /// **'გეოლოგიური ფორმაციები'**
  String get statsGeoFormations;

  /// No description provided for @statsReliefTypes.
  ///
  /// In ka, this message translates to:
  /// **'რელიეფის ტიპები'**
  String get statsReliefTypes;

  /// No description provided for @statsSoilTypes.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის ტიპები'**
  String get statsSoilTypes;

  /// No description provided for @resetPassword.
  ///
  /// In ka, this message translates to:
  /// **'პაროლის აღდგენა'**
  String get resetPassword;

  /// No description provided for @sentCheck.
  ///
  /// In ka, this message translates to:
  /// **'გაიგზავნა ✓'**
  String get sentCheck;

  /// No description provided for @screenSection.
  ///
  /// In ka, this message translates to:
  /// **'ეკრანი'**
  String get screenSection;

  /// No description provided for @exportCoordFormat.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატის ფორმატი (ექსპ.)'**
  String get exportCoordFormat;

  /// No description provided for @aboutSection.
  ///
  /// In ka, this message translates to:
  /// **'შესახებ'**
  String get aboutSection;

  /// No description provided for @appPurposeAndAuthor.
  ///
  /// In ka, this message translates to:
  /// **'პროგრამა შექმნილია სტუდენტებისთვის — ლანდშაფტური გეოგრაფიის საველე კვლევების სასწავლო და სამეცნიერო პრაქტიკისათვის.\n\nშექმნა და იმპლემენტაცია: შპს ბიზნესისა და ტექნოლოგიების უნივერსიტეტის (BTU) ასოცირებული პროფესორი გიორგი კაპანაძე'**
  String get appPurposeAndAuthor;

  /// No description provided for @shareFailed.
  ///
  /// In ka, this message translates to:
  /// **'გაზიარება ვერ მოხერხდა'**
  String get shareFailed;

  /// No description provided for @mapTools.
  ///
  /// In ka, this message translates to:
  /// **'ინსტრუმენტები'**
  String get mapTools;

  /// No description provided for @trackStart.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკის ჩაწერა'**
  String get trackStart;

  /// No description provided for @trackStop.
  ///
  /// In ka, this message translates to:
  /// **'ჩაწერის დასრულება'**
  String get trackStop;

  /// No description provided for @organizationLabel.
  ///
  /// In ka, this message translates to:
  /// **'ორგანიზაცია'**
  String get organizationLabel;

  /// No description provided for @universityLabel.
  ///
  /// In ka, this message translates to:
  /// **'უნივერსიტეტი'**
  String get universityLabel;

  /// No description provided for @measureTool.
  ///
  /// In ka, this message translates to:
  /// **'გამზომი'**
  String get measureTool;

  /// No description provided for @undo.
  ///
  /// In ka, this message translates to:
  /// **'უკან (undo)'**
  String get undo;

  /// No description provided for @clear.
  ///
  /// In ka, this message translates to:
  /// **'გასუფთავება'**
  String get clear;

  /// No description provided for @measureCoords.
  ///
  /// In ka, this message translates to:
  /// **'კოორდ.'**
  String get measureCoords;

  /// No description provided for @measureLine.
  ///
  /// In ka, this message translates to:
  /// **'ხაზი'**
  String get measureLine;

  /// No description provided for @measurePolygon.
  ///
  /// In ka, this message translates to:
  /// **'პოლიგ.'**
  String get measurePolygon;

  /// No description provided for @measureHintCoords.
  ///
  /// In ka, this message translates to:
  /// **'რუკაზე შეეხეთ კოორდინატების სანახავად'**
  String get measureHintCoords;

  /// No description provided for @measureHintLine.
  ///
  /// In ka, this message translates to:
  /// **'შეეხეთ წერტილების დასამატებლად'**
  String get measureHintLine;

  /// No description provided for @measureHintPolygon.
  ///
  /// In ka, this message translates to:
  /// **'შეეხეთ პოლიგონის ასაგებად (მინ. 3 წ.)'**
  String get measureHintPolygon;

  /// No description provided for @measurePoints.
  ///
  /// In ka, this message translates to:
  /// **'წ.'**
  String get measurePoints;

  /// No description provided for @measureLength.
  ///
  /// In ka, this message translates to:
  /// **'სიგრძე'**
  String get measureLength;

  /// No description provided for @measurePerimeter.
  ///
  /// In ka, this message translates to:
  /// **'პერიმეტრი'**
  String get measurePerimeter;

  /// No description provided for @measureArea.
  ///
  /// In ka, this message translates to:
  /// **'ფართობი'**
  String get measureArea;

  /// No description provided for @layerControl.
  ///
  /// In ka, this message translates to:
  /// **'შრეების კონტროლი'**
  String get layerControl;

  /// No description provided for @baseMaps.
  ///
  /// In ka, this message translates to:
  /// **'ფონური რუკები'**
  String get baseMaps;

  /// No description provided for @adminBoundaries.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრაციული საზღვრები'**
  String get adminBoundaries;

  /// No description provided for @layerRegions.
  ///
  /// In ka, this message translates to:
  /// **'მხარეები'**
  String get layerRegions;

  /// No description provided for @layerMunicipalities.
  ///
  /// In ka, this message translates to:
  /// **'მუნიციპალიტეტები'**
  String get layerMunicipalities;

  /// No description provided for @fieldData.
  ///
  /// In ka, this message translates to:
  /// **'საველე მონაცემები'**
  String get fieldData;

  /// No description provided for @weatherForecast.
  ///
  /// In ka, this message translates to:
  /// **'ამინდის პროგნოზი'**
  String get weatherForecast;

  /// No description provided for @weatherLoadFailed.
  ///
  /// In ka, this message translates to:
  /// **'ამინდის ჩამოტვირთვა ვერ მოხდა'**
  String get weatherLoadFailed;

  /// No description provided for @checkInternet.
  ///
  /// In ka, this message translates to:
  /// **'შეამოწმეთ ინტერნეტ კავშირი'**
  String get checkInternet;

  /// No description provided for @retry.
  ///
  /// In ka, this message translates to:
  /// **'კვლავ ცდა'**
  String get retry;

  /// No description provided for @forecast24h.
  ///
  /// In ka, this message translates to:
  /// **'24 საათის პროგნოზი'**
  String get forecast24h;

  /// No description provided for @nextDays.
  ///
  /// In ka, this message translates to:
  /// **'მომდევნო დღეები'**
  String get nextDays;

  /// No description provided for @weatherCredit.
  ///
  /// In ka, this message translates to:
  /// **'ამინდი: '**
  String get weatherCredit;

  /// No description provided for @placeCity.
  ///
  /// In ka, this message translates to:
  /// **'ქალაქი'**
  String get placeCity;

  /// No description provided for @placeVillage.
  ///
  /// In ka, this message translates to:
  /// **'სოფელი'**
  String get placeVillage;

  /// No description provided for @placeAdmin.
  ///
  /// In ka, this message translates to:
  /// **'ადმინისტრაციული ერთეული'**
  String get placeAdmin;

  /// No description provided for @placeRegion.
  ///
  /// In ka, this message translates to:
  /// **'რეგიონი'**
  String get placeRegion;

  /// No description provided for @placeSuburb.
  ///
  /// In ka, this message translates to:
  /// **'უბანი'**
  String get placeSuburb;

  /// No description provided for @placeRiver.
  ///
  /// In ka, this message translates to:
  /// **'მდინარე'**
  String get placeRiver;

  /// No description provided for @placeMountain.
  ///
  /// In ka, this message translates to:
  /// **'მთა'**
  String get placeMountain;

  /// No description provided for @placeOther.
  ///
  /// In ka, this message translates to:
  /// **'ადგილი'**
  String get placeOther;

  /// No description provided for @placeMunicipality.
  ///
  /// In ka, this message translates to:
  /// **'მუნიციპალიტეტი'**
  String get placeMunicipality;

  /// No description provided for @mapSearchHint.
  ///
  /// In ka, this message translates to:
  /// **'ძებნა: სოფელი, ქალაქი, რეგიონი...'**
  String get mapSearchHint;

  /// No description provided for @typeSearchTerm.
  ///
  /// In ka, this message translates to:
  /// **'ჩაწერეთ ძებნის სიტყვა'**
  String get typeSearchTerm;

  /// No description provided for @nothingFound.
  ///
  /// In ka, this message translates to:
  /// **'არაფერი მოიძებნა'**
  String get nothingFound;

  /// No description provided for @inLayers.
  ///
  /// In ka, this message translates to:
  /// **'შრეებში'**
  String get inLayers;

  /// No description provided for @placesOsm.
  ///
  /// In ka, this message translates to:
  /// **'ადგილები (OSM)'**
  String get placesOsm;

  /// No description provided for @gpsTrackFinished.
  ///
  /// In ka, this message translates to:
  /// **'GPS ტრეკი დასრულდა'**
  String get gpsTrackFinished;

  /// No description provided for @distance.
  ///
  /// In ka, this message translates to:
  /// **'მანძილი'**
  String get distance;

  /// No description provided for @durationShort.
  ///
  /// In ka, this message translates to:
  /// **'ხანგრძლ.'**
  String get durationShort;

  /// No description provided for @trackPoints.
  ///
  /// In ka, this message translates to:
  /// **'წერტილი'**
  String get trackPoints;

  /// No description provided for @downloadGpx.
  ///
  /// In ka, this message translates to:
  /// **'GPX-ის გადმოტვირთვა'**
  String get downloadGpx;

  /// No description provided for @tapMapToAddPoint.
  ///
  /// In ka, this message translates to:
  /// **'რუკაზე დააჭირეთ წერტილის დასამატებლად'**
  String get tapMapToAddPoint;

  /// No description provided for @georgia.
  ///
  /// In ka, this message translates to:
  /// **'საქართველო'**
  String get georgia;

  /// No description provided for @savedCheck.
  ///
  /// In ka, this message translates to:
  /// **'შენახულია ✓'**
  String get savedCheck;

  /// No description provided for @gpsOff.
  ///
  /// In ka, this message translates to:
  /// **'GPS გათიშულია'**
  String get gpsOff;

  /// No description provided for @enableGps.
  ///
  /// In ka, this message translates to:
  /// **'GPS ჩართვა'**
  String get enableGps;

  /// No description provided for @locationBlocked.
  ///
  /// In ka, this message translates to:
  /// **'მდებარეობა აკრძალულია'**
  String get locationBlocked;

  /// No description provided for @recordChanged.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერი შეიცვალა'**
  String get recordChanged;

  /// No description provided for @stay.
  ///
  /// In ka, this message translates to:
  /// **'დარჩენა'**
  String get stay;

  /// No description provided for @exitAction.
  ///
  /// In ka, this message translates to:
  /// **'გასვლა'**
  String get exitAction;

  /// No description provided for @tabBasic.
  ///
  /// In ka, this message translates to:
  /// **'ძირითადი'**
  String get tabBasic;

  /// No description provided for @tabPhysGeo.
  ///
  /// In ka, this message translates to:
  /// **'ფიზ.გეოგ.'**
  String get tabPhysGeo;

  /// No description provided for @tabVegetation.
  ///
  /// In ka, this message translates to:
  /// **'მცენარ.'**
  String get tabVegetation;

  /// No description provided for @tabGeomass.
  ///
  /// In ka, this message translates to:
  /// **'გეომასა'**
  String get tabGeomass;

  /// No description provided for @tabVertStruct.
  ///
  /// In ka, this message translates to:
  /// **'ვ.სტრ.'**
  String get tabVertStruct;

  /// No description provided for @zoomOut.
  ///
  /// In ka, this message translates to:
  /// **'შემცირება'**
  String get zoomOut;

  /// No description provided for @fullScreen.
  ///
  /// In ka, this message translates to:
  /// **'სრული ეკრანი'**
  String get fullScreen;

  /// No description provided for @coordFormatHint.
  ///
  /// In ka, this message translates to:
  /// **'DD, DM ან DMS ფორმატი'**
  String get coordFormatHint;

  /// No description provided for @utmMustBeNumbers.
  ///
  /// In ka, this message translates to:
  /// **'E და N რიცხვებია'**
  String get utmMustBeNumbers;

  /// No description provided for @outsideGeorgia.
  ///
  /// In ka, this message translates to:
  /// **'საქართველოს საზღვრების გარეთ'**
  String get outsideGeorgia;

  /// No description provided for @conversionError.
  ///
  /// In ka, this message translates to:
  /// **'კონვერტაციის შეცდომა'**
  String get conversionError;

  /// No description provided for @coordsWrittenToForm.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატები ფორმაში ჩაიწერა'**
  String get coordsWrittenToForm;

  /// No description provided for @coordConverter.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების კონვერტერი'**
  String get coordConverter;

  /// No description provided for @latitudeShort.
  ///
  /// In ka, this message translates to:
  /// **'განედი'**
  String get latitudeShort;

  /// No description provided for @longitudeShort.
  ///
  /// In ka, this message translates to:
  /// **'გრძედი'**
  String get longitudeShort;

  /// No description provided for @writeToForm.
  ///
  /// In ka, this message translates to:
  /// **'ჩაწერა ფორმაში'**
  String get writeToForm;

  /// No description provided for @enterCoordsAnyFormat.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ კოორდინატები ნებისმიერ ფორმატში'**
  String get enterCoordsAnyFormat;

  /// No description provided for @convert.
  ///
  /// In ka, this message translates to:
  /// **'კონვერტაცია'**
  String get convert;

  /// No description provided for @writeToFormDd.
  ///
  /// In ka, this message translates to:
  /// **'ჩაწერა ფორმაში (DD)'**
  String get writeToFormDd;

  /// No description provided for @coordsOutsideGeorgia.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატები საქართველოს საზღვრების გარეთ'**
  String get coordsOutsideGeorgia;

  /// No description provided for @numbersOnly.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ რიცხვი'**
  String get numbersOnly;

  /// No description provided for @altitudeRange.
  ///
  /// In ka, this message translates to:
  /// **'−500 … 9000 მ'**
  String get altitudeRange;

  /// No description provided for @btkFullTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბუნებრივ-ტერიტორიული კომპლექსის (ბტკ) აღწერა'**
  String get btkFullTitle;

  /// No description provided for @locationHint.
  ///
  /// In ka, this message translates to:
  /// **'მდებარეობის სახელი / აღწერა'**
  String get locationHint;

  /// No description provided for @altitudeM.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლე (მ)'**
  String get altitudeM;

  /// No description provided for @aspectDeg.
  ///
  /// In ka, this message translates to:
  /// **'ასპექტი (°)'**
  String get aspectDeg;

  /// No description provided for @geomassHeader.
  ///
  /// In ka, this message translates to:
  /// **'გეომასების კვლევა — ბტკ-ის ვ.პ. მიწისზედა ნაწ.'**
  String get geomassHeader;

  /// No description provided for @treePhytomassHeader.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეების ფიტომასა (ტ/ჰა)'**
  String get treePhytomassHeader;

  /// No description provided for @rowShort.
  ///
  /// In ka, this message translates to:
  /// **'სტრიქ.'**
  String get rowShort;

  /// No description provided for @treeRowShort.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მც. სტრიქ.'**
  String get treeRowShort;

  /// No description provided for @gmSection.
  ///
  /// In ka, this message translates to:
  /// **'სექ.'**
  String get gmSection;

  /// No description provided for @gmDepth.
  ///
  /// In ka, this message translates to:
  /// **'სიღ.'**
  String get gmDepth;

  /// No description provided for @gmPedBulk.
  ///
  /// In ka, this message translates to:
  /// **'პედ.მოც.'**
  String get gmPedBulk;

  /// No description provided for @gmPedQty.
  ///
  /// In ka, this message translates to:
  /// **'პედ.რ.'**
  String get gmPedQty;

  /// No description provided for @gmLithQty.
  ///
  /// In ka, this message translates to:
  /// **'ლით.რ.'**
  String get gmLithQty;

  /// No description provided for @gmLithDens.
  ///
  /// In ka, this message translates to:
  /// **'ლით.სმ.'**
  String get gmLithDens;

  /// No description provided for @gmHydQty.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდ.რ.'**
  String get gmHydQty;

  /// No description provided for @gmHydWet.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდ.სვ.'**
  String get gmHydWet;

  /// No description provided for @gmHydDry.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდ.მშ.'**
  String get gmHydDry;

  /// No description provided for @gmPhytWet.
  ///
  /// In ka, this message translates to:
  /// **'ფიტ.სვ.'**
  String get gmPhytWet;

  /// No description provided for @gmPhytDry.
  ///
  /// In ka, this message translates to:
  /// **'ფიტ.მშ.'**
  String get gmPhytDry;

  /// No description provided for @tpSpecies.
  ///
  /// In ka, this message translates to:
  /// **'სახ.'**
  String get tpSpecies;

  /// No description provided for @tpVolume.
  ///
  /// In ka, this message translates to:
  /// **'მ.წ.'**
  String get tpVolume;

  /// No description provided for @tpWetWood.
  ///
  /// In ka, this message translates to:
  /// **'სვ.მ.'**
  String get tpWetWood;

  /// No description provided for @tpWetLeaves.
  ///
  /// In ka, this message translates to:
  /// **'სვ.ფ.'**
  String get tpWetLeaves;

  /// No description provided for @tpWetBranches.
  ///
  /// In ka, this message translates to:
  /// **'სვ.ტ.'**
  String get tpWetBranches;

  /// No description provided for @tpWetRoots.
  ///
  /// In ka, this message translates to:
  /// **'სვ.ფეს.'**
  String get tpWetRoots;

  /// No description provided for @tpWetTotal.
  ///
  /// In ka, this message translates to:
  /// **'სვ.ჯ.'**
  String get tpWetTotal;

  /// No description provided for @tpDryWood.
  ///
  /// In ka, this message translates to:
  /// **'მშ.მ.'**
  String get tpDryWood;

  /// No description provided for @tpDryLeaves.
  ///
  /// In ka, this message translates to:
  /// **'მშ.ფ.'**
  String get tpDryLeaves;

  /// No description provided for @tpDryBranches.
  ///
  /// In ka, this message translates to:
  /// **'მშ.ტ.'**
  String get tpDryBranches;

  /// No description provided for @tpDryRoots.
  ///
  /// In ka, this message translates to:
  /// **'მშ.ფეს.'**
  String get tpDryRoots;

  /// No description provided for @tpDryTotal.
  ///
  /// In ka, this message translates to:
  /// **'მშ.ჯ.'**
  String get tpDryTotal;

  /// No description provided for @vegTierShort.
  ///
  /// In ka, this message translates to:
  /// **'იარ.'**
  String get vegTierShort;

  /// No description provided for @vegHeightM.
  ///
  /// In ka, this message translates to:
  /// **'სიმ. (მ)'**
  String get vegHeightM;

  /// No description provided for @vegPhenShort.
  ///
  /// In ka, this message translates to:
  /// **'ფენოფ.'**
  String get vegPhenShort;

  /// No description provided for @soilProfileDescShort.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის პროფილის მორფ. დახასიათება'**
  String get soilProfileDescShort;

  /// No description provided for @morphDescPhotos.
  ///
  /// In ka, this message translates to:
  /// **'მორფ. დახასიათების ფოტოები'**
  String get morphDescPhotos;

  /// No description provided for @horizonShort.
  ///
  /// In ka, this message translates to:
  /// **'ჰ-ტი'**
  String get horizonShort;

  /// No description provided for @addHorizon.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტის დამატება'**
  String get addHorizon;

  /// No description provided for @soilSurfaceFormationShort.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგ ზედაპ. ფორმაციის ტიპი'**
  String get soilSurfaceFormationShort;

  /// No description provided for @vertStructDescShort.
  ///
  /// In ka, this message translates to:
  /// **'ვ.პ. მიწისზედა ნ. დამოკიდ. მიწისქვედა ნ.თ.'**
  String get vertStructDescShort;

  /// No description provided for @vertStructPhotos.
  ///
  /// In ka, this message translates to:
  /// **'ვ.ს. ფოტოები'**
  String get vertStructPhotos;

  /// No description provided for @deletePhoto.
  ///
  /// In ka, this message translates to:
  /// **'ფოტოს წაშლა'**
  String get deletePhoto;

  /// No description provided for @deletePhotoConfirm.
  ///
  /// In ka, this message translates to:
  /// **'გსურთ ამ ფოტოს წაშლა?'**
  String get deletePhotoConfirm;

  /// No description provided for @noPhotoAdded.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო არ არის დამატებული'**
  String get noPhotoAdded;

  /// No description provided for @cameraOrGallery.
  ///
  /// In ka, this message translates to:
  /// **'კამერა ან გალერეა'**
  String get cameraOrGallery;

  /// No description provided for @noPhotoHint.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო არ არის. გადაიღეთ კამერით ან მიაბით გალერეიდან.'**
  String get noPhotoHint;

  /// No description provided for @updateLater.
  ///
  /// In ka, this message translates to:
  /// **'შემდეგ'**
  String get updateLater;

  /// No description provided for @updateDownload.
  ///
  /// In ka, this message translates to:
  /// **'ჩამოტვირთვა'**
  String get updateDownload;

  /// No description provided for @layersEmptyHelp.
  ///
  /// In ka, this message translates to:
  /// **'📁 \"მოწყობილობიდან\" — ფაილი მოწყობილობიდან\n\n📦 assets-ბეჭდვა — catalog.json-ში:\n  \"file\": \"assets/rasters/map.png\"\n  ფორმატები: PNG · JPG · WebP · TIFF'**
  String get layersEmptyHelp;

  /// No description provided for @resetPasswordPrompt.
  ///
  /// In ka, this message translates to:
  /// **'შეიყვანეთ ელ-ფოსტა — გამოგიგზავნოთ განახლების ბმული.'**
  String get resetPasswordPrompt;

  /// No description provided for @soilLegend.
  ///
  /// In ka, this message translates to:
  /// **'ფ.=ფერი  მ.შ.=მექ.შედგ.  სტ.=სტრ.  ფ.=ფ-ნ.  სმ.=სიმკვ.  ახ.=ახ-ნ.  ხ.=ხ-ნ.  ტ.=ტ-ბა  ჰ.=ჰ-ს.  ქ.=ქ.საზ.'**
  String get soilLegend;

  /// No description provided for @otherUserChanged.
  ///
  /// In ka, this message translates to:
  /// **'⚠️ სხვა მომხმარებელმა ჩანაწერი შეცვალა — თქვენი ვერსია შენახულია'**
  String get otherUserChanged;

  /// No description provided for @gpsOffMessage.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების დასადგენად GPS (მდებარეობის სერვისი) ჩართული უნდა იყოს.'**
  String get gpsOffMessage;

  /// No description provided for @locationBlockedMessage.
  ///
  /// In ka, this message translates to:
  /// **'აპლიკაციას მდებარეობაზე წვდომა არ აქვს. გახსენით პარამეტრები და ჩართეთ.'**
  String get locationBlockedMessage;

  /// No description provided for @copySuffix.
  ///
  /// In ka, this message translates to:
  /// **'(ასლი)'**
  String get copySuffix;

  /// No description provided for @authUserNotFound.
  ///
  /// In ka, this message translates to:
  /// **'მომხმარებელი ვერ მოიძებნა'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In ka, this message translates to:
  /// **'პაროლი არასწორია'**
  String get authWrongPassword;

  /// No description provided for @authInvalidCredential.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტა ან პაროლი არასწორია'**
  String get authInvalidCredential;

  /// No description provided for @authEmailInUse.
  ///
  /// In ka, this message translates to:
  /// **'ეს ელ-ფოსტა უკვე გამოყენებულია'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In ka, this message translates to:
  /// **'პაროლი ძალიან სუსტია (მინ. 6 სიმბოლო)'**
  String get authWeakPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In ka, this message translates to:
  /// **'ელ-ფოსტის ფორმატი არასწორია'**
  String get authInvalidEmail;

  /// No description provided for @authMethodDisabled.
  ///
  /// In ka, this message translates to:
  /// **'ეს შესვლის მეთოდი გათიშულია'**
  String get authMethodDisabled;

  /// No description provided for @authUserDisabled.
  ///
  /// In ka, this message translates to:
  /// **'ანგარიში დაბლოკილია'**
  String get authUserDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ka, this message translates to:
  /// **'ძალიან ბევრი მცდელობა — ცოტა ხანი დაიცადეთ'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In ka, this message translates to:
  /// **'ქსელის შეცდომა — შეამოწმეთ ინტერნეტი'**
  String get authNetworkError;

  /// No description provided for @authSystemError.
  ///
  /// In ka, this message translates to:
  /// **'სისტემური შეცდომა'**
  String get authSystemError;

  /// No description provided for @authEnterEmailFirst.
  ///
  /// In ka, this message translates to:
  /// **'ჯერ შეიყვანეთ ელ-ფოსტა'**
  String get authEnterEmailFirst;

  /// No description provided for @authRulesError.
  ///
  /// In ka, this message translates to:
  /// **'Firestore Rules შეცდომა — allowed_users კოლექციაზე \"allow read: if true\" გახსენით.'**
  String get authRulesError;

  /// No description provided for @fileReadFailed.
  ///
  /// In ka, this message translates to:
  /// **'ფაილი ვერ წაიკითხა'**
  String get fileReadFailed;

  /// No description provided for @invalidBtkFile.
  ///
  /// In ka, this message translates to:
  /// **'არასწორი .btk ფაილის ფორმატი'**
  String get invalidBtkFile;

  /// No description provided for @invalidBtkzFile.
  ///
  /// In ka, this message translates to:
  /// **'არასწორი .btkz ფორმატი'**
  String get invalidBtkzFile;

  /// No description provided for @shareRecordsGeoJson.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ჩანაწერები — GeoJSON'**
  String get shareRecordsGeoJson;

  /// No description provided for @shareRecordsCsv.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ჩანაწერები — CSV'**
  String get shareRecordsCsv;

  /// No description provided for @shareRecordsKml.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ KML'**
  String get shareRecordsKml;

  /// No description provided for @savePdfTitle.
  ///
  /// In ka, this message translates to:
  /// **'PDF შენახვა'**
  String get savePdfTitle;

  /// No description provided for @pdfSaved.
  ///
  /// In ka, this message translates to:
  /// **'PDF შენახულია'**
  String get pdfSaved;

  /// No description provided for @exportBtkTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ჩანაწერების ექსპორტი'**
  String get exportBtkTitle;

  /// No description provided for @exportBtkzTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ ჩანაწერები + ფოტოები'**
  String get exportBtkzTitle;

  /// No description provided for @exported.
  ///
  /// In ka, this message translates to:
  /// **'ექსპორტირებულია'**
  String get exported;

  /// No description provided for @unitKm.
  ///
  /// In ka, this message translates to:
  /// **'კმ'**
  String get unitKm;

  /// No description provided for @unitM.
  ///
  /// In ka, this message translates to:
  /// **'მ'**
  String get unitM;

  /// No description provided for @unitKm2.
  ///
  /// In ka, this message translates to:
  /// **'კმ²'**
  String get unitKm2;

  /// No description provided for @unitM2.
  ///
  /// In ka, this message translates to:
  /// **'მ²'**
  String get unitM2;

  /// No description provided for @unitHa.
  ///
  /// In ka, this message translates to:
  /// **'ჰა'**
  String get unitHa;

  /// No description provided for @unitMps.
  ///
  /// In ka, this message translates to:
  /// **'მ/წ'**
  String get unitMps;

  /// No description provided for @unitMm.
  ///
  /// In ka, this message translates to:
  /// **'მმ'**
  String get unitMm;

  /// No description provided for @unitHour.
  ///
  /// In ka, this message translates to:
  /// **'სთ'**
  String get unitHour;

  /// No description provided for @unitMin.
  ///
  /// In ka, this message translates to:
  /// **'წთ'**
  String get unitMin;

  /// No description provided for @unitSec.
  ///
  /// In ka, this message translates to:
  /// **'წმ'**
  String get unitSec;

  /// No description provided for @windN.
  ///
  /// In ka, this message translates to:
  /// **'ჩ'**
  String get windN;

  /// No description provided for @windNE.
  ///
  /// In ka, this message translates to:
  /// **'ჩ-აღ'**
  String get windNE;

  /// No description provided for @windE.
  ///
  /// In ka, this message translates to:
  /// **'აღ'**
  String get windE;

  /// No description provided for @windSE.
  ///
  /// In ka, this message translates to:
  /// **'სამ-აღ'**
  String get windSE;

  /// No description provided for @windS.
  ///
  /// In ka, this message translates to:
  /// **'სამ'**
  String get windS;

  /// No description provided for @windSW.
  ///
  /// In ka, this message translates to:
  /// **'სამ-დ'**
  String get windSW;

  /// No description provided for @windW.
  ///
  /// In ka, this message translates to:
  /// **'დ'**
  String get windW;

  /// No description provided for @windNW.
  ///
  /// In ka, this message translates to:
  /// **'ჩ-დ'**
  String get windNW;

  /// No description provided for @today.
  ///
  /// In ka, this message translates to:
  /// **'დღეს'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In ka, this message translates to:
  /// **'ხვალ'**
  String get tomorrow;

  /// No description provided for @daySun.
  ///
  /// In ka, this message translates to:
  /// **'კვირა'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In ka, this message translates to:
  /// **'ორშ'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In ka, this message translates to:
  /// **'სამშ'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In ka, this message translates to:
  /// **'ოთხ'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In ka, this message translates to:
  /// **'ხუთ'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In ka, this message translates to:
  /// **'პარ'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In ka, this message translates to:
  /// **'შაბ'**
  String get daySat;

  /// No description provided for @wxThunder.
  ///
  /// In ka, this message translates to:
  /// **'ჭექა-ქუხილი'**
  String get wxThunder;

  /// No description provided for @wxHeavyRain.
  ///
  /// In ka, this message translates to:
  /// **'ძლიერი წვიმა'**
  String get wxHeavyRain;

  /// No description provided for @wxRain.
  ///
  /// In ka, this message translates to:
  /// **'წვიმა'**
  String get wxRain;

  /// No description provided for @wxSleet.
  ///
  /// In ka, this message translates to:
  /// **'თოვა-წვიმა'**
  String get wxSleet;

  /// No description provided for @wxSnow.
  ///
  /// In ka, this message translates to:
  /// **'თოვლი'**
  String get wxSnow;

  /// No description provided for @wxFog.
  ///
  /// In ka, this message translates to:
  /// **'ნისლი'**
  String get wxFog;

  /// No description provided for @wxClear.
  ///
  /// In ka, this message translates to:
  /// **'მოწმენდილი'**
  String get wxClear;

  /// No description provided for @wxFair.
  ///
  /// In ka, this message translates to:
  /// **'ნათელი'**
  String get wxFair;

  /// No description provided for @wxPartlyCloudy.
  ///
  /// In ka, this message translates to:
  /// **'ნაწილობრივ ღრუბლიანი'**
  String get wxPartlyCloudy;

  /// No description provided for @wxOvercast.
  ///
  /// In ka, this message translates to:
  /// **'მოღრუბლული'**
  String get wxOvercast;

  /// No description provided for @wxCloudy.
  ///
  /// In ka, this message translates to:
  /// **'ღრუბლიანი'**
  String get wxCloudy;

  /// No description provided for @wxUnknown.
  ///
  /// In ka, this message translates to:
  /// **'ამინდი'**
  String get wxUnknown;

  /// No description provided for @monthJan.
  ///
  /// In ka, this message translates to:
  /// **'იანვ'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In ka, this message translates to:
  /// **'თებ'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In ka, this message translates to:
  /// **'მარ'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In ka, this message translates to:
  /// **'აპრ'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In ka, this message translates to:
  /// **'მაი'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In ka, this message translates to:
  /// **'ივნ'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In ka, this message translates to:
  /// **'ივლ'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In ka, this message translates to:
  /// **'აგვ'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In ka, this message translates to:
  /// **'სექ'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In ka, this message translates to:
  /// **'ოქტ'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In ka, this message translates to:
  /// **'ნოე'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In ka, this message translates to:
  /// **'დეკ'**
  String get monthDec;

  /// No description provided for @errorWithDetail.
  ///
  /// In ka, this message translates to:
  /// **'შეცდომა: {detail}'**
  String errorWithDetail(String detail);

  /// No description provided for @authErrorCode.
  ///
  /// In ka, this message translates to:
  /// **'შეცდომა ({code})'**
  String authErrorCode(String code);

  /// No description provided for @authDbError.
  ///
  /// In ka, this message translates to:
  /// **'DB შეცდომა ({code})'**
  String authDbError(String code);

  /// No description provided for @resetLinkSent.
  ///
  /// In ka, this message translates to:
  /// **'პაროლის განახლების ბმული გამოიგზავნა:\n\n{email}\n\nშეამოწმეთ ელ-ფოსტა (spam-საც).'**
  String resetLinkSent(String email);

  /// No description provided for @deleteRecordsConfirm.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჩანაწერი საბოლოოდ წაიშლება?'**
  String deleteRecordsConfirm(int count);

  /// No description provided for @recordsCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჩანაწერი'**
  String recordsCount(int count);

  /// No description provided for @photosCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} ფოტო'**
  String photosCount(int count);

  /// No description provided for @tracksCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} GPS ტრეკი'**
  String tracksCount(int count);

  /// No description provided for @importedParts.
  ///
  /// In ka, this message translates to:
  /// **'{parts} შემოიტანა'**
  String importedParts(String parts);

  /// No description provided for @importedSummary.
  ///
  /// In ka, this message translates to:
  /// **'{total} ჩანაწერი შემოიტანა ({added} ახალი, {updated} განახლდა)'**
  String importedSummary(int total, int added, int updated);

  /// No description provided for @queryNotFound.
  ///
  /// In ka, this message translates to:
  /// **'\"{query}\" — არ მოიძებნა'**
  String queryNotFound(String query);

  /// No description provided for @btkNumber.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ #{id}'**
  String btkNumber(String id);

  /// No description provided for @templateSaved.
  ///
  /// In ka, this message translates to:
  /// **'\"{name}\" შაბლონებში შეინახა ✓'**
  String templateSaved(String name);

  /// No description provided for @pageOf.
  ///
  /// In ka, this message translates to:
  /// **'გვ. {current} / {total}'**
  String pageOf(int current, int total);

  /// No description provided for @pageRange.
  ///
  /// In ka, this message translates to:
  /// **'გვ. (1–{count})'**
  String pageRange(int count);

  /// No description provided for @recordsOnMap.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები რუქაზე ({count})'**
  String recordsOnMap(int count);

  /// No description provided for @recordsDownloaded.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჩანაწერი გადმოიწერა ✓'**
  String recordsDownloaded(int count);

  /// No description provided for @photoOpenFailed.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო ვერ გაიხსნა: {error}'**
  String photoOpenFailed(String error);

  /// No description provided for @photoSaveFailed.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო ვერ შეინახა: {error}'**
  String photoSaveFailed(String error);

  /// No description provided for @newVersionAvailable.
  ///
  /// In ka, this message translates to:
  /// **'ახალი ვერსია v{version} ხელმისაწვდომია'**
  String newVersionAvailable(String version);

  /// No description provided for @savedAtPath.
  ///
  /// In ka, this message translates to:
  /// **'შენახულია: {path}'**
  String savedAtPath(String path);

  /// No description provided for @exportedWith.
  ///
  /// In ka, this message translates to:
  /// **'ექსპორტირებულია ({details})'**
  String exportedWith(String details);

  /// No description provided for @shareGpsTrack.
  ///
  /// In ka, this message translates to:
  /// **'GPS ტრეკი — {date}'**
  String shareGpsTrack(String date);

  /// No description provided for @shareBtkFile.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ — {filename}'**
  String shareBtkFile(String filename);

  /// No description provided for @saveFailed.
  ///
  /// In ka, this message translates to:
  /// **'ვერ შეინახა. ცვლილებები ჯერ მხოლოდ ეკრანზეა.'**
  String get saveFailed;

  /// No description provided for @cloudSaveFailed.
  ///
  /// In ka, this message translates to:
  /// **'სერვერმა ცვლილება არ მიიღო და ის არ შეინახა.'**
  String get cloudSaveFailed;

  /// No description provided for @recordsLoadFailed.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერების ჩატვირთვა ვერ მოხერხდა.'**
  String get recordsLoadFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In ka, this message translates to:
  /// **'წაშლა ვერ მოხერხდა.'**
  String get deleteFailed;

  /// No description provided for @replaceCoordsTitle.
  ///
  /// In ka, this message translates to:
  /// **'შევცვალო კოორდინატები?'**
  String get replaceCoordsTitle;

  /// No description provided for @replaceCoordsMessage.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერს უკვე აქვს კოორდინატები. GPS-ის მონაცემები მათ შეცვლის.'**
  String get replaceCoordsMessage;

  /// No description provided for @replaceAction.
  ///
  /// In ka, this message translates to:
  /// **'შეცვლა'**
  String get replaceAction;

  /// No description provided for @locationFailed.
  ///
  /// In ka, this message translates to:
  /// **'მდებარეობა ვერ დადგინდა. სცადე ღია ადგილას.'**
  String get locationFailed;

  /// No description provided for @recordsUnreadable.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჩანაწერი ვერ წაიკითხა. ისინი არ წაშლილა.'**
  String recordsUnreadable(int count);

  /// No description provided for @importSkippedOlder.
  ///
  /// In ka, this message translates to:
  /// **'{count} გამოტოვებულია, რადგან უკვე არის იგივე ან უფრო ახალი ვერსია'**
  String importSkippedOlder(int count);

  /// No description provided for @unitGCm3.
  ///
  /// In ka, this message translates to:
  /// **'გრ/სმ³'**
  String get unitGCm3;

  /// No description provided for @unitTHa.
  ///
  /// In ka, this message translates to:
  /// **'ტ/ჰა'**
  String get unitTHa;

  /// No description provided for @compareAction.
  ///
  /// In ka, this message translates to:
  /// **'შედარება'**
  String get compareAction;

  /// No description provided for @compareTitle.
  ///
  /// In ka, this message translates to:
  /// **'ბტკ-ების შედარება'**
  String get compareTitle;

  /// No description provided for @compareOnlyDifferences.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ განსხვავებები'**
  String get compareOnlyDifferences;

  /// No description provided for @compareNoDifferences.
  ///
  /// In ka, this message translates to:
  /// **'განსხვავება არ არის'**
  String get compareNoDifferences;

  /// No description provided for @compareLegend.
  ///
  /// In ka, this message translates to:
  /// **'— არ არის შევსებული. ? შევსებულია, მაგრამ ვერ გამოიყენება: რიცხვი ვერ წაიკითხა ან სიღრმის ერთეული არ არის არჩეული. ჯამები მხოლოდ შეყვანილ მნიშვნელობებს აერთიანებს და დასკვნა არ არის.'**
  String get compareLegend;

  /// No description provided for @compareVegRows.
  ///
  /// In ka, this message translates to:
  /// **'მცენარეულობის სტრიქონები'**
  String get compareVegRows;

  /// No description provided for @compareMaxHeight.
  ///
  /// In ka, this message translates to:
  /// **'უდიდესი სიმაღლე (მ)'**
  String get compareMaxHeight;

  /// No description provided for @compareHorizons.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტების რაოდენობა'**
  String get compareHorizons;

  /// No description provided for @compareDeepest.
  ///
  /// In ka, this message translates to:
  /// **'უდიდესი სიღრმე (სმ)'**
  String get compareDeepest;

  /// No description provided for @comparePedomass.
  ///
  /// In ka, this message translates to:
  /// **'პედომასა, ჯამი (ტ/ჰა)'**
  String get comparePedomass;

  /// No description provided for @compareLithomass.
  ///
  /// In ka, this message translates to:
  /// **'ლითომასა, ჯამი (ტ/ჰა)'**
  String get compareLithomass;

  /// No description provided for @compareHydromass.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდრომასა, ჯამი (ტ/ჰა)'**
  String get compareHydromass;

  /// No description provided for @comparePhytomassWet.
  ///
  /// In ka, this message translates to:
  /// **'ფიტომასა სველი, ჯამი (ტ/ჰა)'**
  String get comparePhytomassWet;

  /// No description provided for @comparePhytomassDry.
  ///
  /// In ka, this message translates to:
  /// **'ფიტომასა მშრალი, ჯამი (ტ/ჰა)'**
  String get comparePhytomassDry;

  /// No description provided for @compareTreeWet.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეები სველი, ჯამი (ტ/ჰა)'**
  String get compareTreeWet;

  /// No description provided for @compareTreeDry.
  ///
  /// In ka, this message translates to:
  /// **'ხე-მცენარეები მშრალი, ჯამი (ტ/ჰა)'**
  String get compareTreeDry;

  /// No description provided for @unitCm.
  ///
  /// In ka, this message translates to:
  /// **'სმ'**
  String get unitCm;

  /// No description provided for @depthUnit.
  ///
  /// In ka, this message translates to:
  /// **'სიღრმის ერთეული'**
  String get depthUnit;

  /// No description provided for @depthUnitNotChosen.
  ///
  /// In ka, this message translates to:
  /// **'სიღრმის ერთეული არ არის არჩეული'**
  String get depthUnitNotChosen;

  /// No description provided for @qualityDepthUnitMissing.
  ///
  /// In ka, this message translates to:
  /// **'აირჩიეთ სიღრმის ერთეული: სმ ან მ'**
  String get qualityDepthUnitMissing;

  /// No description provided for @hydromassInfoTitle.
  ///
  /// In ka, this message translates to:
  /// **'ჰიდრომასის განმარტება'**
  String get hydromassInfoTitle;

  /// No description provided for @hydromassWetInfo.
  ///
  /// In ka, this message translates to:
  /// **'სველი (ჰიდ.სვ.): ნიმუშის მასა ველზე აღებისას, მასში არსებული წყლის ჩათვლით.'**
  String get hydromassWetInfo;

  /// No description provided for @hydromassDryInfo.
  ///
  /// In ka, this message translates to:
  /// **'მშრალი (ჰიდ.მშ.): იმავე ნიმუშის მასა გამოშრობის შემდეგ, წყლის გარეშე.'**
  String get hydromassDryInfo;

  /// No description provided for @unitTM3.
  ///
  /// In ka, this message translates to:
  /// **'ტ/მ³'**
  String get unitTM3;

  /// No description provided for @measureUnreadable.
  ///
  /// In ka, this message translates to:
  /// **'ეს მნიშვნელობა რიცხვად ვერ იკითხება'**
  String get measureUnreadable;

  /// No description provided for @measureOutOfRange.
  ///
  /// In ka, this message translates to:
  /// **'მნიშვნელობა მოსალოდნელ ფარგლებს სცდება'**
  String get measureOutOfRange;

  /// No description provided for @measureLegend.
  ///
  /// In ka, this message translates to:
  /// **'ნარინჯისფერი ნიშნავს, რომ მნიშვნელობა შესამოწმებელია. ის მაინც ინახება.'**
  String get measureLegend;

  /// No description provided for @photoLabel.
  ///
  /// In ka, this message translates to:
  /// **'ფოტო'**
  String get photoLabel;

  /// No description provided for @recordMenu.
  ///
  /// In ka, this message translates to:
  /// **'მეტი მოქმედება'**
  String get recordMenu;

  /// No description provided for @fillFromOther.
  ///
  /// In ka, this message translates to:
  /// **'შევსება შაბლონიდან ან ჩანაწერიდან'**
  String get fillFromOther;

  /// No description provided for @fillOnlyEmpty.
  ///
  /// In ka, this message translates to:
  /// **'შეივსება მხოლოდ ცარიელი ველები. უკვე ჩაწერილი მონაცემები არ შეიცვლება.'**
  String get fillOnlyEmpty;

  /// No description provided for @fillAction.
  ///
  /// In ka, this message translates to:
  /// **'შევსება'**
  String get fillAction;

  /// No description provided for @filledCount.
  ///
  /// In ka, this message translates to:
  /// **'შევსებულია: {count}'**
  String filledCount(int count);

  /// No description provided for @nothingFilled.
  ///
  /// In ka, this message translates to:
  /// **'შესავსები ცარიელი ველი ვერ მოიძებნა'**
  String get nothingFilled;

  /// No description provided for @nothingToReuse.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონი ან სხვა ჩანაწერი ჯერ არ არის'**
  String get nothingToReuse;

  /// No description provided for @templates.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონები'**
  String get templates;

  /// No description provided for @recentRecords.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო ჩანაწერები'**
  String get recentRecords;

  /// No description provided for @recordSaveAsTemplate.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონად შენახვა'**
  String get recordSaveAsTemplate;

  /// No description provided for @templateName.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონის სახელი'**
  String get templateName;

  /// No description provided for @templateDefaultName.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონი {time}'**
  String templateDefaultName(String time);

  /// No description provided for @recordTemplateSaved.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონი შენახულია'**
  String get recordTemplateSaved;

  /// No description provided for @templateSaveFailed.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონი ვერ შეინახა'**
  String get templateSaveFailed;

  /// No description provided for @deleteTemplate.
  ///
  /// In ka, this message translates to:
  /// **'შაბლონის წაშლა'**
  String get deleteTemplate;

  /// No description provided for @revertChanges.
  ///
  /// In ka, this message translates to:
  /// **'ცვლილებების გაუქმება'**
  String get revertChanges;

  /// No description provided for @revertMessage.
  ///
  /// In ka, this message translates to:
  /// **'ფორმა დაუბრუნდება იმ მდგომარეობას, რომელშიც გახსენით. ფოტოებზე ეს არ მოქმედებს.'**
  String get revertMessage;

  /// No description provided for @revertAction.
  ///
  /// In ka, this message translates to:
  /// **'აღდგენა'**
  String get revertAction;

  /// No description provided for @exitSaveFailed.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო ცვლილებები ვერ შეინახა. თუ გახვალთ, ისინი შეიძლება დაიკარგოს.'**
  String get exitSaveFailed;

  /// No description provided for @qualityTitle.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერის შემოწმება'**
  String get qualityTitle;

  /// No description provided for @qualityNoNotes.
  ///
  /// In ka, this message translates to:
  /// **'შენიშვნები არ არის'**
  String get qualityNoNotes;

  /// No description provided for @lastEdited.
  ///
  /// In ka, this message translates to:
  /// **'ბოლო ცვლილება: {time}'**
  String lastEdited(String time);

  /// No description provided for @unfinishedRecord.
  ///
  /// In ka, this message translates to:
  /// **'დაუსრულებელი'**
  String get unfinishedRecord;

  /// No description provided for @qualityMissingLocation.
  ///
  /// In ka, this message translates to:
  /// **'ადგილმდებარეობა არ არის შევსებული'**
  String get qualityMissingLocation;

  /// No description provided for @qualityMissingCoords.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატები არ არის შევსებული'**
  String get qualityMissingCoords;

  /// No description provided for @qualityBadCoords.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატები დასაშვებ ფარგლებს სცდება'**
  String get qualityBadCoords;

  /// No description provided for @qualityFutureDate.
  ///
  /// In ka, this message translates to:
  /// **'თარიღი მომავალშია'**
  String get qualityFutureDate;

  /// No description provided for @qualityUnreadable.
  ///
  /// In ka, this message translates to:
  /// **'{field}: რიცხვად ვერ იკითხება'**
  String qualityUnreadable(String field);

  /// No description provided for @qualityOutOfRange.
  ///
  /// In ka, this message translates to:
  /// **'{field}: მოსალოდნელ ფარგლებს სცდება'**
  String qualityOutOfRange(String field);

  /// No description provided for @qualityDryAboveWet.
  ///
  /// In ka, this message translates to:
  /// **'{field}: მშრალი მასა სველზე მეტია'**
  String qualityDryAboveWet(String field);

  /// No description provided for @qualityTotalMismatch.
  ///
  /// In ka, this message translates to:
  /// **'{field}: არ ემთხვევა ნაწილების ჯამს ({sum})'**
  String qualityTotalMismatch(String field, String sum);

  /// No description provided for @qualityRow.
  ///
  /// In ka, this message translates to:
  /// **'სტრიქონი {row}. {text}'**
  String qualityRow(int row, String text);

  /// No description provided for @photoCaption.
  ///
  /// In ka, this message translates to:
  /// **'წარწერა'**
  String get photoCaption;

  /// No description provided for @photoCaptionFailed.
  ///
  /// In ka, this message translates to:
  /// **'წარწერა ვერ შეინახა'**
  String get photoCaptionFailed;

  /// No description provided for @photosGeneral.
  ///
  /// In ka, this message translates to:
  /// **'ზოგადი'**
  String get photosGeneral;

  /// No description provided for @gpsWaitingFix.
  ///
  /// In ka, this message translates to:
  /// **'GPS სიგნალს ველოდები…'**
  String get gpsWaitingFix;

  /// No description provided for @gpsSignalLost.
  ///
  /// In ka, this message translates to:
  /// **'GPS სიგნალი დაიკარგა. ჩაწერილი წერტილები შენახულია.'**
  String get gpsSignalLost;

  /// No description provided for @trackNotificationTitle.
  ///
  /// In ka, this message translates to:
  /// **'BTC Field App'**
  String get trackNotificationTitle;

  /// No description provided for @trackNotificationText.
  ///
  /// In ka, this message translates to:
  /// **'GPS ტრეკი იწერება'**
  String get trackNotificationText;

  /// No description provided for @trackSaveFailed.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკის წერტილები ვერ შეინახა'**
  String get trackSaveFailed;

  /// No description provided for @trackStartFailed.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკის ჩაწერა ვერ დაიწყო'**
  String get trackStartFailed;

  /// No description provided for @trackInterrupted.
  ///
  /// In ka, this message translates to:
  /// **'ჩაწერა შეწყდა'**
  String get trackInterrupted;

  /// No description provided for @trackInterruptedTitle.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკის ჩაწერა შეწყდა'**
  String get trackInterruptedTitle;

  /// No description provided for @trackInterruptedMessage.
  ///
  /// In ka, this message translates to:
  /// **'შენახულია წერტილები: {count}. გავაგრძელოთ ჩაწერა თუ დავასრულოთ ტრეკი?'**
  String trackInterruptedMessage(int count);

  /// No description provided for @continueAction.
  ///
  /// In ka, this message translates to:
  /// **'გაგრძელება'**
  String get continueAction;

  /// No description provided for @finishAction.
  ///
  /// In ka, this message translates to:
  /// **'დასრულება'**
  String get finishAction;

  /// No description provided for @tracksUnreadable.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკები ვერ წაიკითხა: {count}. მონაცემები არ წაშლილა.'**
  String tracksUnreadable(int count);

  /// No description provided for @trackPointsCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} წერტ.'**
  String trackPointsCount(int count);

  /// No description provided for @accuracyValue.
  ///
  /// In ka, this message translates to:
  /// **'სიზუსტე ±{meters} მ'**
  String accuracyValue(int meters);

  /// No description provided for @linkTrack.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკთან დაკავშირება'**
  String get linkTrack;

  /// No description provided for @linkedTrack.
  ///
  /// In ka, this message translates to:
  /// **'ტრეკი #{id}'**
  String linkedTrack(String id);

  /// No description provided for @unlinkTrack.
  ///
  /// In ka, this message translates to:
  /// **'კავშირის მოხსნა'**
  String get unlinkTrack;

  /// No description provided for @qualityLowAccuracy.
  ///
  /// In ka, this message translates to:
  /// **'კოორდინატების სიზუსტე დაბალია (±{meters} მ)'**
  String qualityLowAccuracy(int meters);

  /// No description provided for @recordGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფი'**
  String get recordGroup;

  /// No description provided for @recordGroupHint.
  ///
  /// In ka, this message translates to:
  /// **'მაგ. რაჭა 2026'**
  String get recordGroupHint;

  /// No description provided for @noGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის გარეშე'**
  String get noGroup;

  /// No description provided for @noGroupsYet.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფები ჯერ არ არის'**
  String get noGroupsYet;

  /// No description provided for @setGroup.
  ///
  /// In ka, this message translates to:
  /// **'ჯგუფის მინიჭება'**
  String get setGroup;

  /// No description provided for @setGroupHelp.
  ///
  /// In ka, this message translates to:
  /// **'ცარიელი ველი ჯგუფს მოხსნის'**
  String get setGroupHelp;

  /// No description provided for @filterTitle.
  ///
  /// In ka, this message translates to:
  /// **'ფილტრი'**
  String get filterTitle;

  /// No description provided for @filterClear.
  ///
  /// In ka, this message translates to:
  /// **'გასუფთავება'**
  String get filterClear;

  /// No description provided for @filterShown.
  ///
  /// In ka, this message translates to:
  /// **'ჩანს {shown} / {total}'**
  String filterShown(int shown, int total);

  /// No description provided for @filterUnfinished.
  ///
  /// In ka, this message translates to:
  /// **'მხოლოდ დაუსრულებელი'**
  String get filterUnfinished;

  /// No description provided for @filterAnyDate.
  ///
  /// In ka, this message translates to:
  /// **'ნებისმიერი თარიღი'**
  String get filterAnyDate;

  /// No description provided for @recordsInView.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწერები ხილულ არეში'**
  String get recordsInView;

  /// No description provided for @showOnMap.
  ///
  /// In ka, this message translates to:
  /// **'რუკაზე ჩვენება'**
  String get showOnMap;

  /// No description provided for @onlyLocalStorageHere.
  ///
  /// In ka, this message translates to:
  /// **'ამ მოწყობილობაზე ანგარიში და ღრუბელი მიუწვდომელია. ჩანაწერები მხოლოდ აქ ინახება, ამიტომ დროდადრო გააკეთე სარეზერვო ასლი.'**
  String get onlyLocalStorageHere;

  /// No description provided for @compareTiers.
  ///
  /// In ka, this message translates to:
  /// **'იარუსები'**
  String get compareTiers;

  /// No description provided for @compareHorizonOrder.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტების რიგი'**
  String get compareHorizonOrder;

  /// No description provided for @statsVegStructure.
  ///
  /// In ka, this message translates to:
  /// **'მცენარეულობის სტრუქტურა'**
  String get statsVegStructure;

  /// No description provided for @statsSoilHorizons.
  ///
  /// In ka, this message translates to:
  /// **'ნიადაგის ჰორიზონტები'**
  String get statsSoilHorizons;

  /// No description provided for @statsRecordsWithData.
  ///
  /// In ka, this message translates to:
  /// **'მონაცემი აქვს {count} ჩანაწერს {total}-დან'**
  String statsRecordsWithData(Object count, Object total);

  /// No description provided for @statsTierRecords.
  ///
  /// In ka, this message translates to:
  /// **'ჩანაწ.'**
  String get statsTierRecords;

  /// No description provided for @statsTierSpecies.
  ///
  /// In ka, this message translates to:
  /// **'სახეობა'**
  String get statsTierSpecies;

  /// No description provided for @statsNoTier.
  ///
  /// In ka, this message translates to:
  /// **'იარუსის გარეშე'**
  String get statsNoTier;

  /// No description provided for @statsSpeciesFrequency.
  ///
  /// In ka, this message translates to:
  /// **'სახეობები (რამდენ ჩანაწერშია)'**
  String get statsSpeciesFrequency;

  /// No description provided for @statsHorizonFrequency.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტები (რამდენ ჩანაწერშია)'**
  String get statsHorizonFrequency;

  /// No description provided for @statsHorizonOrders.
  ///
  /// In ka, this message translates to:
  /// **'ჰორიზონტების რიგი (რამდენ ჩანაწერშია)'**
  String get statsHorizonOrders;

  /// No description provided for @statsMoreItems.
  ///
  /// In ka, this message translates to:
  /// **'და კიდევ {count}'**
  String statsMoreItems(Object count);

  /// No description provided for @statsAnalysisNote.
  ///
  /// In ka, this message translates to:
  /// **'ეს შეყვანილი მონაცემების დათვლაა და არა დასკვნა. სხვანაირად დაწერილი სახელი ცალკე ითვლება. „?“ ნიშნავს, რომ მნიშვნელობა შევსებულია, მაგრამ ვერ გამოიყენება.'**
  String get statsAnalysisNote;

  /// No description provided for @statsGeomass.
  ///
  /// In ka, this message translates to:
  /// **'გეომასა'**
  String get statsGeomass;

  /// No description provided for @statsGeomassTotals.
  ///
  /// In ka, this message translates to:
  /// **'ჯამები ჩანაწერების მიხედვით: უმცირესი და უდიდესი'**
  String get statsGeomassTotals;

  /// No description provided for @statsGeomassComponent.
  ///
  /// In ka, this message translates to:
  /// **'მასა'**
  String get statsGeomassComponent;

  /// No description provided for @statsGeomassRange.
  ///
  /// In ka, this message translates to:
  /// **'დიაპაზონი'**
  String get statsGeomassRange;

  /// No description provided for @statsDepthLayers.
  ///
  /// In ka, this message translates to:
  /// **'სიღრმის ფენები (სმ, მასები ტ/ჰა)'**
  String get statsDepthLayers;

  /// No description provided for @statsDepthLayer.
  ///
  /// In ka, this message translates to:
  /// **'ფენა'**
  String get statsDepthLayer;

  /// No description provided for @statsDepthUnknown.
  ///
  /// In ka, this message translates to:
  /// **'უცნობი'**
  String get statsDepthUnknown;

  /// No description provided for @statsPhytomassWet.
  ///
  /// In ka, this message translates to:
  /// **'ფიტომასა სველი'**
  String get statsPhytomassWet;

  /// No description provided for @statsPhytomassDry.
  ///
  /// In ka, this message translates to:
  /// **'ფიტომასა მშრალი'**
  String get statsPhytomassDry;

  /// No description provided for @statsGeomassNote.
  ///
  /// In ka, this message translates to:
  /// **'ფენები ზუსტად შეყვანილი სიღრმით ჯგუფდება. სიღრმე უცნობია, თუ არ არის შევსებული, ვერ წაიკითხა ან ერთეული არ არის არჩეული. ჯამში ერთი წაუკითხავი მნიშვნელობა მთელ ჯამს „?“-ად აქცევს.'**
  String get statsGeomassNote;

  /// No description provided for @statsAltitudeBands.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლის ზოლები (მ)'**
  String get statsAltitudeBands;

  /// No description provided for @statsAltitudeBand.
  ///
  /// In ka, this message translates to:
  /// **'ზოლი'**
  String get statsAltitudeBand;

  /// No description provided for @statsNoAltitude.
  ///
  /// In ka, this message translates to:
  /// **'სიმაღლის გარეშე'**
  String get statsNoAltitude;

  /// No description provided for @statsBandNote.
  ///
  /// In ka, this message translates to:
  /// **'ეს თანაბარი ზოლებია და არა სიმაღლებრივი სარტყლები. მასები ჩანაწერების ჯამების უმცირესი და უდიდესი მნიშვნელობაა (ტ/ჰა).'**
  String get statsBandNote;

  /// No description provided for @statsByYear.
  ///
  /// In ka, this message translates to:
  /// **'წლების მიხედვით'**
  String get statsByYear;

  /// No description provided for @statsYear.
  ///
  /// In ka, this message translates to:
  /// **'წელი'**
  String get statsYear;

  /// No description provided for @statsRepeatedPlaces.
  ///
  /// In ka, this message translates to:
  /// **'რამდენჯერმე აღწერილი ადგილები'**
  String get statsRepeatedPlaces;

  /// No description provided for @statsRepeatedCount.
  ///
  /// In ka, this message translates to:
  /// **'{count} ჩანაწერი, {first} – {last}'**
  String statsRepeatedCount(Object count, Object first, Object last);

  /// No description provided for @statsTimeNote.
  ///
  /// In ka, this message translates to:
  /// **'ადგილი ემთხვევა მხოლოდ ერთნაირად დაწერილი ადგილმდებარეობით. ცხრილი აჩვენებს, რა არის შეყვანილი, და ცვლილებას არ ადასტურებს: წლებს შორის შეიძლება სხვადასხვა ადგილი იყოს აღწერილი. დააჭირე ადგილს შესადარებლად.'**
  String get statsTimeNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ka'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ka':
      return AppLocalizationsKa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
