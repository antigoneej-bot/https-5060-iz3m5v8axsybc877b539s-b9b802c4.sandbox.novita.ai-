/// A link is included only after the publisher configures the actual Play page.
Uri? gardenPostcardLink(String configuredUrl) {
  final source = Uri.tryParse(configuredUrl.trim());
  if (source == null ||
      source.scheme != 'https' ||
      source.host != 'play.google.com' ||
      source.userInfo.isNotEmpty ||
      source.hasPort ||
      source.path != '/store/apps/details' ||
      source.queryParameters['id'] != 'com.mysticcat.journal') {
    return null;
  }
  final campaign = Uri(
    queryParameters: {
      'utm_source': 'garden_postcard',
      'utm_medium': 'share',
      'utm_campaign': 'garden_v1',
    },
  ).query;
  return Uri.https('play.google.com', '/store/apps/details', {
    'id': 'com.mysticcat.journal',
    'referrer': campaign,
  });
}
