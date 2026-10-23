// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'StopScam';

  @override
  String get home => 'Главная';

  @override
  String get scan => 'Проверка';

  @override
  String get history => 'История';

  @override
  String get education => 'Полезное';

  @override
  String get settings => 'Настройки';

  @override
  String get welcome => 'Спокойствие начинается с проверки';

  @override
  String get tagline => 'Ваш помощник в цифровой безопасности';

  @override
  String get heroTitle => 'Сначала проверьте.\nПотом доверяйте.';

  @override
  String get heroBody =>
      'Проверьте подозрительное сообщение или ссылку с помощью AI.';

  @override
  String get ready => 'Проверка по запросу';

  @override
  String get checkMessage => 'Проверить сообщение';

  @override
  String get checkLink => 'Проверить ссылку';

  @override
  String get totalScans => 'Всего проверок';

  @override
  String get highRisks => 'Высокий риск';

  @override
  String get recent => 'Последние проверки';

  @override
  String get seeAll => 'Все';

  @override
  String get dailyTip => 'Совет по безопасности';

  @override
  String get tipBody =>
      'Никому не сообщайте SMS-коды — даже если собеседник представляется сотрудником банка.';

  @override
  String get scannerTitle => 'Проверим вместе';

  @override
  String get scannerSubtitle => 'Вставьте текст. Мы объясним признаки риска.';

  @override
  String get textMode => 'Текст';

  @override
  String get linkMode => 'Ссылка';

  @override
  String get textHint => 'Вставьте подозрительное сообщение…';

  @override
  String get urlHint => 'example.com или https://…';

  @override
  String get paste => 'Вставить';

  @override
  String get clear => 'Очистить';

  @override
  String get startScan => 'Начать проверку';

  @override
  String get analyzing => 'Анализируем…';

  @override
  String get analyzingBody =>
      'Изучаем контекст, признаки давления и подозрительные ссылки.';

  @override
  String get emptyInput => 'Введите сообщение или ссылку.';

  @override
  String get invalidUrl =>
      'Введите корректный адрес сайта с http:// или https://.';

  @override
  String get tooLong => 'Текст слишком длинный. Максимум 12 000 символов.';

  @override
  String get disclaimer =>
      'AI может ошибаться. Не передавайте пароли, SMS-коды, данные банковских карт и другую конфиденциальную информацию.';

  @override
  String get privacyNotice =>
      'Для анализа содержимое отправляется вашему серверу и AI-провайдеру. Удалите личные данные перед отправкой.';

  @override
  String get mockBanner => 'Тестовый режим · результат — пример';

  @override
  String get result => 'Результат проверки';

  @override
  String get riskScore => 'Оценка риска';

  @override
  String get safe => 'Явных признаков мало';

  @override
  String get low => 'Низкий риск';

  @override
  String get medium => 'Средний риск';

  @override
  String get high => 'Высокий риск';

  @override
  String get critical => 'Критический риск';

  @override
  String get reasons => 'На что обратить внимание';

  @override
  String get recommendations => 'Что делать дальше';

  @override
  String get sourceText => 'Исходный текст';

  @override
  String get scanAgain => 'Проверить ещё';

  @override
  String get goHome => 'На главную';

  @override
  String get copyResult => 'Скопировать результат';

  @override
  String get copied => 'Скопировано';

  @override
  String get historyTitle => 'История проверок';

  @override
  String get emptyHistory => 'Здесь пока нет проверок.';

  @override
  String get emptyHistoryBody =>
      'Проверьте первое сообщение — результат сохранится здесь.';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get delete => 'Удалить';

  @override
  String get confirmClear =>
      'Удалить все проверки с этого устройства? Отменить это действие нельзя.';

  @override
  String get cancel => 'Отмена';

  @override
  String get language => 'Язык';

  @override
  String get russian => 'Русский';

  @override
  String get kazakh => 'Қазақша';

  @override
  String get theme => 'Оформление';

  @override
  String get systemTheme => 'Системная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get about => 'О приложении';

  @override
  String get version => '2.3.0';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get aboutBody =>
      'StopScam помогает замечать признаки мошенничества и принимать взвешенные решения. Оценка основана на предоставленном тексте, а не на проверке личности отправителя.';

  @override
  String get next => 'Далее';

  @override
  String get skip => 'Пропустить';

  @override
  String get begin => 'Начать';

  @override
  String get onboard1 => 'Защита от мошенников';

  @override
  String get onboardBody1 =>
      'StopScam помогает распознавать подозрительные сообщения и ссылки.';

  @override
  String get onboard2 => 'Понятный AI-анализ';

  @override
  String get onboardBody2 =>
      'Искусственный интеллект ищет признаки фишинга, давления и обмана.';

  @override
  String get onboard3 => 'Будьте на шаг впереди';

  @override
  String get onboardBody3 =>
      'Получайте объяснение риска и рекомендации. Решение всегда остаётся за вами.';

  @override
  String get retry => 'Попробовать снова';

  @override
  String get errorNetwork =>
      'Нет подключения к интернету. Проверьте соединение и попробуйте снова.';

  @override
  String get errorTimeout => 'Сервис не ответил вовремя. Попробуйте ещё раз.';

  @override
  String get errorAuth => 'Не удалось подтвердить доступ устройства к серверу.';

  @override
  String get errorRate => 'Лимит запросов исчерпан. Повторите позже.';

  @override
  String get errorServer => 'Сервис временно недоступен. Попробуйте позже.';

  @override
  String get errorJson =>
      'Получен неполный ответ. Попробуйте выполнить проверку ещё раз.';

  @override
  String get errorConfig =>
      'Сервис анализа ещё не настроен. Проверьте адрес сервера и его настройки AI.';

  @override
  String get errorUnknown => 'Не удалось выполнить анализ. Попробуйте снова.';

  @override
  String get errorStorage =>
      'Не удалось сохранить данные на устройстве. Освободите место и повторите.';

  @override
  String get saveFailed => 'Результат получен, но не сохранён в историю.';

  @override
  String get phishing => 'Фишинг';

  @override
  String get fakeBank => 'Поддельное обращение банка';

  @override
  String get socialEngineering => 'Социальная инженерия';

  @override
  String get investmentScam => 'Инвестиционная схема';

  @override
  String get fakeDelivery => 'Поддельная доставка';

  @override
  String get accountTheft => 'Кража аккаунта';

  @override
  String get maliciousLink => 'Подозрительная ссылка';

  @override
  String get suspiciousMessage => 'Подозрительное сообщение';

  @override
  String get unknown => 'Не определено';

  @override
  String get educationTitle => 'Знания — ваша защита';

  @override
  String get educationSubtitle =>
      'Короткие советы для безопасной цифровой жизни.';

  @override
  String get article1 => 'Как распознать фишинг';

  @override
  String get body1 =>
      'Фишинг — попытка выманить пароль, код или деньги, выдавая себя за знакомый сервис.\n\nОбратите внимание на срочность, угрозы блокировки и просьбы раскрыть секреты. Имя отправителя можно подделать.\n\nОткройте нужное приложение самостоятельно или наберите известный адрес сайта. Проверьте запрос через официальный канал, который вы нашли независимо от сообщения.';

  @override
  String get article2 => 'Если вы сообщили SMS-код';

  @override
  String get body2 =>
      'Прекратите разговор и не сообщайте новые коды.\n\nОткройте официальный сервис, для которого был код. Смените пароль, завершите чужие сеансы и включите двухфакторную защиту.\n\nЕсли код связан с банком, срочно свяжитесь с банком через его приложение или номер на карте. Сообщите о возможном захвате аккаунта и попросите проверить операции. Сохраните переписку.';

  @override
  String get article3 => 'Как проверить ссылку';

  @override
  String get body3 =>
      'Не открывайте ссылку, чтобы просто проверить её.\n\nСравните домен с известным официальным адресом. Лишние буквы, подмена символов и длинные цепочки поддоменов требуют внимания. HTTPS шифрует соединение, но не доказывает честность сайта.\n\nСокращённая ссылка скрывает конечный адрес. Найдите нужную страницу самостоятельно через официальное приложение.';

  @override
  String get article4 => 'Мошенники от имени банка';

  @override
  String get body4 =>
      'Просьба перевести деньги на «безопасный счёт», назвать код или установить программу удалённого доступа — серьёзный тревожный сигнал.\n\nПрервите разговор. Свяжитесь с банком через официальное приложение или номер на карте. Не перезванивайте по номеру из подозрительного сообщения.\n\nЕсли вы уже передали данные карты, попросите банк заблокировать её и проверить операции.';

  @override
  String get article5 => 'Обман в WhatsApp и Telegram';

  @override
  String get body5 =>
      'Знакомый внезапно просит денег? Его аккаунт могли взломать. Свяжитесь с ним другим способом.\n\nНе сообщайте коды входа и не сканируйте QR-коды для чужой «проверки». Проверяйте список подключённых устройств.\n\nВключите двухэтапную проверку и ограничьте видимость личной информации. Подозрительные сообщения можно пожаловаться и заблокировать средствами мессенджера.';

  @override
  String get article6 => 'Фальшивые инвестиции';

  @override
  String get body6 =>
      'Гарантированная высокая доходность, давление «только сегодня» и просьба внести дополнительный платёж для вывода денег — тревожные признаки.\n\nПроверяйте компанию и её разрешения через официальный реестр соответствующего регулятора. Отзывы и красивые графики легко подделать.\n\nНе отправляйте новые деньги ради возврата уже потерянных. Сохраните доказательства и обратитесь в банк и правоохранительные органы.';

  @override
  String get article7 => 'Правила цифровой безопасности';

  @override
  String get body7 =>
      'Используйте уникальные пароли и менеджер паролей. Включайте двухфакторную аутентификацию, где она доступна.\n\nОбновляйте систему и приложения. Устанавливайте приложения из официальных источников и проверяйте разрешения.\n\nНе торопитесь отвечать на неожиданные запросы. Проверяйте личность собеседника через независимый канал. Делитесь этими правилами с близкими.';

  @override
  String get savedLanguage =>
      'AI-объяснение сохранено на языке исходной проверки.';

  @override
  String get insufficientData => 'Недостаточно данных';

  @override
  String get checkPhone => 'Проверить номер';

  @override
  String get checkQr => 'Сканировать QR';

  @override
  String get incomingCall => 'Входящий звонок';

  @override
  String get phoneHint => 'Например, +7 700 123 45 67';

  @override
  String get invalidPhone => 'Введите действительный номер с кодом страны';

  @override
  String get phoneContext => 'Что сказал собеседник? (необязательно)';

  @override
  String get phoneDescription =>
      'Проверка репутации номера и содержания разговора. Цифры номера сами по себе не доказывают мошенничество.';

  @override
  String get noReputation =>
      'Для этого номера нет доступных данных репутации. Определить риск по одному номеру нельзя.';

  @override
  String get reputationOnly =>
      'Показаны данные службы репутации. Они не подтверждают личность звонящего и не являются численной оценкой риска.';

  @override
  String get repUnknown => 'Репутация неизвестна';

  @override
  String get repClear => 'Служба не отметила угрозу';

  @override
  String get repFlagged => 'Служба отметила угрозу';

  @override
  String get repUnavailable => 'Служба репутации недоступна';

  @override
  String get repNotConfigured => 'Служба репутации не подключена';

  @override
  String get countryCode => 'Код страны';

  @override
  String get confidence => 'Уверенность анализа';

  @override
  String get confidenceNote =>
      'Это уверенность модели в выводе, а не вероятность мошенничества.';

  @override
  String get lowConfidence =>
      'Низкая уверенность: данных для надёжного вывода недостаточно.';

  @override
  String get localAssessment => 'Локальные данные; AI не использовался';

  @override
  String get aiAssessment => 'AI-анализ';

  @override
  String get legacyAssessment => 'Сохранённый результат предыдущей версии';

  @override
  String get qrSubtitle =>
      'Наведите камеру на QR-код. Ссылки и платежи не открываются автоматически.';

  @override
  String get qrDecoded => 'QR-код распознан';

  @override
  String get qrInvalid => 'Не удалось распознать содержимое QR-кода';

  @override
  String get qrPermission =>
      'Для сканирования нужен доступ к камере. Разрешите его в настройках приложения.';

  @override
  String get qrCameraError =>
      'Камера недоступна. Закройте другие приложения с камерой и повторите.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get flash => 'Фонарик';

  @override
  String get qrWifi => 'Wi-Fi: пароль и имя сети скрыты';

  @override
  String get qrContact => 'Контакт: личные данные скрыты';

  @override
  String get qrPayment => 'Платёж';

  @override
  String get qrEmail => 'Электронное письмо';

  @override
  String get qrSms => 'SMS';

  @override
  String get qrUnknown => 'Неизвестный формат';

  @override
  String get qrInsufficient =>
      'QR-код декодирован локально. Его безопасность не подтверждена. Конфиденциальные данные Wi-Fi и контактов не отправляются в AI.';

  @override
  String get recipient => 'Получатель';

  @override
  String get amount => 'Сумма';

  @override
  String get callsTitle => 'Защита от звонков';

  @override
  String get callsBody =>
      'Android передаёт приложению отдельные входящие звонки после вашего согласия. Решение принимается по локальному кэшу, без AI и сети. Неизвестные номера пропускаются. Контакты и полный журнал звонков не читаются.';

  @override
  String get callsEnable => 'Выбрать StopScam для проверки звонков';

  @override
  String get callsEnabled => 'Проверка звонков включена';

  @override
  String get callsDisabled => 'Проверка звонков выключена';

  @override
  String get callsUnsupported =>
      'Системная роль недоступна. Нужен Android 10 или новее с поддержкой проверки звонков.';

  @override
  String get autoBlock => 'Блокировать подтверждённые угрозы';

  @override
  String get autoBlockBody =>
      'Только подтверждённая отметка службы репутации, уверенность ≥95% и свежий кэш. По умолчанию выключено.';

  @override
  String get notificationsEnable => 'Разрешить уведомления о звонках';

  @override
  String get notificationsEnabled => 'Уведомления разрешены';

  @override
  String get blockedCall => 'Звонок заблокирован по подтверждённой репутации';

  @override
  String get allowedCall => 'Звонок пропущен';

  @override
  String get fixtureOtp => 'Тест: запрос кода подтверждения';

  @override
  String get fixtureMoney => 'Тест: финансовый предлог';

  @override
  String get fixtureUrgency => 'Тест: давление срочностью';

  @override
  String get fixtureUrl => 'Тест: признак подозрительной ссылки';

  @override
  String get fixtureSummary =>
      'Отладочный пример по признакам ввода. Это не реальный AI-анализ.';

  @override
  String get mockDetail =>
      'Включён режим разработки: оценка выбирается из тестовых сценариев. Отключите USE_MOCK_AI для реальных запросов.';

  @override
  String get privacyBody =>
      'История последних 200 проверок хранится локально. При ручном анализе введённый текст, ссылка, описание разговора или содержимое QR отправляется вашему backend, который обращается к AI-провайдеру. Пароли Wi-Fi и данные контактных QR не отправляются. Номер передаётся службе репутации только при ручной проверке и наличии настроенного backend. Репутация кэшируется до 24 часов. Проверка входящих звонков использует только локальный кэш, не ждёт сети и включается через системное согласие. Приложение не читает контакты, SMS или полный журнал звонков. Не вводите пароли, коды подтверждения и реквизиты карт. Историю можно удалить в настройках. Системное резервное копирование отключено.\n\nЛичная база номеров и жалобы хранятся отдельно от истории, в SQLite на устройстве. Личная база не синхронизируется. Если вы включили обмен жалобами, новые жалобы передают серверу номер и категорию без названия и заметки. Сервер хранит хэш номера и связывает жалобу со случайным идентификатором устройства; сервер также получает IP-адрес при соединении. Выключение обмена прекращает будущую отправку, но не удаляет уже отправленные жалобы. Названия и заметки из личной базы не передаются AI. Экспорт CSV сохраняет номера и заметки в выбранный вами файл. При удалении приложения или его данных локальная база также удаляется.\n\nПомощник при звонке включается вручную после согласия. Аудио не сохраняется и не передаётся. Распознавание и поиск фраз выполняются на устройстве. Расшифровка стирается при остановке, если вы отдельно не включили её локальное зашифрованное сохранение. Сервер получает только запросы обновления словаря. Кнопка проверки с AI отправляет только краткое описание, написанное вами.';

  @override
  String get openLink => 'Открыть ссылку';

  @override
  String get openLinkWarning =>
      'У этой ссылки высокий риск или недостаточно данных. Переход может быть опасен. Открыть всё равно?';

  @override
  String get localSignals =>
      'Локальные признаки URL (не доказательство мошенничества)';

  @override
  String get knownSignals => 'Известных сигналов';

  @override
  String get numbersTitle => 'Моя база номеров';

  @override
  String get numbersNav => 'Номера';

  @override
  String get numbersLocal =>
      'Личная база на этом устройстве. Записи и жалобы не отправляются другим пользователям.';

  @override
  String get numbersEmpty => 'Номеров пока нет';

  @override
  String get numbersEmptyBody =>
      'Добавьте номер вручную, из результата проверки или импортируйте список CSV.';

  @override
  String get numbersNoMatch => 'Ничего не найдено. Измените поиск или фильтр.';

  @override
  String get numbersSearch => 'Номер, название или заметка';

  @override
  String get numbersAll => 'Все';

  @override
  String get numberAdd => 'Добавить номер';

  @override
  String get numberEdit => 'Редактировать номер';

  @override
  String get numberSave => 'Сохранить';

  @override
  String get numberSaved => 'Номер сохранён';

  @override
  String get numberLabel => 'Название (необязательно)';

  @override
  String get numberNote => 'Личная заметка';

  @override
  String get numberRule => 'Правило для звонков';

  @override
  String get ruleWatch => 'Наблюдать';

  @override
  String get ruleBlocked => 'Блокировать';

  @override
  String get ruleTrusted => 'Разрешать';

  @override
  String get ruleWatchBody =>
      'Сохраняет номер. Само по себе это правило не блокирует звонки.';

  @override
  String get ruleBlockedBody =>
      'Отклоняет звонки с этого номера, когда StopScam выбран для проверки звонков в Android. Это ваше личное решение, не подтверждение мошенничества.';

  @override
  String get ruleTrustedBody =>
      'Разрешает звонки с этого номера даже при отметке внешней базы. Личное разрешение не подтверждает безопасность звонящего.';

  @override
  String get personalSummary =>
      'Номер есть в вашей личной базе. Личная отметка не является подтверждённой репутацией; данных для численной оценки риска недостаточно.';

  @override
  String get personalRulesNote =>
      'Личный чёрный список работает отдельно от автоматической блокировки по репутации. Для обоих нужна системная роль StopScam.';

  @override
  String get personalBlockedCall =>
      'Звонок отклонён по вашему личному чёрному списку.';

  @override
  String get personalAllowedCall =>
      'Звонок разрешён по вашему личному правилу.';

  @override
  String get personalMark => 'Ваша личная отметка';

  @override
  String get numberDuplicate =>
      'Этот номер уже есть в базе. Откройте его для редактирования.';

  @override
  String get numberMissing => 'Запись уже удалена. Обновите список.';

  @override
  String get numberLimit => 'В личной базе можно хранить до 5000 номеров.';

  @override
  String get numberInvalid => 'Проверьте номер и заполненные поля.';

  @override
  String get numberStorageError =>
      'Не удалось прочитать или сохранить базу номеров. Данные не сброшены. Повторите попытку.';

  @override
  String get numberFileError =>
      'Не удалось обработать файл. Используйте CSV или список номеров в UTF-8, не больше 8 МБ.';

  @override
  String get numberDelete => 'Удалить номер';

  @override
  String get numberDeleteBody =>
      'Номер, его правило и личные жалобы будут удалены. Записи в истории проверок останутся.';

  @override
  String get numberNotSaved => 'Номер ещё не сохранён';

  @override
  String get numberUpdated => 'Обновлено';

  @override
  String get numberCreated => 'Добавлено';

  @override
  String get numberReport => 'Добавить жалобу';

  @override
  String get numberReports => 'Мои жалобы';

  @override
  String get numberReportBody =>
      'Жалоба сохраняется на телефоне. Если в настройках включён обмен жалобами, серверу отправляются только номер и категория. Жалоба не подтверждает мошенничество и сама по себе не включает блокировку.';

  @override
  String get numberReportSaved => 'Жалоба сохранена только на этом устройстве';

  @override
  String get numberReportNote =>
      'Что произошло? Не указывайте пароли и SMS-коды.';

  @override
  String get numberReportsEmpty => 'Жалоб пока нет';

  @override
  String get numberReportsRecent => 'Последние 100 личных записей';

  @override
  String get numberReportDelete =>
      'Удалить эту жалобу? Правило для номера останется.';

  @override
  String get numberCategory => 'Причина / категория';

  @override
  String get categoryUnknown => 'Не указана';

  @override
  String get categoryAdvertising => 'Нежелательная реклама';

  @override
  String get categorySuspectedFraud => 'Подозрение на мошенничество';

  @override
  String get categoryHarassment => 'Навязчивые звонки';

  @override
  String get categoryOther => 'Другое';

  @override
  String get numbersImport => 'Импорт CSV';

  @override
  String get numbersExport => 'Экспорт CSV';

  @override
  String get numbersExportDone => 'Список номеров сохранён в выбранный файл';

  @override
  String get numbersImportTitle => 'Проверить перед импортом';

  @override
  String get numbersImportBody =>
      'По умолчанию новые номера получат правило «Наблюдать». Существующие записи не изменятся. CSV переносит номера и заметки; отдельные жалобы в него не входят.';

  @override
  String get numbersImportValid => 'Корректных номеров';

  @override
  String get numbersImportInvalid => 'Пропущено некорректных строк';

  @override
  String get numbersImportDuplicates => 'Повторов в файле';

  @override
  String get numbersRestoreRules =>
      'Восстановить правила блокировки и разрешения из файла';

  @override
  String get numbersRestoreWarning =>
      'Включайте только для своего проверенного файла. Правила начнут действовать при выданной роли проверки звонков.';

  @override
  String get numbersImportAdded => 'Добавлено номеров';

  @override
  String get numbersImportSkipped => 'Уже были в базе';

  @override
  String get numbersImportEmpty =>
      'В файле нет корректных номеров. Допустим также простой список: по одному номеру на строку.';

  @override
  String get numbersRoleNeeded =>
      'Номер сохранён. Для блокировки выберите StopScam в системных настройках проверки звонков.';

  @override
  String get numbersOpen => 'Открыть базу';

  @override
  String get numbersManage => 'Управлять номером';

  @override
  String get numbersExportNote =>
      'Экспорт содержит номера и личные заметки. Храните файл в надёжном месте. Отдельные жалобы не экспортируются.';

  @override
  String get shareNumberReports => 'Анонимно делиться жалобами на номера';

  @override
  String get shareNumberReportsBody =>
      'Выключено по умолчанию. При добавлении новой жалобы отправляем серверу только номер и категорию, без названия и заметки. Сервер связывает жалобу со случайным идентификатором устройства и хранит хэш номера. Старые жалобы не отправляются.';

  @override
  String get numberReportShared =>
      'Жалоба сохранена на телефоне и отправлена серверу.';

  @override
  String get numberReportShareFailed =>
      'Жалоба сохранена на телефоне, но отправить её серверу не удалось.';

  @override
  String get callListeningTitle => 'Помощник при звонке';

  @override
  String get callListeningConsentTitle => 'Перед включением микрофона';

  @override
  String get callListeningConsentBody =>
      'Вы сами включаете громкую связь и запускаете помощника. Речь распознаётся на устройстве через микрофон. Аудио не сохраняется и не отправляется на сервер. Расшифровка по умолчанию остаётся только в памяти и удаляется при остановке. Сохранение последней расшифровки на телефоне можно отдельно включить для сеанса.\n\nПредупредите собеседника об анализе разговора. Требования к согласию зависят от страны; уточните применимые правила до использования.\n\nФункция работает не на всех устройствах: Android может отключать микрофон во время звонка. Требуются Android 12+, доступное локальное распознавание и языковой пакет. При недоступности используйте ручную проверку. Помощник может ошибаться, не подтверждает мошенничество и не завершает звонки.';

  @override
  String get callListeningAccept => 'Понимаю, включить';

  @override
  String get callListeningCancel => 'Отмена';

  @override
  String get callListeningBody =>
      'Включите громкую связь самостоятельно. Помощник слушает микрофон только после вашего запуска. Работает не на всех устройствах. Совпадения — повод проверить ситуацию, а не доказательство мошенничества.';

  @override
  String get callListeningStart => 'Слушать звонок';

  @override
  String get callListeningStop => 'Остановить микрофон';

  @override
  String get callListeningActive =>
      'Микрофон включён • распознавание на устройстве';

  @override
  String get callListeningStopped => 'Микрофон выключен';

  @override
  String get callListeningLanguage => 'Язык разговора';

  @override
  String get callListeningNone =>
      'Совпадений для предупреждения нет. Это не означает безопасность.';

  @override
  String get callListeningCaution =>
      'Есть подозрительные фразы. Проверьте, с кем разговариваете.';

  @override
  String get callListeningWarning => 'Обнаружено опасное сочетание фраз';

  @override
  String get callListeningDanger =>
      'Это похоже на мошенничество. Не называйте коды и данные карты. Положите трубку и перезвоните в банк по номеру на карте.';

  @override
  String get callListeningUnavailable =>
      'Локальное распознавание недоступно. Нужны Android 12+ и поддержка распознавания на устройстве. Используйте ручную проверку ниже.';

  @override
  String get callListeningPermission =>
      'Разрешите микрофон и уведомления для видимого индикатора. Помощник не запущен.';

  @override
  String get callListeningNoAudio =>
      'Речь не распознана: система могла отключить микрофон во время звонка. Микрофон остановлен. Опишите разговор вручную ниже.';

  @override
  String get callListeningLanguageMissing =>
      'Офлайн-пакет выбранного языка недоступен. Установите его в настройках распознавания Android или используйте ручную проверку.';

  @override
  String get callListeningLimit =>
      'Сеанс остановлен после 30 минут. При необходимости запустите новый.';

  @override
  String get callDictionaryVersion => 'Версия словаря';

  @override
  String get callDictionaryEmpty =>
      'Словарь казахских фраз ещё не проверен носителем языка. Предупреждения на казахском пока недоступны; доступна ручная проверка.';

  @override
  String get callDictionaryUpdate => 'Обновить словарь';

  @override
  String get callDictionaryError =>
      'Обновление словаря не принято. Используется предыдущая проверенная версия.';

  @override
  String get callSaveTranscript => 'Сохранить расшифровку этого сеанса';

  @override
  String get callSaveTranscriptBody =>
      'Выключено по умолчанию. Последняя расшифровка хранится зашифрованной только на телефоне и заменяет предыдущую. Сервер её не получает.';

  @override
  String get callShowTranscript => 'Показать сохранённую расшифровку';

  @override
  String get callDeleteTranscript => 'Удалить расшифровку';

  @override
  String get callNoSavedTranscript => 'Сохранённой расшифровки нет';

  @override
  String get callManualTitle => 'После звонка: ручная проверка';

  @override
  String get callManualBody =>
      'Кратко опишите, что просил собеседник. По кнопке отправится только написанное вами описание. Расшифровка и аудио не отправляются. Не вводите секретные коды и реквизиты.';

  @override
  String get callManualDescription => 'Ваше краткое описание';

  @override
  String get callManualAi => 'Проверить описание с AI';

  @override
  String get callListeningBack => 'Вернуться к помощнику';

  @override
  String get designQuickChecks => 'Что проверим?';

  @override
  String get designMessage => 'Сообщение';

  @override
  String get designMessageHint => 'SMS и мессенджеры';

  @override
  String get designLinkHint => 'Сайты и адреса';

  @override
  String get designPhone => 'Номер телефона';

  @override
  String get designPhoneHint => 'Репутация номера';

  @override
  String get designQr => 'QR-код';

  @override
  String get designQrHint => 'Проверка содержимого';

  @override
  String get designCallHint =>
      'Подсказки во время разговора. Запускается вами.';

  @override
  String get designNumbersHint => 'Ваши номера и правила блокировки';
}
