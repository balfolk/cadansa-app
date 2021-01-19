import 'package:cadansa_app/data/parse_utils.dart';

class Localization {
  Localization._();

  static final TIMEOUT_MESSAGE = LText(const {
    'en': "Could not connect to the server. Please make sure you're connected to the Internet.",
    'nl': 'Het is niet gelukt verbinding te maken met de server. Controleer of je internetverbinding aanstaat.',
    'fr': 'Échec du téléchargement du fichier. Assurez-vous que votre connexion Internet fonctionne.'
  });
  static final REFRESH = LText(const {
    'en': 'Refresh',
    'nl': 'Probeer opnieuw',
    'fr': 'Réessayer',
  });
  static final FEED_EMPTY = LText(const {
    'en': 'There is no news at the moment. Check again later!',
  });
}
