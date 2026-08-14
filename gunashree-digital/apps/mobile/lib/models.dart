import 'package:flutter/material.dart';

double numberValue(Object? value, [double fallback = 0]) {
  return value is num ? value.toDouble() : fallback;
}

String stringValue(Object? value, [String fallback = '']) {
  return value is String && value.isNotEmpty ? value : fallback;
}

Color colorFromHex(String value, [Color fallback = Colors.white]) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(
    normalized.length == 6 ? 'FF$normalized' : normalized,
    radix: 16,
  );
  return parsed == null ? fallback : Color(parsed);
}

String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

class PosterLayer {
  PosterLayer({
    required this.id,
    required this.type,
    this.text = '',
    this.src = '',
    this.x = 0,
    this.y = 0,
    this.width = 240,
    this.height = 120,
    this.fontSize = 42,
    this.color = Colors.black,
    this.locked = false,
  });

  final String id;
  final String type;
  String text;
  String src;
  double x;
  double y;
  double width;
  double height;
  double fontSize;
  Color color;
  bool locked;

  bool get isText => type == 'text';
  bool get isImage => type == 'image';

  PosterLayer copy() {
    return PosterLayer(
      id: id,
      type: type,
      text: text,
      src: src,
      x: x,
      y: y,
      width: width,
      height: height,
      fontSize: fontSize,
      color: color,
      locked: locked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'text': text,
        'src': src,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'fontSize': fontSize,
        'color': colorToHex(color),
        'locked': locked,
      };

  factory PosterLayer.fromJson(Map<String, dynamic> json) {
    return PosterLayer(
      id: stringValue(
          json['id'], 'layer-${DateTime.now().microsecondsSinceEpoch}'),
      type: stringValue(json['type'], 'text'),
      text: stringValue(json['text']),
      src: stringValue(json['src']),
      x: numberValue(json['x']),
      y: numberValue(json['y']),
      width: numberValue(json['width'], 240),
      height: numberValue(json['height'], 120),
      fontSize: numberValue(json['fontSize'], 42),
      color: colorFromHex(stringValue(json['color'], '#17132B')),
      locked: json['locked'] == true,
    );
  }
}

class PosterTemplate {
  PosterTemplate({
    required this.id,
    required this.title,
    required this.slug,
    required this.width,
    required this.height,
    required this.layers,
    this.thumbnailUrl,
    this.backgroundUrl,
    this.categoryName = 'Featured',
    this.background = const Color(0xFFFFF8F1),
  });

  final String id;
  final String title;
  final String slug;
  final int width;
  final int height;
  final List<PosterLayer> layers;
  final String? thumbnailUrl;
  final String? backgroundUrl;
  final String categoryName;
  final Color background;

  double get aspectRatio => width / height;
  String get ratioLabel {
    final ratio = width / height;
    if ((ratio - 1).abs() < 0.04) return '1:1';
    if ((ratio - 0.8).abs() < 0.04) return '4:5';
    return '9:16';
  }

  factory PosterTemplate.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'] is Map
        ? Map<String, dynamic>.from(json['schema'] as Map)
        : <String, dynamic>{};
    final rawLayers =
        schema['layers'] is List ? schema['layers'] as List : const [];
    final layers = rawLayers
        .whereType<Map>()
        .map((layer) => PosterLayer.fromJson(Map<String, dynamic>.from(layer)))
        .toList();
    final rawCategory = json['category'];
    final category = rawCategory is Map
        ? stringValue(rawCategory['name'], 'Featured')
        : 'Featured';

    return PosterTemplate(
      id: stringValue(json['id'], stringValue(json['slug'], 'template')),
      title: stringValue(json['title'], 'Untitled Template'),
      slug: stringValue(json['slug'], 'template'),
      width: (json['width'] as num?)?.toInt() ?? 1080,
      height: (json['height'] as num?)?.toInt() ?? 1350,
      layers: layers,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      backgroundUrl: json['backgroundUrl'] as String?,
      categoryName: category,
      background: colorFromHex(stringValue(schema['background'], '#FFF8F1')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'width': width,
        'height': height,
        'categoryName': categoryName,
        'background': colorToHex(background),
        'layers': layers.map((layer) => layer.toJson()).toList(),
      };
}

class Category {
  const Category(
      {required this.id, required this.name, this.templateCount = 0});

  final String id;
  final String name;
  final int templateCount;

  factory Category.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] is Map ? json['_count']['templates'] : 0;
    return Category(
      id: stringValue(json['id'], json['name'].toString()),
      name: stringValue(json['name'], 'Other'),
      templateCount: count is num ? count.toInt() : 0,
    );
  }
}

