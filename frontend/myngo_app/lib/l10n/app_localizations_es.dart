// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MYNGO';

  @override
  String get authLoginButton => 'INICIAR SESIÓN 🐾';

  @override
  String get authRegisterButton => 'REGISTRARME 🐾';

  @override
  String get authRegisterLink => '¿Aún no tienes cuenta?';

  @override
  String get authLoginLink => '¿Ya eres parte?';

  @override
  String get authLoginLinkAction => 'Inicia sesión';

  @override
  String get authForgotPassword => '¿Perdiste tu clave?';

  @override
  String get authConnectionError => 'Error de conexión. Inténtalo de nuevo.';

  @override
  String get formEmailLabel => 'Email';

  @override
  String get formEmailHint => 'tu@email.com';

  @override
  String get formPasswordLabel => 'Contraseña';

  @override
  String get formUsernameLabel => 'Nombre de usuario';

  @override
  String get formUsernameHint => '¿Tu nombre? 🐾';

  @override
  String get formUsernameMinLength => 'Mínimo 3 letras';

  @override
  String get formBioHint => 'Cuéntanos algo sobre ti...';

  @override
  String get formChatNameLabel => 'Nombre del Chat';

  @override
  String get formChatNameHint => 'Ej: Grupo de estudio, Plan finde...';

  @override
  String get profileLoadingTitle => 'Cargando perfil...';

  @override
  String get profileLoadingSubtitle => 'Espere un momento...';

  @override
  String get profileNotFoundTitle => 'Usuario no encontrado';

  @override
  String get profileNotFoundEmoji => '😿';

  @override
  String get profileTabsPosts => 'Posts';

  @override
  String get profileTabsFavorites => 'Favoritos';

  @override
  String get profileTabsCollections => 'Colecciones';

  @override
  String get profileVoteTitleChange => '¿Qué quieres hacer con tu voto?';

  @override
  String get profileVoteTitleNew => '¡Vota a este Michi!';

  @override
  String get profileVoteDescChange =>
      'Puedes cambiar tu puntuación o eliminar el voto.';

  @override
  String get profileVoteDescNew => 'Dalle amor con tus estrellas 🐾';

  @override
  String get profileVoteRemoveLabel => 'Eliminar mi voto';

  @override
  String get profileEditBioTitle => 'Editar Biografía';

  @override
  String get profileBioHint => 'Cuéntanos algo sobre ti...';

  @override
  String get profileCreatePostLabel => 'Subir Post';

  @override
  String get profileVoteRemoveTooltip => 'Eliminar mi voto';

  @override
  String get profileNotFound => 'Usuario no encontrado 😿';

  @override
  String get profileEditBio => 'Editar Biografía';

  @override
  String get profileSaveBio => 'Guardar';

  @override
  String get profileCancelBio => 'Cancelar';

  @override
  String get profileVoteRemove => 'Eliminar mi voto';

  @override
  String profileJoined(String date) {
    return 'Se unió en $date';
  }

  @override
  String get profileFollowersCount => 'Seguidores';

  @override
  String get profileFollowingCount => 'Seguidos';

  @override
  String get chatPersonalization => 'Personalizar Chat';

  @override
  String get chatSaveSettings => 'GUARDAR';

  @override
  String get chatConfigSaved => 'Configuración guardada correctamente';

  @override
  String get chatConfigError => 'Error al guardar la configuración';

  @override
  String get chatImageUploadError => 'Error al subir la imagen';

  @override
  String get chatPreviewLive => 'VISTA PREVIA EN TIEMPO REAL';

  @override
  String get chatResetDesign => 'Restablecer diseño por defecto';

  @override
  String get chatIdentitySection => 'Identidad del Chat';

  @override
  String get chatColorsSection => 'Colores de Burbujas';

  @override
  String get chatBackgroundSection => 'Patrón y Estilo de Fondo';

  @override
  String get chatBubbleSection => 'Estilo de Burbujas';

  @override
  String get chatBackgroundGradient => 'Gradiente de fondo';

  @override
  String get chatBackgroundPattern => 'Patrón geométrico';

  @override
  String get chatBubbleStyle => 'Estilo visual de burbuja';

  @override
  String get chatBubbleShape => 'Forma de las burbujas';

  @override
  String get chatFontSize => 'Tamaño de fuente';

  @override
  String get chatGradientSunset => 'Atardecer';

  @override
  String get chatGradientOcean => 'Océano';

  @override
  String get chatGradientForest => 'Bosque';

  @override
  String get chatGradientGalaxy => 'Galaxia';

  @override
  String get chatGradientNight => 'Noche';

  @override
  String get chatGradientPeach => 'Melocotón';

  @override
  String get chatGradientLavender => 'Lavanda';

  @override
  String get chatPatternDots => 'Puntos';

  @override
  String get chatPatternStars => 'Estrellas';

  @override
  String get chatPatternTriangles => 'Geométrico';

  @override
  String get chatPatternWaves => 'Ondas';

  @override
  String get chatPatternLines => 'Líneas';

  @override
  String get chatStyleSolid => 'Sólido';

  @override
  String get chatStyleCrystal => 'Cristal';

  @override
  String get chatStyleNeon => 'Neón';

  @override
  String get chatStyleLove => 'Amor';

  @override
  String get chatStyleCowboy => 'Vaquero';

  @override
  String get chatStyleForest => 'Bosque';

  @override
  String get chatStyleCyber => 'Cyber';

  @override
  String get chatStyleKawaii => 'Kawaii';

  @override
  String get chatStyleAdventure => 'Aventura';

  @override
  String get navigationHome => 'Inicio';

  @override
  String get navigationExplore => 'Explorar';

  @override
  String get navigationShop => 'Tienda';

  @override
  String get navigationChats => 'Chats';

  @override
  String get navigationNotifications => 'Notificaciones';

  @override
  String get navigationProfile => 'Mi Perfil';

  @override
  String get navigationSettings => 'Configuración';

  @override
  String get navigationLogout => 'Cerrar Miau-Sesión';

  @override
  String get navigationError => 'Error de Navegación 🐾';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRetry => 'REINTENTAR';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get communityCreateBtn => 'EMPEZAR YA';

  @override
  String get communityHaveAPet => '¿TIENES UN MICHI?';

  @override
  String get communityHavePetDesc =>
      '¡Crea tu propia comunidad y presume de mascota!';

  @override
  String get communitySuggestions => 'MIAU-SUGERENCIAS';

  @override
  String get communityExploreMore => 'Explora para ver más 🐾';

  @override
  String get communityNoJoined => 'Únete a una comunidad 🐾';

  @override
  String communityMembers(String count) {
    return '$count Miembros';
  }

  @override
  String get communityRanking => 'Aún no hay ranking 🐾';

  @override
  String get communityJoinedMsg => '¡Miau-unido con éxito! 🐾';

  @override
  String get communityJoinNeedLogin =>
      '¡Vaya! Debes iniciar miau-sesión para unirte 🐾';

  @override
  String get postUploadLabel => 'Subir Post';

  @override
  String get postCreateHint => '¿Qué estás pensando, miau?';

  @override
  String get postTagsHint => 'Etiquetas (ej. arte, animales, juegos...)';

  @override
  String get postUploadImagesBtn => 'Subir imágenes';

  @override
  String get postUploadVideoBtn => 'Subir vídeo';

  @override
  String get postPublishBtn => 'Publicar';

  @override
  String get postSaveChangesBtn => 'Guardar Cambios';

  @override
  String get postMaxFilesError => 'Máximo 4 archivos por post';

  @override
  String postFileTooLarge(String filename, String size) {
    return 'El archivo $filename es demasiado grande ($size MB). El límite es 100 MB.';
  }

  @override
  String postSuccessAdd(String type, String gender) {
    return '¡$type añadid$gender con éxito! 🐾';
  }

  @override
  String get postAddedToCollection => '¡Añadida a la colección!';

  @override
  String get messageCreateChat => 'Crear Chat';

  @override
  String get messageParticipantsHint => 'Buscar participantes...';

  @override
  String get messageNoUsers => 'No se encontraron Myngos 😿';

  @override
  String get messageSearchHint => 'Busca en el universo Myngo... 🐾';

  @override
  String get collectionNewCollection => 'Nueva Colección';

  @override
  String get collectionNewCollectionHint => 'Nombre de la colección';

  @override
  String get collectionPublic => 'Pública';

  @override
  String get collectionPrivate => 'Privada';

  @override
  String get collectionPublicDesc => 'Cualquiera podrá verla';

  @override
  String get collectionPrivateDesc => 'Solo tú la verás';

  @override
  String get collectionCreateBtn => 'CREAR';

  @override
  String get collectionCreated => 'Colección creada';

  @override
  String get collectionAddFromGallery => 'Añadir de mi Galería';

  @override
  String get collectionAddFromGalleryDesc =>
      'Reaprovecha una foto que ya subiste';

  @override
  String get collectionUploadPhoto => 'Subir Foto a esta Carpeta';

  @override
  String get collectionUploadPhotoDesc => 'Captura nueva que irá directo aquí';

  @override
  String get collectionUploadPhotoRaw => 'Subir Imagen Cruda';

  @override
  String get collectionUploadPhotoRawDesc =>
      'Directo a tu galería local o de comunidad';

  @override
  String get collectionUploadVideo => 'Subir Vídeo a esta Carpeta';

  @override
  String get collectionUploadVideoDesc =>
      'Comparte tus mejores momentos en movimiento';

  @override
  String get collectionUploadVideoRaw => 'Subir Vídeo Crudo';

  @override
  String get moderationTitle => 'Moderar Contenido';

  @override
  String get moderationDeleteTitle => '¿Eliminar Contenido?';

  @override
  String get moderationDeleteDesc => 'Esta acción no se puede deshacer.';

  @override
  String get moderationReasonDesc =>
      'Indica el motivo del borrado. El autor recibirá una notificación.';

  @override
  String get moderationReasonHint => 'Motivo del borrado...';

  @override
  String get moderationReportTitle => 'Reportar Contenido';

  @override
  String get moderationReportCommentHint => 'Comentario opcional (miau...)';

  @override
  String get moderationReportSpamExample => 'Ej: Spam, lenguaje ofensivo...';

  @override
  String get moderationSendReport => 'Enviar Reporte';

  @override
  String get moderationIgnore => 'IGNORAR';

  @override
  String get settingsAdjustmentsSoon => 'Ajustes próximamente 🐾';

  @override
  String get settingsUpcoming => 'Próximamente 🐾';

  @override
  String get registrationUnite => 'UNETE';

  @override
  String get registrationTitle => '¡Únete a Myngo!';

  @override
  String get registrationSubtitle => 'Crea tu rincón para empezar 🐾';

  @override
  String get registrationRules => 'Reglas de la Comunidad 🐾';

  @override
  String get registrationRulesError => 'Error al cargar reglas 😿';

  @override
  String get registrationAcceptTerms => 'Acepto los miau-términos';

  @override
  String get registrationDeclineTerms => 'Declino y me voy 😿';

  @override
  String get registrationEmailSent =>
      '¡Miau! Revisa tu correo para activar tu cuenta 📧';

  @override
  String get registrationContinue => 'CONTINUAR 🐾';

  @override
  String get registrationContinueBtn => 'CONTINUAR';

  @override
  String get recoveryTitle => '¿Perdiste tu Clave?';

  @override
  String get recoverySubtitle => 'Te ayudaremos a recuperar tu cuenta';

  @override
  String get recoveryRemembered => 'ME ACORDÉ, VOLVER';

  @override
  String get recoveryInstructions =>
      'Te enviaremos un enlace para restablecer tu contraseña';

  @override
  String get languageTitle => 'Cambiar idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get rankMichiBronze => 'Michi de Bronce';

  @override
  String get rankMichiSilver => 'Michi de Plata';

  @override
  String get rankMichiGold => 'Michi de Oro';

  @override
  String get rankMichiDiamond => 'Michi de Diamante';

  @override
  String rankPoints(String count) {
    return '$count / 5000 Puntos';
  }

  @override
  String rankMinLevel(String rating) {
    return 'Necesitas una media de $rating ⭐ para unirte a este selecto grupo.';
  }

  @override
  String get statusActive => 'Activo';

  @override
  String get statusBusy => 'Ocupado';

  @override
  String get statusOffline => 'Desconectado';

  @override
  String get statusOnline => 'En línea';

  @override
  String get emptyStateSearchNoResults => 'No se encontraron resultados';

  @override
  String get emptyStateCommunitiesList =>
      'Únete a una comunidad para empezar 🐾';

  @override
  String get emptyStateRanking => 'Aún no hay ranking 🐾';

  @override
  String get errorGeneric => 'Algo salió mal 😿';

  @override
  String get errorNetworkConnection => 'Error de conexión';

  @override
  String get errorUnexpected => 'Error inesperado';

  @override
  String get errorLoadingGallery => 'Error al cargar galería';

  @override
  String get errorInvalidEmail => 'Email inválido';

  @override
  String get errorPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get videoRetry => 'Reintentar';

  @override
  String get videoErrorLoading => 'Error al cargar vídeo';

  @override
  String get previewLiveInfo => 'VISTA PREVIA EN TIEMPO REAL';

  @override
  String get previewLiveDesc =>
      'Los cambios se reflejan al instante. Pulsa \'Guardar\' para aplicar permanentemente.';

  @override
  String get communityViewCommunity => 'Ver comunidad';

  @override
  String get communityManage => 'Administrar Comunidad';

  @override
  String get communityCloseView => 'Cerrar vista de comunidad';

  @override
  String get communityTabsPosts => 'POSTS';

  @override
  String get communityTabsShop => 'TIENDA';

  @override
  String get communityTabsGallery => 'GALERÍA';

  @override
  String get communityTabsChats => 'CHATS';

  @override
  String get communityTabsMembers => 'MIEMBROS';

  @override
  String get myGatosTitle => 'Mis Michi-Grupos';

  @override
  String get myGatosHint =>
      'Mantén presionado y arrastra para reordenar tus favoritos 🐾';

  @override
  String get noGatosMessage => 'Aún no hay datos 😿';
}
