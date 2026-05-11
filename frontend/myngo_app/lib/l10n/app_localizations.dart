import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'MYNGO'**
  String get appTitle;

  /// No description provided for @authLoginButton.
  ///
  /// In es, this message translates to:
  /// **'INICIAR SESIÓN 🐾'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'REGISTRARME 🐾'**
  String get authRegisterButton;

  /// No description provided for @authRegisterLink.
  ///
  /// In es, this message translates to:
  /// **'¿Aún no tienes cuenta?'**
  String get authRegisterLink;

  /// No description provided for @authLoginLink.
  ///
  /// In es, this message translates to:
  /// **'¿Ya eres parte?'**
  String get authLoginLink;

  /// No description provided for @authLoginLinkAction.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authLoginLinkAction;

  /// No description provided for @authForgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Perdiste tu clave?'**
  String get authForgotPassword;

  /// No description provided for @authConnectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Inténtalo de nuevo.'**
  String get authConnectionError;

  /// No description provided for @formEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get formEmailLabel;

  /// No description provided for @formEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get formEmailHint;

  /// No description provided for @formPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get formPasswordLabel;

  /// No description provided for @formUsernameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get formUsernameLabel;

  /// No description provided for @formUsernameHint.
  ///
  /// In es, this message translates to:
  /// **'¿Tu nombre? 🐾'**
  String get formUsernameHint;

  /// No description provided for @formUsernameMinLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 3 letras'**
  String get formUsernameMinLength;

  /// No description provided for @formBioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos algo sobre ti...'**
  String get formBioHint;

  /// No description provided for @formChatNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del Chat'**
  String get formChatNameLabel;

  /// No description provided for @formChatNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Grupo de estudio, Plan finde...'**
  String get formChatNameHint;

  /// No description provided for @profileLoadingTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargando perfil...'**
  String get profileLoadingTitle;

  /// No description provided for @profileLoadingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Espere un momento...'**
  String get profileLoadingSubtitle;

  /// No description provided for @profileNotFoundTitle.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get profileNotFoundTitle;

  /// No description provided for @profileNotFoundEmoji.
  ///
  /// In es, this message translates to:
  /// **'😿'**
  String get profileNotFoundEmoji;

  /// No description provided for @profileTabsPosts.
  ///
  /// In es, this message translates to:
  /// **'Posts'**
  String get profileTabsPosts;

  /// No description provided for @profileTabsFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get profileTabsFavorites;

  /// No description provided for @profileTabsCollections.
  ///
  /// In es, this message translates to:
  /// **'Colecciones'**
  String get profileTabsCollections;

  /// No description provided for @profileVoteTitleChange.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres hacer con tu voto?'**
  String get profileVoteTitleChange;

  /// No description provided for @profileVoteTitleNew.
  ///
  /// In es, this message translates to:
  /// **'¡Vota a este Michi!'**
  String get profileVoteTitleNew;

  /// No description provided for @profileVoteDescChange.
  ///
  /// In es, this message translates to:
  /// **'Puedes cambiar tu puntuación o eliminar el voto.'**
  String get profileVoteDescChange;

  /// No description provided for @profileVoteDescNew.
  ///
  /// In es, this message translates to:
  /// **'Dalle amor con tus estrellas 🐾'**
  String get profileVoteDescNew;

  /// No description provided for @profileVoteRemoveLabel.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi voto'**
  String get profileVoteRemoveLabel;

  /// No description provided for @profileEditBioTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Biografía'**
  String get profileEditBioTitle;

  /// No description provided for @profileBioHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos algo sobre ti...'**
  String get profileBioHint;

  /// No description provided for @profileCreatePostLabel.
  ///
  /// In es, this message translates to:
  /// **'Subir Post'**
  String get profileCreatePostLabel;

  /// No description provided for @profileVoteRemoveTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi voto'**
  String get profileVoteRemoveTooltip;

  /// No description provided for @profileNotFound.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado 😿'**
  String get profileNotFound;

  /// No description provided for @profileEditBio.
  ///
  /// In es, this message translates to:
  /// **'Editar Biografía'**
  String get profileEditBio;

  /// No description provided for @profileSaveBio.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileSaveBio;

  /// No description provided for @profileCancelBio.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get profileCancelBio;

  /// No description provided for @profileVoteRemove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi voto'**
  String get profileVoteRemove;

  /// No description provided for @profileJoined.
  ///
  /// In es, this message translates to:
  /// **'Se unió en {date}'**
  String profileJoined(String date);

  /// No description provided for @profileFollowersCount.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get profileFollowersCount;

  /// No description provided for @profileFollowingCount.
  ///
  /// In es, this message translates to:
  /// **'Seguidos'**
  String get profileFollowingCount;

  /// No description provided for @chatPersonalization.
  ///
  /// In es, this message translates to:
  /// **'Personalizar Chat'**
  String get chatPersonalization;

  /// No description provided for @chatSaveSettings.
  ///
  /// In es, this message translates to:
  /// **'GUARDAR'**
  String get chatSaveSettings;

  /// No description provided for @chatConfigSaved.
  ///
  /// In es, this message translates to:
  /// **'Configuración guardada correctamente'**
  String get chatConfigSaved;

  /// No description provided for @chatConfigError.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar la configuración'**
  String get chatConfigError;

  /// No description provided for @chatImageUploadError.
  ///
  /// In es, this message translates to:
  /// **'Error al subir la imagen'**
  String get chatImageUploadError;

  /// No description provided for @chatPreviewLive.
  ///
  /// In es, this message translates to:
  /// **'VISTA PREVIA EN TIEMPO REAL'**
  String get chatPreviewLive;

  /// No description provided for @chatResetDesign.
  ///
  /// In es, this message translates to:
  /// **'Restablecer diseño por defecto'**
  String get chatResetDesign;

  /// No description provided for @chatIdentitySection.
  ///
  /// In es, this message translates to:
  /// **'Identidad del Chat'**
  String get chatIdentitySection;

  /// No description provided for @chatColorsSection.
  ///
  /// In es, this message translates to:
  /// **'Colores de Burbujas'**
  String get chatColorsSection;

  /// No description provided for @chatBackgroundSection.
  ///
  /// In es, this message translates to:
  /// **'Patrón y Estilo de Fondo'**
  String get chatBackgroundSection;

  /// No description provided for @chatBubbleSection.
  ///
  /// In es, this message translates to:
  /// **'Estilo de Burbujas'**
  String get chatBubbleSection;

  /// No description provided for @chatBackgroundGradient.
  ///
  /// In es, this message translates to:
  /// **'Gradiente de fondo'**
  String get chatBackgroundGradient;

  /// No description provided for @chatBackgroundPattern.
  ///
  /// In es, this message translates to:
  /// **'Patrón geométrico'**
  String get chatBackgroundPattern;

  /// No description provided for @chatBubbleStyle.
  ///
  /// In es, this message translates to:
  /// **'Estilo visual de burbuja'**
  String get chatBubbleStyle;

  /// No description provided for @chatBubbleShape.
  ///
  /// In es, this message translates to:
  /// **'Forma de las burbujas'**
  String get chatBubbleShape;

  /// No description provided for @chatFontSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de fuente'**
  String get chatFontSize;

  /// No description provided for @chatGradientSunset.
  ///
  /// In es, this message translates to:
  /// **'Atardecer'**
  String get chatGradientSunset;

  /// No description provided for @chatGradientOcean.
  ///
  /// In es, this message translates to:
  /// **'Océano'**
  String get chatGradientOcean;

  /// No description provided for @chatGradientForest.
  ///
  /// In es, this message translates to:
  /// **'Bosque'**
  String get chatGradientForest;

  /// No description provided for @chatGradientGalaxy.
  ///
  /// In es, this message translates to:
  /// **'Galaxia'**
  String get chatGradientGalaxy;

  /// No description provided for @chatGradientNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get chatGradientNight;

  /// No description provided for @chatGradientPeach.
  ///
  /// In es, this message translates to:
  /// **'Melocotón'**
  String get chatGradientPeach;

  /// No description provided for @chatGradientLavender.
  ///
  /// In es, this message translates to:
  /// **'Lavanda'**
  String get chatGradientLavender;

  /// No description provided for @chatPatternDots.
  ///
  /// In es, this message translates to:
  /// **'Puntos'**
  String get chatPatternDots;

  /// No description provided for @chatPatternStars.
  ///
  /// In es, this message translates to:
  /// **'Estrellas'**
  String get chatPatternStars;

  /// No description provided for @chatPatternTriangles.
  ///
  /// In es, this message translates to:
  /// **'Geométrico'**
  String get chatPatternTriangles;

  /// No description provided for @chatPatternWaves.
  ///
  /// In es, this message translates to:
  /// **'Ondas'**
  String get chatPatternWaves;

  /// No description provided for @chatPatternLines.
  ///
  /// In es, this message translates to:
  /// **'Líneas'**
  String get chatPatternLines;

  /// No description provided for @chatStyleSolid.
  ///
  /// In es, this message translates to:
  /// **'Sólido'**
  String get chatStyleSolid;

  /// No description provided for @chatStyleCrystal.
  ///
  /// In es, this message translates to:
  /// **'Cristal'**
  String get chatStyleCrystal;

  /// No description provided for @chatStyleNeon.
  ///
  /// In es, this message translates to:
  /// **'Neón'**
  String get chatStyleNeon;

  /// No description provided for @chatStyleLove.
  ///
  /// In es, this message translates to:
  /// **'Amor'**
  String get chatStyleLove;

  /// No description provided for @chatStyleCowboy.
  ///
  /// In es, this message translates to:
  /// **'Vaquero'**
  String get chatStyleCowboy;

  /// No description provided for @chatStyleForest.
  ///
  /// In es, this message translates to:
  /// **'Bosque'**
  String get chatStyleForest;

  /// No description provided for @chatStyleCyber.
  ///
  /// In es, this message translates to:
  /// **'Cyber'**
  String get chatStyleCyber;

  /// No description provided for @chatStyleKawaii.
  ///
  /// In es, this message translates to:
  /// **'Kawaii'**
  String get chatStyleKawaii;

  /// No description provided for @chatStyleAdventure.
  ///
  /// In es, this message translates to:
  /// **'Aventura'**
  String get chatStyleAdventure;

  /// No description provided for @navigationHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navigationHome;

  /// No description provided for @navigationExplore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get navigationExplore;

  /// No description provided for @navigationShop.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get navigationShop;

  /// No description provided for @navigationChats.
  ///
  /// In es, this message translates to:
  /// **'Chats'**
  String get navigationChats;

  /// No description provided for @navigationNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get navigationNotifications;

  /// No description provided for @navigationProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi Perfil'**
  String get navigationProfile;

  /// No description provided for @navigationSettings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get navigationSettings;

  /// No description provided for @navigationLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Miau-Sesión'**
  String get navigationLogout;

  /// No description provided for @navigationError.
  ///
  /// In es, this message translates to:
  /// **'Error de Navegación 🐾'**
  String get navigationError;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'REINTENTAR'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @communityCreateBtn.
  ///
  /// In es, this message translates to:
  /// **'EMPEZAR YA'**
  String get communityCreateBtn;

  /// No description provided for @communityHaveAPet.
  ///
  /// In es, this message translates to:
  /// **'¿TIENES UN MICHI?'**
  String get communityHaveAPet;

  /// No description provided for @communityHavePetDesc.
  ///
  /// In es, this message translates to:
  /// **'¡Crea tu propia comunidad y presume de mascota!'**
  String get communityHavePetDesc;

  /// No description provided for @communitySuggestions.
  ///
  /// In es, this message translates to:
  /// **'MIAU-SUGERENCIAS'**
  String get communitySuggestions;

  /// No description provided for @communityExploreMore.
  ///
  /// In es, this message translates to:
  /// **'Explora para ver más 🐾'**
  String get communityExploreMore;

  /// No description provided for @communityNoJoined.
  ///
  /// In es, this message translates to:
  /// **'Únete a una comunidad 🐾'**
  String get communityNoJoined;

  /// No description provided for @communityMembers.
  ///
  /// In es, this message translates to:
  /// **'{count} Miembros'**
  String communityMembers(String count);

  /// No description provided for @communityRanking.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay ranking 🐾'**
  String get communityRanking;

  /// No description provided for @communityJoinedMsg.
  ///
  /// In es, this message translates to:
  /// **'¡Miau-unido con éxito! 🐾'**
  String get communityJoinedMsg;

  /// No description provided for @communityJoinNeedLogin.
  ///
  /// In es, this message translates to:
  /// **'¡Vaya! Debes iniciar miau-sesión para unirte 🐾'**
  String get communityJoinNeedLogin;

  /// No description provided for @postUploadLabel.
  ///
  /// In es, this message translates to:
  /// **'Subir Post'**
  String get postUploadLabel;

  /// No description provided for @postCreateHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué estás pensando, miau?'**
  String get postCreateHint;

  /// No description provided for @postTagsHint.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas (ej. arte, animales, juegos...)'**
  String get postTagsHint;

  /// No description provided for @postUploadImagesBtn.
  ///
  /// In es, this message translates to:
  /// **'Subir imágenes'**
  String get postUploadImagesBtn;

  /// No description provided for @postUploadVideoBtn.
  ///
  /// In es, this message translates to:
  /// **'Subir vídeo'**
  String get postUploadVideoBtn;

  /// No description provided for @postPublishBtn.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get postPublishBtn;

  /// No description provided for @postSaveChangesBtn.
  ///
  /// In es, this message translates to:
  /// **'Guardar Cambios'**
  String get postSaveChangesBtn;

  /// No description provided for @postMaxFilesError.
  ///
  /// In es, this message translates to:
  /// **'Máximo 4 archivos por post'**
  String get postMaxFilesError;

  /// No description provided for @postFileTooLarge.
  ///
  /// In es, this message translates to:
  /// **'El archivo {filename} es demasiado grande ({size} MB). El límite es 100 MB.'**
  String postFileTooLarge(String filename, String size);

  /// No description provided for @postSuccessAdd.
  ///
  /// In es, this message translates to:
  /// **'¡{type} añadid{gender} con éxito! 🐾'**
  String postSuccessAdd(String type, String gender);

  /// No description provided for @postAddedToCollection.
  ///
  /// In es, this message translates to:
  /// **'¡Añadida a la colección!'**
  String get postAddedToCollection;

  /// No description provided for @messageCreateChat.
  ///
  /// In es, this message translates to:
  /// **'Crear Chat'**
  String get messageCreateChat;

  /// No description provided for @messageParticipantsHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar participantes...'**
  String get messageParticipantsHint;

  /// No description provided for @messageNoUsers.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron Myngos 😿'**
  String get messageNoUsers;

  /// No description provided for @messageSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Busca en el universo Myngo... 🐾'**
  String get messageSearchHint;

  /// No description provided for @collectionNewCollection.
  ///
  /// In es, this message translates to:
  /// **'Nueva Colección'**
  String get collectionNewCollection;

  /// No description provided for @collectionNewCollectionHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la colección'**
  String get collectionNewCollectionHint;

  /// No description provided for @collectionPublic.
  ///
  /// In es, this message translates to:
  /// **'Pública'**
  String get collectionPublic;

  /// No description provided for @collectionPrivate.
  ///
  /// In es, this message translates to:
  /// **'Privada'**
  String get collectionPrivate;

  /// No description provided for @collectionPublicDesc.
  ///
  /// In es, this message translates to:
  /// **'Cualquiera podrá verla'**
  String get collectionPublicDesc;

  /// No description provided for @collectionPrivateDesc.
  ///
  /// In es, this message translates to:
  /// **'Solo tú la verás'**
  String get collectionPrivateDesc;

  /// No description provided for @collectionCreateBtn.
  ///
  /// In es, this message translates to:
  /// **'CREAR'**
  String get collectionCreateBtn;

  /// No description provided for @collectionCreated.
  ///
  /// In es, this message translates to:
  /// **'Colección creada'**
  String get collectionCreated;

  /// No description provided for @collectionAddFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Añadir de mi Galería'**
  String get collectionAddFromGallery;

  /// No description provided for @collectionAddFromGalleryDesc.
  ///
  /// In es, this message translates to:
  /// **'Reaprovecha una foto que ya subiste'**
  String get collectionAddFromGalleryDesc;

  /// No description provided for @collectionUploadPhoto.
  ///
  /// In es, this message translates to:
  /// **'Subir Foto a esta Carpeta'**
  String get collectionUploadPhoto;

  /// No description provided for @collectionUploadPhotoDesc.
  ///
  /// In es, this message translates to:
  /// **'Captura nueva que irá directo aquí'**
  String get collectionUploadPhotoDesc;

  /// No description provided for @collectionUploadPhotoRaw.
  ///
  /// In es, this message translates to:
  /// **'Subir Imagen Cruda'**
  String get collectionUploadPhotoRaw;

  /// No description provided for @collectionUploadPhotoRawDesc.
  ///
  /// In es, this message translates to:
  /// **'Directo a tu galería local o de comunidad'**
  String get collectionUploadPhotoRawDesc;

  /// No description provided for @collectionUploadVideo.
  ///
  /// In es, this message translates to:
  /// **'Subir Vídeo a esta Carpeta'**
  String get collectionUploadVideo;

  /// No description provided for @collectionUploadVideoDesc.
  ///
  /// In es, this message translates to:
  /// **'Comparte tus mejores momentos en movimiento'**
  String get collectionUploadVideoDesc;

  /// No description provided for @collectionUploadVideoRaw.
  ///
  /// In es, this message translates to:
  /// **'Subir Vídeo Crudo'**
  String get collectionUploadVideoRaw;

  /// No description provided for @moderationTitle.
  ///
  /// In es, this message translates to:
  /// **'Moderar Contenido'**
  String get moderationTitle;

  /// No description provided for @moderationDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar Contenido?'**
  String get moderationDeleteTitle;

  /// No description provided for @moderationDeleteDesc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get moderationDeleteDesc;

  /// No description provided for @moderationReasonDesc.
  ///
  /// In es, this message translates to:
  /// **'Indica el motivo del borrado. El autor recibirá una notificación.'**
  String get moderationReasonDesc;

  /// No description provided for @moderationReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Motivo del borrado...'**
  String get moderationReasonHint;

  /// No description provided for @moderationReportTitle.
  ///
  /// In es, this message translates to:
  /// **'Reportar Contenido'**
  String get moderationReportTitle;

  /// No description provided for @moderationReportCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Comentario opcional (miau...)'**
  String get moderationReportCommentHint;

  /// No description provided for @moderationReportSpamExample.
  ///
  /// In es, this message translates to:
  /// **'Ej: Spam, lenguaje ofensivo...'**
  String get moderationReportSpamExample;

  /// No description provided for @moderationSendReport.
  ///
  /// In es, this message translates to:
  /// **'Enviar Reporte'**
  String get moderationSendReport;

  /// No description provided for @moderationIgnore.
  ///
  /// In es, this message translates to:
  /// **'IGNORAR'**
  String get moderationIgnore;

  /// No description provided for @settingsAdjustmentsSoon.
  ///
  /// In es, this message translates to:
  /// **'Ajustes próximamente 🐾'**
  String get settingsAdjustmentsSoon;

  /// No description provided for @settingsUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximamente 🐾'**
  String get settingsUpcoming;

  /// No description provided for @registrationUnite.
  ///
  /// In es, this message translates to:
  /// **'UNETE'**
  String get registrationUnite;

  /// No description provided for @registrationTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Únete a Myngo!'**
  String get registrationTitle;

  /// No description provided for @registrationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu rincón para empezar 🐾'**
  String get registrationSubtitle;

  /// No description provided for @registrationRules.
  ///
  /// In es, this message translates to:
  /// **'Reglas de la Comunidad 🐾'**
  String get registrationRules;

  /// No description provided for @registrationRulesError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar reglas 😿'**
  String get registrationRulesError;

  /// No description provided for @registrationAcceptTerms.
  ///
  /// In es, this message translates to:
  /// **'Acepto los miau-términos'**
  String get registrationAcceptTerms;

  /// No description provided for @registrationDeclineTerms.
  ///
  /// In es, this message translates to:
  /// **'Declino y me voy 😿'**
  String get registrationDeclineTerms;

  /// No description provided for @registrationEmailSent.
  ///
  /// In es, this message translates to:
  /// **'¡Miau! Revisa tu correo para activar tu cuenta 📧'**
  String get registrationEmailSent;

  /// No description provided for @registrationContinue.
  ///
  /// In es, this message translates to:
  /// **'CONTINUAR 🐾'**
  String get registrationContinue;

  /// No description provided for @registrationContinueBtn.
  ///
  /// In es, this message translates to:
  /// **'CONTINUAR'**
  String get registrationContinueBtn;

  /// No description provided for @recoveryTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Perdiste tu Clave?'**
  String get recoveryTitle;

  /// No description provided for @recoverySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te ayudaremos a recuperar tu cuenta'**
  String get recoverySubtitle;

  /// No description provided for @recoveryRemembered.
  ///
  /// In es, this message translates to:
  /// **'ME ACORDÉ, VOLVER'**
  String get recoveryRemembered;

  /// No description provided for @recoveryInstructions.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un enlace para restablecer tu contraseña'**
  String get recoveryInstructions;

  /// No description provided for @languageTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar idioma'**
  String get languageTitle;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @rankMichiBronze.
  ///
  /// In es, this message translates to:
  /// **'Michi de Bronce'**
  String get rankMichiBronze;

  /// No description provided for @rankMichiSilver.
  ///
  /// In es, this message translates to:
  /// **'Michi de Plata'**
  String get rankMichiSilver;

  /// No description provided for @rankMichiGold.
  ///
  /// In es, this message translates to:
  /// **'Michi de Oro'**
  String get rankMichiGold;

  /// No description provided for @rankMichiDiamond.
  ///
  /// In es, this message translates to:
  /// **'Michi de Diamante'**
  String get rankMichiDiamond;

  /// No description provided for @rankPoints.
  ///
  /// In es, this message translates to:
  /// **'{count} / 5000 Puntos'**
  String rankPoints(String count);

  /// No description provided for @rankMinLevel.
  ///
  /// In es, this message translates to:
  /// **'Necesitas una media de {rating} ⭐ para unirte a este selecto grupo.'**
  String rankMinLevel(String rating);

  /// No description provided for @statusActive.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get statusActive;

  /// No description provided for @statusBusy.
  ///
  /// In es, this message translates to:
  /// **'Ocupado'**
  String get statusBusy;

  /// No description provided for @statusOffline.
  ///
  /// In es, this message translates to:
  /// **'Desconectado'**
  String get statusOffline;

  /// No description provided for @statusOnline.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get statusOnline;

  /// No description provided for @emptyStateSearchNoResults.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron resultados'**
  String get emptyStateSearchNoResults;

  /// No description provided for @emptyStateCommunitiesList.
  ///
  /// In es, this message translates to:
  /// **'Únete a una comunidad para empezar 🐾'**
  String get emptyStateCommunitiesList;

  /// No description provided for @emptyStateRanking.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay ranking 🐾'**
  String get emptyStateRanking;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal 😿'**
  String get errorGeneric;

  /// No description provided for @errorNetworkConnection.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get errorNetworkConnection;

  /// No description provided for @errorUnexpected.
  ///
  /// In es, this message translates to:
  /// **'Error inesperado'**
  String get errorUnexpected;

  /// No description provided for @errorLoadingGallery.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar galería'**
  String get errorLoadingGallery;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get errorInvalidEmail;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get errorPasswordMismatch;

  /// No description provided for @videoRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get videoRetry;

  /// No description provided for @videoErrorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar vídeo'**
  String get videoErrorLoading;

  /// No description provided for @previewLiveInfo.
  ///
  /// In es, this message translates to:
  /// **'VISTA PREVIA EN TIEMPO REAL'**
  String get previewLiveInfo;

  /// No description provided for @previewLiveDesc.
  ///
  /// In es, this message translates to:
  /// **'Los cambios se reflejan al instante. Pulsa \'Guardar\' para aplicar permanentemente.'**
  String get previewLiveDesc;

  /// No description provided for @communityViewCommunity.
  ///
  /// In es, this message translates to:
  /// **'Ver comunidad'**
  String get communityViewCommunity;

  /// No description provided for @communityManage.
  ///
  /// In es, this message translates to:
  /// **'Administrar Comunidad'**
  String get communityManage;

  /// No description provided for @communityCloseView.
  ///
  /// In es, this message translates to:
  /// **'Cerrar vista de comunidad'**
  String get communityCloseView;

  /// No description provided for @communityTabsPosts.
  ///
  /// In es, this message translates to:
  /// **'POSTS'**
  String get communityTabsPosts;

  /// No description provided for @communityTabsShop.
  ///
  /// In es, this message translates to:
  /// **'TIENDA'**
  String get communityTabsShop;

  /// No description provided for @communityTabsGallery.
  ///
  /// In es, this message translates to:
  /// **'GALERÍA'**
  String get communityTabsGallery;

  /// No description provided for @communityTabsChats.
  ///
  /// In es, this message translates to:
  /// **'CHATS'**
  String get communityTabsChats;

  /// No description provided for @communityTabsMembers.
  ///
  /// In es, this message translates to:
  /// **'MIEMBROS'**
  String get communityTabsMembers;

  /// No description provided for @myGatosTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Michi-Grupos'**
  String get myGatosTitle;

  /// No description provided for @myGatosHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén presionado y arrastra para reordenar tus favoritos 🐾'**
  String get myGatosHint;

  /// No description provided for @noGatosMessage.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay datos 😿'**
  String get noGatosMessage;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
