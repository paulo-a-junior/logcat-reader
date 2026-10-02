import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Leitor de Logcat';

  @override
  String get selectDevice => 'Selecione um dispositivo';

  @override
  String get noDevicesFound => 'Nenhum dispositivo encontrado';

  @override
  String get refreshDevices => 'Atualizar dispositivos';

  @override
  String get connectViaIp => 'Ligar por IP (adb connect)';

  @override
  String get startLogcat => 'Iniciar logcat';

  @override
  String get stop => 'Parar';

  @override
  String get openFile => 'Abrir ficheiro';

  @override
  String get clearLogs => 'Limpar registos';

  @override
  String get preferences => 'Preferências';

  @override
  String get fileTypeLogs => 'Ficheiros de registo';

  @override
  String get fileTypeAll => 'Todos os ficheiros';

  @override
  String get connectDialogTitle => 'Ligar por IP';

  @override
  String get address => 'Endereço';

  @override
  String get cancel => 'Cancelar';

  @override
  String get connect => 'Ligar';

  @override
  String get columnLine => 'Linha';

  @override
  String get columnProcess => 'Nome do Processo';

  @override
  String get columnMessage => 'Mensagem';

  @override
  String get tableRaw => 'Completo';

  @override
  String get tableFiltered => 'Filtrado';

  @override
  String lineCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString linhas',
      one: '1 linha',
    );
    return '$_temp0';
  }

  @override
  String get followingNewLines => 'A seguir novas linhas';

  @override
  String get followNewLines => 'Seguir novas linhas';

  @override
  String get filterMessage => 'Mensagem';

  @override
  String get filterMessageHintText => 'Texto';

  @override
  String get filterMessageHintRegex => 'Expressão regular';

  @override
  String get regularExpression => 'Expressão regular';

  @override
  String get caseSensitive => 'Distinguir maiúsculas';

  @override
  String get filterProcess => 'Processo';

  @override
  String get filterProcessHint => 'Nome ou PID';

  @override
  String get filterTag => 'Etiqueta';

  @override
  String get filterMinLevel => 'Nível mín.';

  @override
  String get levelVerbose => 'Detalhado';

  @override
  String get levelDebug => 'Depuração';

  @override
  String get levelInfo => 'Info';

  @override
  String get levelWarn => 'Aviso';

  @override
  String get levelError => 'Erro';

  @override
  String get levelFatal => 'Fatal';

  @override
  String statusStarting(String source) {
    return 'A iniciar logcat em $source…';
  }

  @override
  String statusStreaming(String source) {
    return 'A receber de $source';
  }

  @override
  String statusEnded(String source) {
    return 'O logcat em $source terminou';
  }

  @override
  String statusReconnecting(String source, int attempt) {
    return 'Ligação a $source perdida — a religar (tentativa $attempt)…';
  }

  @override
  String get statusStopped => 'Parado';

  @override
  String statusLoading(String path) {
    return 'A carregar $path…';
  }

  @override
  String statusLoaded(int count, String path) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString linhas carregadas de $path',
      one: '1 linha carregada de $path',
    );
    return '$_temp0';
  }

  @override
  String statusReadFailed(String path, String error) {
    return 'Falha ao ler $path: $error';
  }

  @override
  String adbNotFound(String adb) {
    return 'Não foi possível executar \"$adb\". Confirme que o adb está no PATH ou defina a variável de ambiente ADB.';
  }

  @override
  String notifyConnectionLost(String source) {
    return 'Ligação a $source perdida';
  }

  @override
  String notifyReconnected(String source) {
    return 'Religado a $source';
  }

  @override
  String notifyRebooted(String source) {
    return '$source reiniciou — logcat retomado';
  }

  @override
  String notifyJavaCrash(String process) {
    return 'Falha (FATAL EXCEPTION) em $process';
  }

  @override
  String notifyAnr(String process) {
    return 'ANR em $process';
  }

  @override
  String notifyNativeCrash(String process) {
    return 'Falha nativa em $process';
  }

  @override
  String get show => 'Mostrar';

  @override
  String get sectionDevice => 'Dispositivo';

  @override
  String get autoReconnect => 'Religar automaticamente';

  @override
  String get autoReconnectSubtitle => 'Retomar o logcat quando o dispositivo desliga ou reinicia';

  @override
  String get sectionDisplay => 'Apresentação';

  @override
  String get longLines => 'Linhas longas';

  @override
  String get longLinesEllipsis => 'Reticências';

  @override
  String get longLinesWrap => 'Quebrar';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get fontSize => 'Tamanho da letra';

  @override
  String get sectionNotifications => 'Notificações';

  @override
  String get notifyOnConnectionLost => 'Ligação perdida';

  @override
  String get notifyOnReconnected => 'Religado';

  @override
  String get notifyOnCrash => 'Falhas de aplicações';

  @override
  String get notifyOnCrashSubtitle => 'FATAL EXCEPTION, ANR e falhas nativas nos registos em direto';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predefinição do sistema';

  @override
  String get resetDefaults => 'Repor predefinições';

  @override
  String get close => 'Fechar';

  @override
  String get filters => 'Filtros';

  @override
  String get manageFilters => 'Gerir filtros';

  @override
  String get addFilter => 'Adicionar filtro';

  @override
  String get newFilterName => 'Novo filtro';

  @override
  String get editFilter => 'Editar filtro';

  @override
  String get duplicateFilter => 'Duplicar';

  @override
  String get deleteFilter => 'Eliminar';

  @override
  String get deleteFilterTitle => 'Eliminar filtro?';

  @override
  String deleteFilterConfirm(String name) {
    return 'O filtro \"$name\" será removido.';
  }

  @override
  String filterCopyName(String name) {
    return '$name (cópia)';
  }

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Guardar';

  @override
  String get filterName => 'Nome';

  @override
  String get filterColor => 'Cor';

  @override
  String get filterMode => 'Linhas correspondentes';

  @override
  String get filterModeInclude => 'Mostrar';

  @override
  String get filterModeExclude => 'Ocultar';

  @override
  String get filterCriteria => 'Critérios';

  @override
  String get combineAny => 'Qualquer';

  @override
  String get combineAll => 'Todos';

  @override
  String get combineTooltip => 'Mostrar linhas que correspondem a qualquer um ou a todos os filtros ativos';

  @override
  String get enableAllFilters => 'Ativar todos';

  @override
  String get disableAllFilters => 'Desativar todos';

  @override
  String get noFilterSelected => 'Selecione um filtro para o editar, ou adicione um novo.';

  @override
  String get noFilters => 'Ainda não há filtros';

  @override
  String get noActiveFilters => 'Nenhum filtro ativo — ative um filtro para ver linhas';

  @override
  String get summaryMatchesAll => 'Corresponde a todas as linhas';

  @override
  String summaryLevel(String level) {
    return 'nível ≥ $level';
  }

  @override
  String summaryTag(String tag) {
    return 'etiqueta: $tag';
  }

  @override
  String summaryProcess(String process) {
    return 'processo: $process';
  }

  @override
  String get summaryExclude => 'oculta correspondências';

  @override
  String invalidRegex(String error) {
    return 'Expressão regular inválida: $error';
  }

  @override
  String get filterEnabled => 'Ativo';

  @override
  String get navLogs => 'Registos';

  @override
  String get navApps => 'Apps';

  @override
  String get navFiles => 'Ficheiros';

  @override
  String get navShell => 'Shell';

  @override
  String get navShortcuts => 'Atalhos';

  @override
  String get noDeviceSelected => 'Selecione um dispositivo ligado na barra de ferramentas para usar esta vista.';

  @override
  String get deviceMenu => 'Ações do dispositivo';

  @override
  String get reboot => 'Reiniciar';

  @override
  String get rebootRecovery => 'Reiniciar em recovery';

  @override
  String get rebootBootloader => 'Reiniciar em bootloader';

  @override
  String get rebootConfirmTitle => 'Reiniciar dispositivo?';

  @override
  String rebootConfirm(String device, String mode) {
    return '$device vai reiniciar ($mode).';
  }

  @override
  String rebootSent(String device) {
    return 'Comando de reinício enviado para $device';
  }

  @override
  String get takeScreenshot => 'Capturar ecrã…';

  @override
  String screenshotSaved(String path) {
    return 'Captura guardada em $path';
  }

  @override
  String get installApk => 'Instalar APK…';

  @override
  String installing(String name) {
    return 'A instalar $name…';
  }

  @override
  String installed(String name) {
    return '$name instalado';
  }

  @override
  String get fileTypeApk => 'Pacotes Android';

  @override
  String get fileTypePng => 'Imagens PNG';

  @override
  String get refresh => 'Atualizar';

  @override
  String get searchPackages => 'Pesquisar pacotes';

  @override
  String get showSystemApps => 'Apps de sistema';

  @override
  String get systemBadge => 'sistema';

  @override
  String packageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pacotes',
      one: '1 pacote',
    );
    return '$_temp0';
  }

  @override
  String get launchApp => 'Abrir';

  @override
  String get forceStop => 'Forçar paragem';

  @override
  String get clearData => 'Limpar dados';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get saveApk => 'Guardar APK…';

  @override
  String uninstallTitle(String name) {
    return 'Desinstalar $name?';
  }

  @override
  String clearDataTitle(String name) {
    return 'Limpar dados de $name?';
  }

  @override
  String get cannotUndo => 'Esta ação não pode ser desfeita.';

  @override
  String doneMessage(String action, String name) {
    return '$action: $name';
  }

  @override
  String get goUp => 'Pasta acima';

  @override
  String get path => 'Caminho';

  @override
  String get pushFiles => 'Enviar ficheiros…';

  @override
  String get pull => 'Transferir…';

  @override
  String get newFolder => 'Nova pasta';

  @override
  String get folderName => 'Nome da pasta';

  @override
  String get create => 'Criar';

  @override
  String get delete => 'Eliminar';

  @override
  String deleteFileTitle(String name) {
    return 'Eliminar $name?';
  }

  @override
  String get emptyFolder => 'Esta pasta está vazia';

  @override
  String get columnName => 'Nome';

  @override
  String get columnSize => 'Tamanho';

  @override
  String get columnModified => 'Modificado';

  @override
  String transferring(String name) {
    return 'A transferir $name…';
  }

  @override
  String pushDone(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ficheiros enviados para $path',
      one: '1 ficheiro enviado para $path',
    );
    return '$_temp0';
  }

  @override
  String pullDone(String path) {
    return 'Guardado em $path';
  }

  @override
  String get shellHint => 'Comando a executar no dispositivo (adb shell) — ↑/↓ para histórico';

  @override
  String get run => 'Executar';

  @override
  String get clearConsole => 'Limpar terminados';

  @override
  String exitCode(int code) {
    return 'saída $code';
  }

  @override
  String get stopped => 'parado';

  @override
  String get running => 'a executar…';

  @override
  String get outputTruncated => '(saída truncada)';

  @override
  String get consoleEmpty => 'Execute um comando ou atalho para ver a saída aqui.';

  @override
  String get copyOutput => 'Copiar saída';

  @override
  String get copied => 'Copiado';

  @override
  String get addShortcut => 'Adicionar atalho';

  @override
  String get editShortcut => 'Editar atalho';

  @override
  String get newShortcutName => 'Novo atalho';

  @override
  String get deleteShortcutTitle => 'Eliminar atalho?';

  @override
  String deleteShortcutConfirm(String name) {
    return 'O atalho \"$name\" será removido.';
  }

  @override
  String get manageShortcuts => 'Gerir atalhos…';

  @override
  String get noShortcuts => 'Ainda não há atalhos';

  @override
  String get shortcutName => 'Nome';

  @override
  String get shortcutCommand => 'Comando';

  @override
  String get shortcutKind => 'Executa';

  @override
  String get kindShell => 'adb shell';

  @override
  String get kindAdb => 'adb';

  @override
  String get kindHost => 'Este computador';

  @override
  String get kindShellHint => 'Executado na shell do dispositivo, ex.: input keyevent KEYCODE_HOME';

  @override
  String get kindAdbHint => 'Argumentos do adb para o dispositivo selecionado, ex.: install -r /caminho/app.apk';

  @override
  String get kindHostHint => 'Comando ou script neste computador; ANDROID_SERIAL e ADB são definidos';

  @override
  String get shortcutOutput => 'Ao terminar';

  @override
  String get outputNotify => 'Notificar';

  @override
  String get outputConsole => 'Abrir vista Shell';

  @override
  String get shortcutConfirm => 'Perguntar antes de executar';

  @override
  String get shortcutPinned => 'Mostrar na barra de ferramentas';

  @override
  String get shortcutIcon => 'Ícone';

  @override
  String runShortcutTitle(String name) {
    return 'Executar \"$name\"?';
  }

  @override
  String shortcutDone(String name) {
    return '$name: concluído';
  }

  @override
  String shortcutFailed(String name, int code) {
    return '$name falhou (saída $code)';
  }

  @override
  String shortcutNeedsDevice(String name) {
    return 'Selecione um dispositivo ligado para executar \"$name\"';
  }

  @override
  String get commandRequired => 'Introduza um comando';
}
