import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'StopScam'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In ru, this message translates to:
  /// **'Проверка'**
  String get scan;

  /// No description provided for @history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get history;

  /// No description provided for @education.
  ///
  /// In ru, this message translates to:
  /// **'Полезное'**
  String get education;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @welcome.
  ///
  /// In ru, this message translates to:
  /// **'Спокойствие начинается с проверки'**
  String get welcome;

  /// No description provided for @tagline.
  ///
  /// In ru, this message translates to:
  /// **'Ваш помощник в цифровой безопасности'**
  String get tagline;

  /// No description provided for @heroTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сначала проверьте.\nПотом доверяйте.'**
  String get heroTitle;

  /// No description provided for @heroBody.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подозрительное сообщение или ссылку с помощью AI.'**
  String get heroBody;

  /// No description provided for @ready.
  ///
  /// In ru, this message translates to:
  /// **'Проверка по запросу'**
  String get ready;

  /// No description provided for @checkMessage.
  ///
  /// In ru, this message translates to:
  /// **'Проверить сообщение'**
  String get checkMessage;

  /// No description provided for @checkLink.
  ///
  /// In ru, this message translates to:
  /// **'Проверить ссылку'**
  String get checkLink;

  /// No description provided for @totalScans.
  ///
  /// In ru, this message translates to:
  /// **'Всего проверок'**
  String get totalScans;

  /// No description provided for @highRisks.
  ///
  /// In ru, this message translates to:
  /// **'Высокий риск'**
  String get highRisks;

  /// No description provided for @recent.
  ///
  /// In ru, this message translates to:
  /// **'Последние проверки'**
  String get recent;

  /// No description provided for @seeAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get seeAll;

  /// No description provided for @dailyTip.
  ///
  /// In ru, this message translates to:
  /// **'Совет по безопасности'**
  String get dailyTip;

  /// No description provided for @tipBody.
  ///
  /// In ru, this message translates to:
  /// **'Никому не сообщайте SMS-коды — даже если собеседник представляется сотрудником банка.'**
  String get tipBody;

  /// No description provided for @scannerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверим вместе'**
  String get scannerTitle;

  /// No description provided for @scannerSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте текст. Мы объясним признаки риска.'**
  String get scannerSubtitle;

  /// No description provided for @textMode.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get textMode;

  /// No description provided for @linkMode.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка'**
  String get linkMode;

  /// No description provided for @textHint.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте подозрительное сообщение…'**
  String get textHint;

  /// No description provided for @urlHint.
  ///
  /// In ru, this message translates to:
  /// **'example.com или https://…'**
  String get urlHint;

  /// No description provided for @paste.
  ///
  /// In ru, this message translates to:
  /// **'Вставить'**
  String get paste;

  /// No description provided for @clear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get clear;

  /// No description provided for @startScan.
  ///
  /// In ru, this message translates to:
  /// **'Начать проверку'**
  String get startScan;

  /// No description provided for @analyzing.
  ///
  /// In ru, this message translates to:
  /// **'Анализируем…'**
  String get analyzing;

  /// No description provided for @analyzingBody.
  ///
  /// In ru, this message translates to:
  /// **'Изучаем контекст, признаки давления и подозрительные ссылки.'**
  String get analyzingBody;

  /// No description provided for @emptyInput.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение или ссылку.'**
  String get emptyInput;

  /// No description provided for @invalidUrl.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный адрес сайта с http:// или https://.'**
  String get invalidUrl;

  /// No description provided for @tooLong.
  ///
  /// In ru, this message translates to:
  /// **'Текст слишком длинный. Максимум 12 000 символов.'**
  String get tooLong;

  /// No description provided for @disclaimer.
  ///
  /// In ru, this message translates to:
  /// **'AI может ошибаться. Не передавайте пароли, SMS-коды, данные банковских карт и другую конфиденциальную информацию.'**
  String get disclaimer;

  /// No description provided for @privacyNotice.
  ///
  /// In ru, this message translates to:
  /// **'Для анализа содержимое отправляется вашему серверу и AI-провайдеру. Удалите личные данные перед отправкой.'**
  String get privacyNotice;

  /// No description provided for @mockBanner.
  ///
  /// In ru, this message translates to:
  /// **'Тестовый режим · результат — пример'**
  String get mockBanner;

  /// No description provided for @result.
  ///
  /// In ru, this message translates to:
  /// **'Результат проверки'**
  String get result;

  /// No description provided for @riskScore.
  ///
  /// In ru, this message translates to:
  /// **'Оценка риска'**
  String get riskScore;

  /// No description provided for @safe.
  ///
  /// In ru, this message translates to:
  /// **'Явных признаков мало'**
  String get safe;

  /// No description provided for @low.
  ///
  /// In ru, this message translates to:
  /// **'Низкий риск'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In ru, this message translates to:
  /// **'Средний риск'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In ru, this message translates to:
  /// **'Высокий риск'**
  String get high;

  /// No description provided for @critical.
  ///
  /// In ru, this message translates to:
  /// **'Критический риск'**
  String get critical;

  /// No description provided for @reasons.
  ///
  /// In ru, this message translates to:
  /// **'На что обратить внимание'**
  String get reasons;

  /// No description provided for @recommendations.
  ///
  /// In ru, this message translates to:
  /// **'Что делать дальше'**
  String get recommendations;

  /// No description provided for @sourceText.
  ///
  /// In ru, this message translates to:
  /// **'Исходный текст'**
  String get sourceText;

  /// No description provided for @scanAgain.
  ///
  /// In ru, this message translates to:
  /// **'Проверить ещё'**
  String get scanAgain;

  /// No description provided for @goHome.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get goHome;

  /// No description provided for @copyResult.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать результат'**
  String get copyResult;

  /// No description provided for @copied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get copied;

  /// No description provided for @historyTitle.
  ///
  /// In ru, this message translates to:
  /// **'История проверок'**
  String get historyTitle;

  /// No description provided for @emptyHistory.
  ///
  /// In ru, this message translates to:
  /// **'Здесь пока нет проверок.'**
  String get emptyHistory;

  /// No description provided for @emptyHistoryBody.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте первое сообщение — результат сохранится здесь.'**
  String get emptyHistoryBody;

  /// No description provided for @clearHistory.
  ///
  /// In ru, this message translates to:
  /// **'Очистить историю'**
  String get clearHistory;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @confirmClear.
  ///
  /// In ru, this message translates to:
  /// **'Удалить все проверки с этого устройства? Отменить это действие нельзя.'**
  String get confirmClear;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @kazakh.
  ///
  /// In ru, this message translates to:
  /// **'Қазақша'**
  String get kazakh;

  /// No description provided for @theme.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get theme;

  /// No description provided for @systemTheme.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get darkTheme;

  /// No description provided for @about.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get about;

  /// No description provided for @version.
  ///
  /// In ru, this message translates to:
  /// **'2.2.0'**
  String get version;

  /// No description provided for @privacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get privacy;

  /// No description provided for @aboutBody.
  ///
  /// In ru, this message translates to:
  /// **'StopScam помогает замечать признаки мошенничества и принимать взвешенные решения. Оценка основана на предоставленном тексте, а не на проверке личности отправителя.'**
  String get aboutBody;

  /// No description provided for @next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get skip;

  /// No description provided for @begin.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get begin;

  /// No description provided for @onboard1.
  ///
  /// In ru, this message translates to:
  /// **'Защита от мошенников'**
  String get onboard1;

  /// No description provided for @onboardBody1.
  ///
  /// In ru, this message translates to:
  /// **'StopScam помогает распознавать подозрительные сообщения и ссылки.'**
  String get onboardBody1;

  /// No description provided for @onboard2.
  ///
  /// In ru, this message translates to:
  /// **'Понятный AI-анализ'**
  String get onboard2;

  /// No description provided for @onboardBody2.
  ///
  /// In ru, this message translates to:
  /// **'Искусственный интеллект ищет признаки фишинга, давления и обмана.'**
  String get onboardBody2;

  /// No description provided for @onboard3.
  ///
  /// In ru, this message translates to:
  /// **'Будьте на шаг впереди'**
  String get onboard3;

  /// No description provided for @onboardBody3.
  ///
  /// In ru, this message translates to:
  /// **'Получайте объяснение риска и рекомендации. Решение всегда остаётся за вами.'**
  String get onboardBody3;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Попробовать снова'**
  String get retry;

  /// No description provided for @errorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету. Проверьте соединение и попробуйте снова.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Сервис не ответил вовремя. Попробуйте ещё раз.'**
  String get errorTimeout;

  /// No description provided for @errorAuth.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить доступ устройства к серверу.'**
  String get errorAuth;

  /// No description provided for @errorRate.
  ///
  /// In ru, this message translates to:
  /// **'Лимит запросов исчерпан. Повторите позже.'**
  String get errorRate;

  /// No description provided for @errorServer.
  ///
  /// In ru, this message translates to:
  /// **'Сервис временно недоступен. Попробуйте позже.'**
  String get errorServer;

  /// No description provided for @errorJson.
  ///
  /// In ru, this message translates to:
  /// **'Получен неполный ответ. Попробуйте выполнить проверку ещё раз.'**
  String get errorJson;

  /// No description provided for @errorConfig.
  ///
  /// In ru, this message translates to:
  /// **'Сервис анализа ещё не настроен. Проверьте адрес сервера и его настройки AI.'**
  String get errorConfig;

  /// No description provided for @errorUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить анализ. Попробуйте снова.'**
  String get errorUnknown;

  /// No description provided for @errorStorage.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить данные на устройстве. Освободите место и повторите.'**
  String get errorStorage;

  /// No description provided for @saveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Результат получен, но не сохранён в историю.'**
  String get saveFailed;

  /// No description provided for @phishing.
  ///
  /// In ru, this message translates to:
  /// **'Фишинг'**
  String get phishing;

  /// No description provided for @fakeBank.
  ///
  /// In ru, this message translates to:
  /// **'Поддельное обращение банка'**
  String get fakeBank;

  /// No description provided for @socialEngineering.
  ///
  /// In ru, this message translates to:
  /// **'Социальная инженерия'**
  String get socialEngineering;

  /// No description provided for @investmentScam.
  ///
  /// In ru, this message translates to:
  /// **'Инвестиционная схема'**
  String get investmentScam;

  /// No description provided for @fakeDelivery.
  ///
  /// In ru, this message translates to:
  /// **'Поддельная доставка'**
  String get fakeDelivery;

  /// No description provided for @accountTheft.
  ///
  /// In ru, this message translates to:
  /// **'Кража аккаунта'**
  String get accountTheft;

  /// No description provided for @maliciousLink.
  ///
  /// In ru, this message translates to:
  /// **'Подозрительная ссылка'**
  String get maliciousLink;

  /// No description provided for @suspiciousMessage.
  ///
  /// In ru, this message translates to:
  /// **'Подозрительное сообщение'**
  String get suspiciousMessage;

  /// No description provided for @unknown.
  ///
  /// In ru, this message translates to:
  /// **'Не определено'**
  String get unknown;

  /// No description provided for @educationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Знания — ваша защита'**
  String get educationTitle;

  /// No description provided for @educationSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Короткие советы для безопасной цифровой жизни.'**
  String get educationSubtitle;

  /// No description provided for @article1.
  ///
  /// In ru, this message translates to:
  /// **'Как распознать фишинг'**
  String get article1;

  /// No description provided for @body1.
  ///
  /// In ru, this message translates to:
  /// **'Фишинг — попытка выманить пароль, код или деньги, выдавая себя за знакомый сервис.\n\nОбратите внимание на срочность, угрозы блокировки и просьбы раскрыть секреты. Имя отправителя можно подделать.\n\nОткройте нужное приложение самостоятельно или наберите известный адрес сайта. Проверьте запрос через официальный канал, который вы нашли независимо от сообщения.'**
  String get body1;

  /// No description provided for @article2.
  ///
  /// In ru, this message translates to:
  /// **'Если вы сообщили SMS-код'**
  String get article2;

  /// No description provided for @body2.
  ///
  /// In ru, this message translates to:
  /// **'Прекратите разговор и не сообщайте новые коды.\n\nОткройте официальный сервис, для которого был код. Смените пароль, завершите чужие сеансы и включите двухфакторную защиту.\n\nЕсли код связан с банком, срочно свяжитесь с банком через его приложение или номер на карте. Сообщите о возможном захвате аккаунта и попросите проверить операции. Сохраните переписку.'**
  String get body2;

  /// No description provided for @article3.
  ///
  /// In ru, this message translates to:
  /// **'Как проверить ссылку'**
  String get article3;

  /// No description provided for @body3.
  ///
  /// In ru, this message translates to:
  /// **'Не открывайте ссылку, чтобы просто проверить её.\n\nСравните домен с известным официальным адресом. Лишние буквы, подмена символов и длинные цепочки поддоменов требуют внимания. HTTPS шифрует соединение, но не доказывает честность сайта.\n\nСокращённая ссылка скрывает конечный адрес. Найдите нужную страницу самостоятельно через официальное приложение.'**
  String get body3;

  /// No description provided for @article4.
  ///
  /// In ru, this message translates to:
  /// **'Мошенники от имени банка'**
  String get article4;

  /// No description provided for @body4.
  ///
  /// In ru, this message translates to:
  /// **'Просьба перевести деньги на «безопасный счёт», назвать код или установить программу удалённого доступа — серьёзный тревожный сигнал.\n\nПрервите разговор. Свяжитесь с банком через официальное приложение или номер на карте. Не перезванивайте по номеру из подозрительного сообщения.\n\nЕсли вы уже передали данные карты, попросите банк заблокировать её и проверить операции.'**
  String get body4;

  /// No description provided for @article5.
  ///
  /// In ru, this message translates to:
  /// **'Обман в WhatsApp и Telegram'**
  String get article5;

  /// No description provided for @body5.
  ///
  /// In ru, this message translates to:
  /// **'Знакомый внезапно просит денег? Его аккаунт могли взломать. Свяжитесь с ним другим способом.\n\nНе сообщайте коды входа и не сканируйте QR-коды для чужой «проверки». Проверяйте список подключённых устройств.\n\nВключите двухэтапную проверку и ограничьте видимость личной информации. Подозрительные сообщения можно пожаловаться и заблокировать средствами мессенджера.'**
  String get body5;

  /// No description provided for @article6.
  ///
  /// In ru, this message translates to:
  /// **'Фальшивые инвестиции'**
  String get article6;

  /// No description provided for @body6.
  ///
  /// In ru, this message translates to:
  /// **'Гарантированная высокая доходность, давление «только сегодня» и просьба внести дополнительный платёж для вывода денег — тревожные признаки.\n\nПроверяйте компанию и её разрешения через официальный реестр соответствующего регулятора. Отзывы и красивые графики легко подделать.\n\nНе отправляйте новые деньги ради возврата уже потерянных. Сохраните доказательства и обратитесь в банк и правоохранительные органы.'**
  String get body6;

  /// No description provided for @article7.
  ///
  /// In ru, this message translates to:
  /// **'Правила цифровой безопасности'**
  String get article7;

  /// No description provided for @body7.
  ///
  /// In ru, this message translates to:
  /// **'Используйте уникальные пароли и менеджер паролей. Включайте двухфакторную аутентификацию, где она доступна.\n\nОбновляйте систему и приложения. Устанавливайте приложения из официальных источников и проверяйте разрешения.\n\nНе торопитесь отвечать на неожиданные запросы. Проверяйте личность собеседника через независимый канал. Делитесь этими правилами с близкими.'**
  String get body7;

  /// No description provided for @savedLanguage.
  ///
  /// In ru, this message translates to:
  /// **'AI-объяснение сохранено на языке исходной проверки.'**
  String get savedLanguage;

  /// No description provided for @insufficientData.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно данных'**
  String get insufficientData;

  /// No description provided for @checkPhone.
  ///
  /// In ru, this message translates to:
  /// **'Проверить номер'**
  String get checkPhone;

  /// No description provided for @checkQr.
  ///
  /// In ru, this message translates to:
  /// **'Сканировать QR'**
  String get checkQr;

  /// No description provided for @incomingCall.
  ///
  /// In ru, this message translates to:
  /// **'Входящий звонок'**
  String get incomingCall;

  /// No description provided for @phoneHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, +7 700 123 45 67'**
  String get phoneHint;

  /// No description provided for @invalidPhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите действительный номер с кодом страны'**
  String get invalidPhone;

  /// No description provided for @phoneContext.
  ///
  /// In ru, this message translates to:
  /// **'Что сказал собеседник? (необязательно)'**
  String get phoneContext;

  /// No description provided for @phoneDescription.
  ///
  /// In ru, this message translates to:
  /// **'Проверка репутации номера и содержания разговора. Цифры номера сами по себе не доказывают мошенничество.'**
  String get phoneDescription;

  /// No description provided for @noReputation.
  ///
  /// In ru, this message translates to:
  /// **'Для этого номера нет доступных данных репутации. Определить риск по одному номеру нельзя.'**
  String get noReputation;

  /// No description provided for @reputationOnly.
  ///
  /// In ru, this message translates to:
  /// **'Показаны данные службы репутации. Они не подтверждают личность звонящего и не являются численной оценкой риска.'**
  String get reputationOnly;

  /// No description provided for @repUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Репутация неизвестна'**
  String get repUnknown;

  /// No description provided for @repClear.
  ///
  /// In ru, this message translates to:
  /// **'Служба не отметила угрозу'**
  String get repClear;

  /// No description provided for @repFlagged.
  ///
  /// In ru, this message translates to:
  /// **'Служба отметила угрозу'**
  String get repFlagged;

  /// No description provided for @repUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Служба репутации недоступна'**
  String get repUnavailable;

  /// No description provided for @repNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Служба репутации не подключена'**
  String get repNotConfigured;

  /// No description provided for @countryCode.
  ///
  /// In ru, this message translates to:
  /// **'Код страны'**
  String get countryCode;

  /// No description provided for @confidence.
  ///
  /// In ru, this message translates to:
  /// **'Уверенность анализа'**
  String get confidence;

  /// No description provided for @confidenceNote.
  ///
  /// In ru, this message translates to:
  /// **'Это уверенность модели в выводе, а не вероятность мошенничества.'**
  String get confidenceNote;

  /// No description provided for @lowConfidence.
  ///
  /// In ru, this message translates to:
  /// **'Низкая уверенность: данных для надёжного вывода недостаточно.'**
  String get lowConfidence;

  /// No description provided for @localAssessment.
  ///
  /// In ru, this message translates to:
  /// **'Локальные данные; AI не использовался'**
  String get localAssessment;

  /// No description provided for @aiAssessment.
  ///
  /// In ru, this message translates to:
  /// **'AI-анализ'**
  String get aiAssessment;

  /// No description provided for @legacyAssessment.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённый результат предыдущей версии'**
  String get legacyAssessment;

  /// No description provided for @qrSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Наведите камеру на QR-код. Ссылки и платежи не открываются автоматически.'**
  String get qrSubtitle;

  /// No description provided for @qrDecoded.
  ///
  /// In ru, this message translates to:
  /// **'QR-код распознан'**
  String get qrDecoded;

  /// No description provided for @qrInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось распознать содержимое QR-кода'**
  String get qrInvalid;

  /// No description provided for @qrPermission.
  ///
  /// In ru, this message translates to:
  /// **'Для сканирования нужен доступ к камере. Разрешите его в настройках приложения.'**
  String get qrPermission;

  /// No description provided for @qrCameraError.
  ///
  /// In ru, this message translates to:
  /// **'Камера недоступна. Закройте другие приложения с камерой и повторите.'**
  String get qrCameraError;

  /// No description provided for @openSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get openSettings;

  /// No description provided for @flash.
  ///
  /// In ru, this message translates to:
  /// **'Фонарик'**
  String get flash;

  /// No description provided for @qrWifi.
  ///
  /// In ru, this message translates to:
  /// **'Wi-Fi: пароль и имя сети скрыты'**
  String get qrWifi;

  /// No description provided for @qrContact.
  ///
  /// In ru, this message translates to:
  /// **'Контакт: личные данные скрыты'**
  String get qrContact;

  /// No description provided for @qrPayment.
  ///
  /// In ru, this message translates to:
  /// **'Платёж'**
  String get qrPayment;

  /// No description provided for @qrEmail.
  ///
  /// In ru, this message translates to:
  /// **'Электронное письмо'**
  String get qrEmail;

  /// No description provided for @qrSms.
  ///
  /// In ru, this message translates to:
  /// **'SMS'**
  String get qrSms;

  /// No description provided for @qrUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный формат'**
  String get qrUnknown;

  /// No description provided for @qrInsufficient.
  ///
  /// In ru, this message translates to:
  /// **'QR-код декодирован локально. Его безопасность не подтверждена. Конфиденциальные данные Wi-Fi и контактов не отправляются в AI.'**
  String get qrInsufficient;

  /// No description provided for @recipient.
  ///
  /// In ru, this message translates to:
  /// **'Получатель'**
  String get recipient;

  /// No description provided for @amount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма'**
  String get amount;

  /// No description provided for @callsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Защита от звонков'**
  String get callsTitle;

  /// No description provided for @callsBody.
  ///
  /// In ru, this message translates to:
  /// **'Android передаёт приложению отдельные входящие звонки после вашего согласия. Решение принимается по локальному кэшу, без AI и сети. Неизвестные номера пропускаются. Контакты и полный журнал звонков не читаются.'**
  String get callsBody;

  /// No description provided for @callsEnable.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать StopScam для проверки звонков'**
  String get callsEnable;

  /// No description provided for @callsEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Проверка звонков включена'**
  String get callsEnabled;

  /// No description provided for @callsDisabled.
  ///
  /// In ru, this message translates to:
  /// **'Проверка звонков выключена'**
  String get callsDisabled;

  /// No description provided for @callsUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Системная роль недоступна. Нужен Android 10 или новее с поддержкой проверки звонков.'**
  String get callsUnsupported;

  /// No description provided for @autoBlock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать подтверждённые угрозы'**
  String get autoBlock;

  /// No description provided for @autoBlockBody.
  ///
  /// In ru, this message translates to:
  /// **'Только подтверждённая отметка службы репутации, уверенность ≥95% и свежий кэш. По умолчанию выключено.'**
  String get autoBlockBody;

  /// No description provided for @notificationsEnable.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить уведомления о звонках'**
  String get notificationsEnable;

  /// No description provided for @notificationsEnabled.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления разрешены'**
  String get notificationsEnabled;

  /// No description provided for @blockedCall.
  ///
  /// In ru, this message translates to:
  /// **'Звонок заблокирован по подтверждённой репутации'**
  String get blockedCall;

  /// No description provided for @allowedCall.
  ///
  /// In ru, this message translates to:
  /// **'Звонок пропущен'**
  String get allowedCall;

  /// No description provided for @fixtureOtp.
  ///
  /// In ru, this message translates to:
  /// **'Тест: запрос кода подтверждения'**
  String get fixtureOtp;

  /// No description provided for @fixtureMoney.
  ///
  /// In ru, this message translates to:
  /// **'Тест: финансовый предлог'**
  String get fixtureMoney;

  /// No description provided for @fixtureUrgency.
  ///
  /// In ru, this message translates to:
  /// **'Тест: давление срочностью'**
  String get fixtureUrgency;

  /// No description provided for @fixtureUrl.
  ///
  /// In ru, this message translates to:
  /// **'Тест: признак подозрительной ссылки'**
  String get fixtureUrl;

  /// No description provided for @fixtureSummary.
  ///
  /// In ru, this message translates to:
  /// **'Отладочный пример по признакам ввода. Это не реальный AI-анализ.'**
  String get fixtureSummary;

  /// No description provided for @mockDetail.
  ///
  /// In ru, this message translates to:
  /// **'Включён режим разработки: оценка выбирается из тестовых сценариев. Отключите USE_MOCK_AI для реальных запросов.'**
  String get mockDetail;

  /// No description provided for @privacyBody.
  ///
  /// In ru, this message translates to:
  /// **'История последних 200 проверок хранится локально. При ручном анализе введённый текст, ссылка, описание разговора или содержимое QR отправляется вашему backend, который обращается к AI-провайдеру. Пароли Wi-Fi и данные контактных QR не отправляются. Номер передаётся службе репутации только при ручной проверке и наличии настроенного backend. Репутация кэшируется до 24 часов. Проверка входящих звонков использует только локальный кэш, не ждёт сети и включается через системное согласие. Приложение не читает контакты, SMS или полный журнал звонков. Не вводите пароли, коды подтверждения и реквизиты карт. Историю можно удалить в настройках. Системное резервное копирование отключено.\n\nЛичная база номеров и жалобы хранятся отдельно от истории, в SQLite на устройстве. Личная база не синхронизируется. Если вы включили обмен жалобами, новые жалобы передают серверу номер и категорию без названия и заметки. Сервер хранит хэш номера и связывает жалобу со случайным идентификатором устройства; сервер также получает IP-адрес при соединении. Выключение обмена прекращает будущую отправку, но не удаляет уже отправленные жалобы. Названия и заметки из личной базы не передаются AI. Экспорт CSV сохраняет номера и заметки в выбранный вами файл. При удалении приложения или его данных локальная база также удаляется.\n\nПомощник при звонке включается вручную после согласия. Аудио не сохраняется и не передаётся. Распознавание и поиск фраз выполняются на устройстве. Расшифровка стирается при остановке, если вы отдельно не включили её локальное зашифрованное сохранение. Сервер получает только запросы обновления словаря. Кнопка проверки с AI отправляет только краткое описание, написанное вами.'**
  String get privacyBody;

  /// No description provided for @openLink.
  ///
  /// In ru, this message translates to:
  /// **'Открыть ссылку'**
  String get openLink;

  /// No description provided for @openLinkWarning.
  ///
  /// In ru, this message translates to:
  /// **'У этой ссылки высокий риск или недостаточно данных. Переход может быть опасен. Открыть всё равно?'**
  String get openLinkWarning;

  /// No description provided for @localSignals.
  ///
  /// In ru, this message translates to:
  /// **'Локальные признаки URL (не доказательство мошенничества)'**
  String get localSignals;

  /// No description provided for @knownSignals.
  ///
  /// In ru, this message translates to:
  /// **'Известных сигналов'**
  String get knownSignals;

  /// No description provided for @numbersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моя база номеров'**
  String get numbersTitle;

  /// No description provided for @numbersNav.
  ///
  /// In ru, this message translates to:
  /// **'Номера'**
  String get numbersNav;

  /// No description provided for @numbersLocal.
  ///
  /// In ru, this message translates to:
  /// **'Личная база на этом устройстве. Записи и жалобы не отправляются другим пользователям.'**
  String get numbersLocal;

  /// No description provided for @numbersEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Номеров пока нет'**
  String get numbersEmpty;

  /// No description provided for @numbersEmptyBody.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте номер вручную, из результата проверки или импортируйте список CSV.'**
  String get numbersEmptyBody;

  /// No description provided for @numbersNoMatch.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено. Измените поиск или фильтр.'**
  String get numbersNoMatch;

  /// No description provided for @numbersSearch.
  ///
  /// In ru, this message translates to:
  /// **'Номер, название или заметка'**
  String get numbersSearch;

  /// No description provided for @numbersAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get numbersAll;

  /// No description provided for @numberAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить номер'**
  String get numberAdd;

  /// No description provided for @numberEdit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать номер'**
  String get numberEdit;

  /// No description provided for @numberSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get numberSave;

  /// No description provided for @numberSaved.
  ///
  /// In ru, this message translates to:
  /// **'Номер сохранён'**
  String get numberSaved;

  /// No description provided for @numberLabel.
  ///
  /// In ru, this message translates to:
  /// **'Название (необязательно)'**
  String get numberLabel;

  /// No description provided for @numberNote.
  ///
  /// In ru, this message translates to:
  /// **'Личная заметка'**
  String get numberNote;

  /// No description provided for @numberRule.
  ///
  /// In ru, this message translates to:
  /// **'Правило для звонков'**
  String get numberRule;

  /// No description provided for @ruleWatch.
  ///
  /// In ru, this message translates to:
  /// **'Наблюдать'**
  String get ruleWatch;

  /// No description provided for @ruleBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get ruleBlocked;

  /// No description provided for @ruleTrusted.
  ///
  /// In ru, this message translates to:
  /// **'Разрешать'**
  String get ruleTrusted;

  /// No description provided for @ruleWatchBody.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняет номер. Само по себе это правило не блокирует звонки.'**
  String get ruleWatchBody;

  /// No description provided for @ruleBlockedBody.
  ///
  /// In ru, this message translates to:
  /// **'Отклоняет звонки с этого номера, когда StopScam выбран для проверки звонков в Android. Это ваше личное решение, не подтверждение мошенничества.'**
  String get ruleBlockedBody;

  /// No description provided for @ruleTrustedBody.
  ///
  /// In ru, this message translates to:
  /// **'Разрешает звонки с этого номера даже при отметке внешней базы. Личное разрешение не подтверждает безопасность звонящего.'**
  String get ruleTrustedBody;

  /// No description provided for @personalSummary.
  ///
  /// In ru, this message translates to:
  /// **'Номер есть в вашей личной базе. Личная отметка не является подтверждённой репутацией; данных для численной оценки риска недостаточно.'**
  String get personalSummary;

  /// No description provided for @personalRulesNote.
  ///
  /// In ru, this message translates to:
  /// **'Личный чёрный список работает отдельно от автоматической блокировки по репутации. Для обоих нужна системная роль StopScam.'**
  String get personalRulesNote;

  /// No description provided for @personalBlockedCall.
  ///
  /// In ru, this message translates to:
  /// **'Звонок отклонён по вашему личному чёрному списку.'**
  String get personalBlockedCall;

  /// No description provided for @personalAllowedCall.
  ///
  /// In ru, this message translates to:
  /// **'Звонок разрешён по вашему личному правилу.'**
  String get personalAllowedCall;

  /// No description provided for @personalMark.
  ///
  /// In ru, this message translates to:
  /// **'Ваша личная отметка'**
  String get personalMark;

  /// No description provided for @numberDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Этот номер уже есть в базе. Откройте его для редактирования.'**
  String get numberDuplicate;

  /// No description provided for @numberMissing.
  ///
  /// In ru, this message translates to:
  /// **'Запись уже удалена. Обновите список.'**
  String get numberMissing;

  /// No description provided for @numberLimit.
  ///
  /// In ru, this message translates to:
  /// **'В личной базе можно хранить до 5000 номеров.'**
  String get numberLimit;

  /// No description provided for @numberInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте номер и заполненные поля.'**
  String get numberInvalid;

  /// No description provided for @numberStorageError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать или сохранить базу номеров. Данные не сброшены. Повторите попытку.'**
  String get numberStorageError;

  /// No description provided for @numberFileError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обработать файл. Используйте CSV или список номеров в UTF-8, не больше 8 МБ.'**
  String get numberFileError;

  /// No description provided for @numberDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить номер'**
  String get numberDelete;

  /// No description provided for @numberDeleteBody.
  ///
  /// In ru, this message translates to:
  /// **'Номер, его правило и личные жалобы будут удалены. Записи в истории проверок останутся.'**
  String get numberDeleteBody;

  /// No description provided for @numberNotSaved.
  ///
  /// In ru, this message translates to:
  /// **'Номер ещё не сохранён'**
  String get numberNotSaved;

  /// No description provided for @numberUpdated.
  ///
  /// In ru, this message translates to:
  /// **'Обновлено'**
  String get numberUpdated;

  /// No description provided for @numberCreated.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено'**
  String get numberCreated;

  /// No description provided for @numberReport.
  ///
  /// In ru, this message translates to:
  /// **'Добавить жалобу'**
  String get numberReport;

  /// No description provided for @numberReports.
  ///
  /// In ru, this message translates to:
  /// **'Мои жалобы'**
  String get numberReports;

  /// No description provided for @numberReportBody.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба сохраняется на телефоне. Если в настройках включён обмен жалобами, серверу отправляются только номер и категория. Жалоба не подтверждает мошенничество и сама по себе не включает блокировку.'**
  String get numberReportBody;

  /// No description provided for @numberReportSaved.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба сохранена только на этом устройстве'**
  String get numberReportSaved;

  /// No description provided for @numberReportNote.
  ///
  /// In ru, this message translates to:
  /// **'Что произошло? Не указывайте пароли и SMS-коды.'**
  String get numberReportNote;

  /// No description provided for @numberReportsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Жалоб пока нет'**
  String get numberReportsEmpty;

  /// No description provided for @numberReportsRecent.
  ///
  /// In ru, this message translates to:
  /// **'Последние 100 личных записей'**
  String get numberReportsRecent;

  /// No description provided for @numberReportDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить эту жалобу? Правило для номера останется.'**
  String get numberReportDelete;

  /// No description provided for @numberCategory.
  ///
  /// In ru, this message translates to:
  /// **'Причина / категория'**
  String get numberCategory;

  /// No description provided for @categoryUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Не указана'**
  String get categoryUnknown;

  /// No description provided for @categoryAdvertising.
  ///
  /// In ru, this message translates to:
  /// **'Нежелательная реклама'**
  String get categoryAdvertising;

  /// No description provided for @categorySuspectedFraud.
  ///
  /// In ru, this message translates to:
  /// **'Подозрение на мошенничество'**
  String get categorySuspectedFraud;

  /// No description provided for @categoryHarassment.
  ///
  /// In ru, this message translates to:
  /// **'Навязчивые звонки'**
  String get categoryHarassment;

  /// No description provided for @categoryOther.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get categoryOther;

  /// No description provided for @numbersImport.
  ///
  /// In ru, this message translates to:
  /// **'Импорт CSV'**
  String get numbersImport;

  /// No description provided for @numbersExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт CSV'**
  String get numbersExport;

  /// No description provided for @numbersExportDone.
  ///
  /// In ru, this message translates to:
  /// **'Список номеров сохранён в выбранный файл'**
  String get numbersExportDone;

  /// No description provided for @numbersImportTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверить перед импортом'**
  String get numbersImportTitle;

  /// No description provided for @numbersImportBody.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию новые номера получат правило «Наблюдать». Существующие записи не изменятся. CSV переносит номера и заметки; отдельные жалобы в него не входят.'**
  String get numbersImportBody;

  /// No description provided for @numbersImportValid.
  ///
  /// In ru, this message translates to:
  /// **'Корректных номеров'**
  String get numbersImportValid;

  /// No description provided for @numbersImportInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Пропущено некорректных строк'**
  String get numbersImportInvalid;

  /// No description provided for @numbersImportDuplicates.
  ///
  /// In ru, this message translates to:
  /// **'Повторов в файле'**
  String get numbersImportDuplicates;

  /// No description provided for @numbersRestoreRules.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить правила блокировки и разрешения из файла'**
  String get numbersRestoreRules;

  /// No description provided for @numbersRestoreWarning.
  ///
  /// In ru, this message translates to:
  /// **'Включайте только для своего проверенного файла. Правила начнут действовать при выданной роли проверки звонков.'**
  String get numbersRestoreWarning;

  /// No description provided for @numbersImportAdded.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено номеров'**
  String get numbersImportAdded;

  /// No description provided for @numbersImportSkipped.
  ///
  /// In ru, this message translates to:
  /// **'Уже были в базе'**
  String get numbersImportSkipped;

  /// No description provided for @numbersImportEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В файле нет корректных номеров. Допустим также простой список: по одному номеру на строку.'**
  String get numbersImportEmpty;

  /// No description provided for @numbersRoleNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Номер сохранён. Для блокировки выберите StopScam в системных настройках проверки звонков.'**
  String get numbersRoleNeeded;

  /// No description provided for @numbersOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть базу'**
  String get numbersOpen;

  /// No description provided for @numbersManage.
  ///
  /// In ru, this message translates to:
  /// **'Управлять номером'**
  String get numbersManage;

  /// No description provided for @numbersExportNote.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт содержит номера и личные заметки. Храните файл в надёжном месте. Отдельные жалобы не экспортируются.'**
  String get numbersExportNote;

  /// No description provided for @shareNumberReports.
  ///
  /// In ru, this message translates to:
  /// **'Анонимно делиться жалобами на номера'**
  String get shareNumberReports;

  /// No description provided for @shareNumberReportsBody.
  ///
  /// In ru, this message translates to:
  /// **'Выключено по умолчанию. При добавлении новой жалобы отправляем серверу только номер и категорию, без названия и заметки. Сервер связывает жалобу со случайным идентификатором устройства и хранит хэш номера. Старые жалобы не отправляются.'**
  String get shareNumberReportsBody;

  /// No description provided for @numberReportShared.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба сохранена на телефоне и отправлена серверу.'**
  String get numberReportShared;

  /// No description provided for @numberReportShareFailed.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба сохранена на телефоне, но отправить её серверу не удалось.'**
  String get numberReportShareFailed;

  /// No description provided for @callListeningTitle.
  ///
  /// In ru, this message translates to:
  /// **'Помощник при звонке'**
  String get callListeningTitle;

  /// No description provided for @callListeningConsentTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перед включением микрофона'**
  String get callListeningConsentTitle;

  /// No description provided for @callListeningConsentBody.
  ///
  /// In ru, this message translates to:
  /// **'Вы сами включаете громкую связь и запускаете помощника. Речь распознаётся на устройстве через микрофон. Аудио не сохраняется и не отправляется на сервер. Расшифровка по умолчанию остаётся только в памяти и удаляется при остановке. Сохранение последней расшифровки на телефоне можно отдельно включить для сеанса.\n\nПредупредите собеседника об анализе разговора. Требования к согласию зависят от страны; уточните применимые правила до использования.\n\nФункция работает не на всех устройствах: Android может отключать микрофон во время звонка. Требуются Android 12+, доступное локальное распознавание и языковой пакет. При недоступности используйте ручную проверку. Помощник может ошибаться, не подтверждает мошенничество и не завершает звонки.'**
  String get callListeningConsentBody;

  /// No description provided for @callListeningAccept.
  ///
  /// In ru, this message translates to:
  /// **'Понимаю, включить'**
  String get callListeningAccept;

  /// No description provided for @callListeningCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get callListeningCancel;

  /// No description provided for @callListeningBody.
  ///
  /// In ru, this message translates to:
  /// **'Включите громкую связь самостоятельно. Помощник слушает микрофон только после вашего запуска. Работает не на всех устройствах. Совпадения — повод проверить ситуацию, а не доказательство мошенничества.'**
  String get callListeningBody;

  /// No description provided for @callListeningStart.
  ///
  /// In ru, this message translates to:
  /// **'Слушать звонок'**
  String get callListeningStart;

  /// No description provided for @callListeningStop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить микрофон'**
  String get callListeningStop;

  /// No description provided for @callListeningActive.
  ///
  /// In ru, this message translates to:
  /// **'Микрофон включён • распознавание на устройстве'**
  String get callListeningActive;

  /// No description provided for @callListeningStopped.
  ///
  /// In ru, this message translates to:
  /// **'Микрофон выключен'**
  String get callListeningStopped;

  /// No description provided for @callListeningLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык разговора'**
  String get callListeningLanguage;

  /// No description provided for @callListeningNone.
  ///
  /// In ru, this message translates to:
  /// **'Совпадений для предупреждения нет. Это не означает безопасность.'**
  String get callListeningNone;

  /// No description provided for @callListeningCaution.
  ///
  /// In ru, this message translates to:
  /// **'Есть подозрительные фразы. Проверьте, с кем разговариваете.'**
  String get callListeningCaution;

  /// No description provided for @callListeningWarning.
  ///
  /// In ru, this message translates to:
  /// **'Обнаружено опасное сочетание фраз'**
  String get callListeningWarning;

  /// No description provided for @callListeningDanger.
  ///
  /// In ru, this message translates to:
  /// **'Это похоже на мошенничество. Не называйте коды и данные карты. Положите трубку и перезвоните в банк по номеру на карте.'**
  String get callListeningDanger;

  /// No description provided for @callListeningUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Локальное распознавание недоступно. Нужны Android 12+ и поддержка распознавания на устройстве. Используйте ручную проверку ниже.'**
  String get callListeningUnavailable;

  /// No description provided for @callListeningPermission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите микрофон и уведомления для видимого индикатора. Помощник не запущен.'**
  String get callListeningPermission;

  /// No description provided for @callListeningNoAudio.
  ///
  /// In ru, this message translates to:
  /// **'Речь не распознана: система могла отключить микрофон во время звонка. Микрофон остановлен. Опишите разговор вручную ниже.'**
  String get callListeningNoAudio;

  /// No description provided for @callListeningLanguageMissing.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн-пакет выбранного языка недоступен. Установите его в настройках распознавания Android или используйте ручную проверку.'**
  String get callListeningLanguageMissing;

  /// No description provided for @callListeningLimit.
  ///
  /// In ru, this message translates to:
  /// **'Сеанс остановлен после 30 минут. При необходимости запустите новый.'**
  String get callListeningLimit;

  /// No description provided for @callDictionaryVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия словаря'**
  String get callDictionaryVersion;

  /// No description provided for @callDictionaryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Словарь казахских фраз ещё не проверен носителем языка. Предупреждения на казахском пока недоступны; доступна ручная проверка.'**
  String get callDictionaryEmpty;

  /// No description provided for @callDictionaryUpdate.
  ///
  /// In ru, this message translates to:
  /// **'Обновить словарь'**
  String get callDictionaryUpdate;

  /// No description provided for @callDictionaryError.
  ///
  /// In ru, this message translates to:
  /// **'Обновление словаря не принято. Используется предыдущая проверенная версия.'**
  String get callDictionaryError;

  /// No description provided for @callSaveTranscript.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить расшифровку этого сеанса'**
  String get callSaveTranscript;

  /// No description provided for @callSaveTranscriptBody.
  ///
  /// In ru, this message translates to:
  /// **'Выключено по умолчанию. Последняя расшифровка хранится зашифрованной только на телефоне и заменяет предыдущую. Сервер её не получает.'**
  String get callSaveTranscriptBody;

  /// No description provided for @callShowTranscript.
  ///
  /// In ru, this message translates to:
  /// **'Показать сохранённую расшифровку'**
  String get callShowTranscript;

  /// No description provided for @callDeleteTranscript.
  ///
  /// In ru, this message translates to:
  /// **'Удалить расшифровку'**
  String get callDeleteTranscript;

  /// No description provided for @callNoSavedTranscript.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённой расшифровки нет'**
  String get callNoSavedTranscript;

  /// No description provided for @callManualTitle.
  ///
  /// In ru, this message translates to:
  /// **'После звонка: ручная проверка'**
  String get callManualTitle;

  /// No description provided for @callManualBody.
  ///
  /// In ru, this message translates to:
  /// **'Кратко опишите, что просил собеседник. По кнопке отправится только написанное вами описание. Расшифровка и аудио не отправляются. Не вводите секретные коды и реквизиты.'**
  String get callManualBody;

  /// No description provided for @callManualDescription.
  ///
  /// In ru, this message translates to:
  /// **'Ваше краткое описание'**
  String get callManualDescription;

  /// No description provided for @callManualAi.
  ///
  /// In ru, this message translates to:
  /// **'Проверить описание с AI'**
  String get callManualAi;

  /// No description provided for @callListeningBack.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к помощнику'**
  String get callListeningBack;
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
      <String>['kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