class LocalDesign {
  LocalDesign({
    required this.id,
    required this.name,
    required this.templateId,
    required this.templateTitle,
    required this.background,
    required this.layers,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? templateId;
  final String templateTitle;
  final Color background;
  final List<PosterLayer> layers;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'templateId': templateId,
        'templateTitle': templateTitle,
        'background': colorToHex(background),
        'layers': layers.map((layer) => layer.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LocalDesign.fromJson(Map<String, dynamic> json) {
    final rawLayers =
        json['layers'] is List ? json['layers'] as List : const [];
    return LocalDesign(
      id: stringValue(
          json['id'], DateTime.now().microsecondsSinceEpoch.toString()),
      name: stringValue(json['name'], 'Untitled Design'),
      templateId: json['templateId'] as String?,
      templateTitle: stringValue(json['templateTitle'], 'Poster'),
      background: colorFromHex(stringValue(json['background'], '#FFF8F1')),
      layers: rawLayers
          .whereType<Map>()
          .map(
              (layer) => PosterLayer.fromJson(Map<String, dynamic>.from(layer)))
          .toList(),
      updatedAt:
          DateTime.tryParse(stringValue(json['updatedAt'])) ?? DateTime.now(),
    );
  }
}

List<PosterTemplate> demoTemplates() {
  return [
    PosterTemplate.fromJson({
      'id': 'demo-festival',
      'title': 'Festival Celebration',
      'slug': 'festival-celebration',
      'width': 1080,
      'height': 1350,
      'schema': {
        'background': '#FFF0E1',
        'layers': [
          {
            'id': 'eyebrow',
            'type': 'text',
            'text': 'SPECIAL INVITATION',
            'x': 78,
            'y': 90,
            'width': 880,
            'height': 50,
            'fontSize': 28,
            'color': '#A64B2A'
          },
          {
            'id': 'title',
            'type': 'text',
            'text': 'Celebrate\\nwith joy',
            'x': 78,
            'y': 220,
            'width': 860,
            'height': 230,
            'fontSize': 92,
            'color': '#17132B'
          },
          {
            'id': 'name',
            'type': 'text',
            'text': '{{NAME}}',
            'x': 80,
            'y': 1060,
            'width': 700,
            'height': 70,
            'fontSize': 38,
            'color': '#A64B2A'
          },
        ],
      },
    }),
    PosterTemplate.fromJson({
      'id': 'demo-business',
      'title': 'Business Promotion',
      'slug': 'business-promotion',
      'width': 1080,
      'height': 1350,
      'schema': {
        'background': '#E8F3F0',
        'layers': [
          {
            'id': 'label',
            'type': 'text',
            'text': 'NOW OPEN',
            'x': 80,
            'y': 80,
            'width': 880,
            'height': 52,
            'fontSize': 32,
            'color': '#1C7262'
          },
          {
            'id': 'title',
            'type': 'text',
            'text': '{{BUSINESS_NAME}}',
            'x': 80,
            'y': 200,
            'width': 900,
            'height': 190,
            'fontSize': 80,
            'color': '#143C38'
          },
          {
            'id': 'body',
            'type': 'text',
            'text': 'Quality you can\\nfeel every day.',
            'x': 80,
            'y': 470,
            'width': 700,
            'height': 150,
            'fontSize': 48,
            'color': '#275A53'
          },
          {
            'id': 'mobile',
            'type': 'text',
            'text': '{{MOBILE}}',
            'x': 80,
            'y': 1130,
            'width': 800,
            'height': 60,
            'fontSize': 36,
            'color': '#143C38'
          },
        ],
      },
    }),
    PosterTemplate.fromJson({
      'id': 'demo-story',
      'title': 'Daily Story',
      'slug': 'daily-story',
      'width': 1080,
      'height': 1920,
      'schema': {
        'background': '#17132B',
        'layers': [
          {
            'id': 'top',
            'type': 'text',
            'text': 'A LITTLE\\nINSPIRATION',
            'x': 74,
            'y': 120,
            'width': 880,
            'height': 250,
            'fontSize': 84,
            'color': '#FFFFFF'
          },
          {
            'id': 'quote',
            'type': 'text',
            'text': 'Make today\\nbeautiful.',
            'x': 74,
            'y': 850,
            'width': 900,
            'height': 250,
            'fontSize': 78,
            'color': '#F7C96F'
          },
          {
            'id': 'handle',
            'type': 'text',
            'text': '@gunashreedigital',
            'x': 74,
            'y': 1790,
            'width': 850,
            'height': 60,
            'fontSize': 28,
            'color': '#D7D2E6'
          },
        ],
      },
    }),
  ];
}
