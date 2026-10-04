enum SourceType {
  spotify('Spotify'),
  youtube('YouTube'),
  soundcloud('SoundCloud');

  const SourceType(this.displayName);

  final String displayName;
}
