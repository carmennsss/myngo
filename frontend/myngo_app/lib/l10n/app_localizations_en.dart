// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MYNGO';

  @override
  String get authLoginButton => 'SIGN IN 🐾';

  @override
  String get authRegisterButton => 'REGISTER 🐾';

  @override
  String get authRegisterLink => 'Don\'t have an account?';

  @override
  String get authLoginLink => 'Already a member?';

  @override
  String get authLoginLinkAction => 'Sign in';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authConnectionError => 'Connection error. Please try again.';

  @override
  String get formEmailLabel => 'Email';

  @override
  String get formEmailHint => 'your@email.com';

  @override
  String get formPasswordLabel => 'Password';

  @override
  String get formUsernameLabel => 'Username';

  @override
  String get formUsernameHint => 'Your name? 🐾';

  @override
  String get formUsernameMinLength => 'Minimum 3 characters';

  @override
  String get formBioHint => 'Tell us something about yourself...';

  @override
  String get formChatNameLabel => 'Chat Name';

  @override
  String get formChatNameHint => 'E.g: Study group, Weekend plan...';

  @override
  String get profileLoadingTitle => 'Loading profile...';

  @override
  String get profileLoadingSubtitle => 'Please wait...';

  @override
  String get profileNotFoundTitle => 'User not found';

  @override
  String get profileNotFoundEmoji => '😿';

  @override
  String get profileTabsPosts => 'Posts';

  @override
  String get profileTabsFavorites => 'Favorites';

  @override
  String get profileTabsCollections => 'Collections';

  @override
  String get profileVoteTitleChange => 'What do you want to do with your vote?';

  @override
  String get profileVoteTitleNew => 'Vote for this Michi!';

  @override
  String get profileVoteDescChange =>
      'You can change your rating or remove the vote.';

  @override
  String get profileVoteDescNew => 'Give love with your stars 🐾';

  @override
  String get profileVoteRemoveLabel => 'Remove my vote';

  @override
  String get profileEditBioTitle => 'Edit Biography';

  @override
  String get profileBioHint => 'Tell us something about yourself...';

  @override
  String get profileCreatePostLabel => 'Upload Post';

  @override
  String get profileVoteRemoveTooltip => 'Remove my vote';

  @override
  String get profileNotFound => 'User not found 😿';

  @override
  String get profileEditBio => 'Edit Bio';

  @override
  String get profileSaveBio => 'Save';

  @override
  String get profileCancelBio => 'Cancel';

  @override
  String get profileVoteRemove => 'Remove my vote';

  @override
  String profileJoined(String date) {
    return 'Joined in $date';
  }

  @override
  String get profileFollowersCount => 'Followers';

  @override
  String get profileFollowingCount => 'Following';

  @override
  String get chatPersonalization => 'Customize Chat';

  @override
  String get chatSaveSettings => 'SAVE';

  @override
  String get chatConfigSaved => 'Configuration saved successfully';

  @override
  String get chatConfigError => 'Error saving configuration';

  @override
  String get chatImageUploadError => 'Error uploading image';

  @override
  String get chatPreviewLive => 'LIVE PREVIEW';

  @override
  String get chatResetDesign => 'Reset to default design';

  @override
  String get chatIdentitySection => 'Chat Identity';

  @override
  String get chatColorsSection => 'Bubble Colors';

  @override
  String get chatBackgroundSection => 'Pattern and Background Style';

  @override
  String get chatBubbleSection => 'Bubble Style';

  @override
  String get chatBackgroundGradient => 'Background gradient';

  @override
  String get chatBackgroundPattern => 'Geometric pattern';

  @override
  String get chatBubbleStyle => 'Bubble visual style';

  @override
  String get chatBubbleShape => 'Bubble shape';

  @override
  String get chatFontSize => 'Font size';

  @override
  String get chatGradientSunset => 'Sunset';

  @override
  String get chatGradientOcean => 'Ocean';

  @override
  String get chatGradientForest => 'Forest';

  @override
  String get chatGradientGalaxy => 'Galaxy';

  @override
  String get chatGradientNight => 'Night';

  @override
  String get chatGradientPeach => 'Peach';

  @override
  String get chatGradientLavender => 'Lavender';

  @override
  String get chatPatternDots => 'Dots';

  @override
  String get chatPatternStars => 'Stars';

  @override
  String get chatPatternTriangles => 'Geometric';

  @override
  String get chatPatternWaves => 'Waves';

  @override
  String get chatPatternLines => 'Lines';

  @override
  String get chatStyleSolid => 'Solid';

  @override
  String get chatStyleCrystal => 'Crystal';

  @override
  String get chatStyleNeon => 'Neon';

  @override
  String get chatStyleLove => 'Love';

  @override
  String get chatStyleCowboy => 'Cowboy';

  @override
  String get chatStyleForest => 'Forest';

  @override
  String get chatStyleCyber => 'Cyber';

  @override
  String get chatStyleKawaii => 'Kawaii';

  @override
  String get chatStyleAdventure => 'Adventure';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationExplore => 'Explore';

  @override
  String get navigationShop => 'Shop';

  @override
  String get navigationChats => 'Chats';

  @override
  String get navigationNotifications => 'Notifications';

  @override
  String get navigationProfile => 'My Profile';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get navigationLogout => 'Sign Out';

  @override
  String get navigationError => 'Navigation Error 🐾';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'RETRY';

  @override
  String get commonClose => 'Close';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get communityCreateBtn => 'START NOW';

  @override
  String get communityHaveAPet => 'DO YOU HAVE A MICHI?';

  @override
  String get communityHavePetDesc =>
      'Create your own community and show off your pet!';

  @override
  String get communitySuggestions => 'MEW-SUGGESTIONS';

  @override
  String get communityExploreMore => 'Explore to see more 🐾';

  @override
  String get communityNoJoined => 'Join a community to get started 🐾';

  @override
  String communityMembers(String count) {
    return '$count Members';
  }

  @override
  String get communityRanking => 'No ranking yet 🐾';

  @override
  String get communityJoinedMsg => 'Meow-joined successfully! 🐾';

  @override
  String get communityJoinNeedLogin => 'Oops! You need to sign in to join 🐾';

  @override
  String get postUploadLabel => 'Upload Post';

  @override
  String get postCreateHint => 'What are you thinking, meow?';

  @override
  String get postTagsHint => 'Tags (e.g. art, animals, games...)';

  @override
  String get postUploadImagesBtn => 'Upload images';

  @override
  String get postUploadVideoBtn => 'Upload video';

  @override
  String get postPublishBtn => 'Publish';

  @override
  String get postSaveChangesBtn => 'Save Changes';

  @override
  String get postMaxFilesError => 'Maximum 4 files per post';

  @override
  String postFileTooLarge(String filename, String size) {
    return 'File $filename is too large ($size MB). The limit is 100 MB.';
  }

  @override
  String postSuccessAdd(String type, String gender) {
    return '$type added successfully! 🐾';
  }

  @override
  String get postAddedToCollection => 'Added to collection!';

  @override
  String get messageCreateChat => 'Create Chat';

  @override
  String get messageParticipantsHint => 'Search participants...';

  @override
  String get messageNoUsers => 'No Michis found 😿';

  @override
  String get messageSearchHint => 'Search in the Myngo universe... 🐾';

  @override
  String get collectionNewCollection => 'New Collection';

  @override
  String get collectionNewCollectionHint => 'Collection name';

  @override
  String get collectionPublic => 'Public';

  @override
  String get collectionPrivate => 'Private';

  @override
  String get collectionPublicDesc => 'Anyone can see it';

  @override
  String get collectionPrivateDesc => 'Only you can see it';

  @override
  String get collectionCreateBtn => 'CREATE';

  @override
  String get collectionCreated => 'Collection created';

  @override
  String get collectionAddFromGallery => 'Add from My Gallery';

  @override
  String get collectionAddFromGalleryDesc =>
      'Reuse a photo you already uploaded';

  @override
  String get collectionUploadPhoto => 'Upload Photo to this Folder';

  @override
  String get collectionUploadPhotoDesc => 'New capture that goes straight here';

  @override
  String get collectionUploadPhotoRaw => 'Upload Raw Image';

  @override
  String get collectionUploadPhotoRawDesc =>
      'Straight to your local or community gallery';

  @override
  String get collectionUploadVideo => 'Upload Video to this Folder';

  @override
  String get collectionUploadVideoDesc => 'Share your best moments in motion';

  @override
  String get collectionUploadVideoRaw => 'Upload Raw Video';

  @override
  String get moderationTitle => 'Moderate Content';

  @override
  String get moderationDeleteTitle => 'Delete Content?';

  @override
  String get moderationDeleteDesc => 'This action cannot be undone.';

  @override
  String get moderationReasonDesc =>
      'Indicate the reason for deletion. The author will receive a notification.';

  @override
  String get moderationReasonHint => 'Reason for deletion...';

  @override
  String get moderationReportTitle => 'Report Content';

  @override
  String get moderationReportCommentHint => 'Optional comment (meow...)';

  @override
  String get moderationReportSpamExample => 'E.g: Spam, offensive language...';

  @override
  String get moderationSendReport => 'Send Report';

  @override
  String get moderationIgnore => 'IGNORE';

  @override
  String get settingsAdjustmentsSoon => 'Settings coming soon 🐾';

  @override
  String get settingsUpcoming => 'Coming soon 🐾';

  @override
  String get registrationUnite => 'JOIN';

  @override
  String get registrationTitle => 'Join Myngo!';

  @override
  String get registrationSubtitle => 'Create your corner to get started 🐾';

  @override
  String get registrationRules => 'Community Rules 🐾';

  @override
  String get registrationRulesError => 'Error loading rules 😿';

  @override
  String get registrationAcceptTerms => 'I accept the meow-terms';

  @override
  String get registrationDeclineTerms => 'I decline and leave 😿';

  @override
  String get registrationEmailSent =>
      'Meow! Check your email to activate your account 📧';

  @override
  String get registrationContinue => 'CONTINUE 🐾';

  @override
  String get registrationContinueBtn => 'CONTINUE';

  @override
  String get recoveryTitle => 'Forgot Your Password?';

  @override
  String get recoverySubtitle => 'We\'ll help you recover your account';

  @override
  String get recoveryRemembered => 'I REMEMBERED, GO BACK';

  @override
  String get recoveryInstructions =>
      'We\'ll send you a link to reset your password';

  @override
  String get languageTitle => 'Change Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get rankMichiBronze => 'Bronze Michi';

  @override
  String get rankMichiSilver => 'Silver Michi';

  @override
  String get rankMichiGold => 'Gold Michi';

  @override
  String get rankMichiDiamond => 'Diamond Michi';

  @override
  String rankPoints(String count) {
    return '$count / 5000 Points';
  }

  @override
  String rankMinLevel(String rating) {
    return 'You need an average of $rating ⭐ to join this select group.';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusBusy => 'Busy';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusOnline => 'Online';

  @override
  String get emptyStateSearchNoResults => 'No results found';

  @override
  String get emptyStateCommunitiesList => 'Join a community to get started 🐾';

  @override
  String get emptyStateRanking => 'No ranking yet 🐾';

  @override
  String get errorGeneric => 'Something went wrong 😿';

  @override
  String get errorNetworkConnection => 'Connection error';

  @override
  String get errorUnexpected => 'Unexpected error';

  @override
  String get errorLoadingGallery => 'Error loading gallery';

  @override
  String get errorInvalidEmail => 'Invalid email';

  @override
  String get errorPasswordMismatch => 'Passwords don\'t match';

  @override
  String get videoRetry => 'Retry';

  @override
  String get videoErrorLoading => 'Error loading video';

  @override
  String get previewLiveInfo => 'LIVE PREVIEW';

  @override
  String get previewLiveDesc =>
      'Changes reflect instantly. Press \'Save\' to apply permanently.';

  @override
  String get communityViewCommunity => 'View community';

  @override
  String get communityManage => 'Manage Community';

  @override
  String get communityCloseView => 'Close community view';

  @override
  String get communityTabsPosts => 'POSTS';

  @override
  String get communityTabsShop => 'SHOP';

  @override
  String get communityTabsGallery => 'GALLERY';

  @override
  String get communityTabsChats => 'CHATS';

  @override
  String get communityTabsMembers => 'MEMBERS';

  @override
  String get myGatosTitle => 'My Michi-Groups';

  @override
  String get myGatosHint => 'Long press and drag to reorder your favorites 🐾';

  @override
  String get noGatosMessage => 'No data yet 😿';
}
