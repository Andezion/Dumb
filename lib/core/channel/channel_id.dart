enum ChannelId {
  acoustic,
  mechanical,
  magnetic,
  optical,
  ambientLight,
}

extension ChannelIdDisplay on ChannelId {
  String get title => switch (this) {
        ChannelId.acoustic => 'ACOUSTIC',
        ChannelId.mechanical => 'MECHANICAL',
        ChannelId.magnetic => 'MAGNETIC',
        ChannelId.optical => 'OPTICAL',
        ChannelId.ambientLight => 'LIGHT SENSOR',
      };

  String get physicalChain => switch (this) {
        ChannelId.acoustic => 'Speaker -> Air -> Microphone',
        ChannelId.mechanical => 'Vibration -> Surface -> Accelerometer',
        ChannelId.magnetic => 'Field -> Magnetometer',
        ChannelId.optical => 'Screen / Flash -> Camera',
        ChannelId.ambientLight => 'Light -> Ambient Sensor',
      };

  String get glyph => switch (this) {
        ChannelId.acoustic => '~~~',
        ChannelId.mechanical => '≋',
        ChannelId.magnetic => '◉',
        ChannelId.optical => '◧',
        ChannelId.ambientLight => '☼',
      };
}
