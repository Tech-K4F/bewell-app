import 'package:flutter/material.dart';

// ─── Modello sconto Awin ──────────────────────────────────────────────────────

class BwDiscount {
  final String id;
  final String brandName;
  final String description;    // es. "-15% su tutto"
  final String code;           // es. "BEWELL15"
  final String categoryEmoji;
  final String url;            // link affiliato Awin
  final String exclusiveLabel; // es. "esclusivo Be Well"
  final Color bgColor;

  const BwDiscount({
    required this.id,
    required this.brandName,
    required this.description,
    required this.code,
    required this.categoryEmoji,
    required this.url,
    required this.exclusiveLabel,
    required this.bgColor,
  });
}

// ─── Palette colori di sfondo card (costanti light) ──────────────────────────

const _tealLight   = Color(0xFFE0F2F1);
const _amberLight  = Color(0xFFFFF8E1);
const _grayLight   = Color(0xFFF5F5F5);

// ─── Catalogo sconti iniziale (hardcodata) ───────────────────────────────────
// Sostituire gli URL con link affiliati Awin reali prima del rilascio.
// Nessun dato utente identificabile incluso nei link.

class DiscountCatalog {
  static const List<BwDiscount> all = [
    BwDiscount(
      id: 'myprotein',
      brandName: 'MyProtein',
      description: '-15% su tutto',
      code: 'BEWELL15',
      categoryEmoji: '💪',
      url: 'https://www.myprotein.com', // TODO: sostituire con link Awin reale
      exclusiveLabel: 'esclusivo Be Well',
      bgColor: _tealLight,
    ),
    BwDiscount(
      id: 'decathlon',
      brandName: 'Decathlon',
      description: '-10% su tutto il catalogo',
      code: 'BEWELL10',
      categoryEmoji: '🏊',
      url: 'https://www.decathlon.it',  // TODO: sostituire con link Awin reale
      exclusiveLabel: 'esclusivo Be Well',
      bgColor: _amberLight,
    ),
    BwDiscount(
      id: 'iherb',
      brandName: 'iHerb',
      description: '-20% integratori naturali',
      code: 'BEWELL20',
      categoryEmoji: '🌿',
      url: 'https://www.iherb.com',     // TODO: sostituire con link Awin reale
      exclusiveLabel: 'esclusivo Be Well',
      bgColor: _tealLight,
    ),
    BwDiscount(
      id: 'yogi_tea',
      brandName: 'Yogi Tea',
      description: '-10% tisane biologiche',
      code: 'BEWELLTEA',
      categoryEmoji: '🍵',
      url: 'https://www.yogitea.com',   // TODO: sostituire con link Awin reale
      exclusiveLabel: 'esclusivo Be Well',
      bgColor: _amberLight,
    ),
    BwDiscount(
      id: 'garmin',
      brandName: 'Garmin',
      description: '-8% wearable salute',
      code: 'BEWELLFIT',
      categoryEmoji: '⌚',
      url: 'https://www.garmin.com',    // TODO: sostituire con link Awin reale
      exclusiveLabel: 'esclusivo Be Well',
      bgColor: _grayLight,
    ),
  ];
}
