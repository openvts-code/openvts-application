import 'package:flutter/material.dart';

/// Shared POI categories. Backend stores the [value] as free text; the [label]
/// is what we render. Keep values lowercase snake-case so they remain stable.
class UserPoiCategoryOption {
  const UserPoiCategoryOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

const List<UserPoiCategoryOption> kUserPoiCategories = <UserPoiCategoryOption>[
  UserPoiCategoryOption(
    value: 'airport',
    label: 'Airport',
    icon: Icons.flight_outlined,
  ),
  UserPoiCategoryOption(
    value: 'atm',
    label: 'ATM',
    icon: Icons.atm_outlined,
  ),
  UserPoiCategoryOption(
    value: 'office',
    label: 'Office',
    icon: Icons.business_outlined,
  ),
  UserPoiCategoryOption(
    value: 'home',
    label: 'Home',
    icon: Icons.home_outlined,
  ),
  UserPoiCategoryOption(
    value: 'hotel',
    label: 'Hotel',
    icon: Icons.hotel_outlined,
  ),
  UserPoiCategoryOption(
    value: 'restaurant',
    label: 'Restaurant',
    icon: Icons.restaurant_outlined,
  ),
  UserPoiCategoryOption(
    value: 'shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_outlined,
  ),
  UserPoiCategoryOption(
    value: 'park',
    label: 'Park',
    icon: Icons.park_outlined,
  ),
  UserPoiCategoryOption(
    value: 'museum',
    label: 'Museum',
    icon: Icons.museum_outlined,
  ),
  UserPoiCategoryOption(
    value: 'hospital',
    label: 'Hospital',
    icon: Icons.local_hospital_outlined,
  ),
  UserPoiCategoryOption(
    value: 'school',
    label: 'School',
    icon: Icons.school_outlined,
  ),
  UserPoiCategoryOption(
    value: 'gas_station',
    label: 'Gas Station',
    icon: Icons.local_gas_station_outlined,
  ),
  UserPoiCategoryOption(
    value: 'gym',
    label: 'Gym',
    icon: Icons.fitness_center_outlined,
  ),
  UserPoiCategoryOption(
    value: 'cafe',
    label: 'Cafe',
    icon: Icons.local_cafe_outlined,
  ),
  UserPoiCategoryOption(
    value: 'library',
    label: 'Library',
    icon: Icons.local_library_outlined,
  ),
];

/// Slug → Material icon mapping for POI pins and cards. Values are the
/// strings persisted in the backend `icon` field.
class UserPoiIconOption {
  const UserPoiIconOption({required this.slug, required this.icon});

  final String slug;
  final IconData icon;
}

const List<UserPoiIconOption> kUserPoiIcons = <UserPoiIconOption>[
  UserPoiIconOption(slug: 'mappin', icon: Icons.place_outlined),
  UserPoiIconOption(slug: 'airport', icon: Icons.flight_outlined),
  UserPoiIconOption(slug: 'atm', icon: Icons.atm_outlined),
  UserPoiIconOption(slug: 'office', icon: Icons.business_outlined),
  UserPoiIconOption(slug: 'home', icon: Icons.home_outlined),
  UserPoiIconOption(slug: 'hotel', icon: Icons.hotel_outlined),
  UserPoiIconOption(slug: 'restaurant', icon: Icons.restaurant_outlined),
  UserPoiIconOption(slug: 'shopping', icon: Icons.shopping_bag_outlined),
  UserPoiIconOption(slug: 'park', icon: Icons.park_outlined),
  UserPoiIconOption(slug: 'museum', icon: Icons.museum_outlined),
  UserPoiIconOption(slug: 'hospital', icon: Icons.local_hospital_outlined),
  UserPoiIconOption(slug: 'school', icon: Icons.school_outlined),
  UserPoiIconOption(
      slug: 'gas-station', icon: Icons.local_gas_station_outlined),
  UserPoiIconOption(slug: 'gym', icon: Icons.fitness_center_outlined),
  UserPoiIconOption(slug: 'cafe', icon: Icons.local_cafe_outlined),
  UserPoiIconOption(slug: 'library', icon: Icons.local_library_outlined),
  UserPoiIconOption(slug: 'warehouse', icon: Icons.warehouse_outlined),
  UserPoiIconOption(slug: 'factory', icon: Icons.factory_outlined),
  UserPoiIconOption(slug: 'parking', icon: Icons.local_parking_outlined),
  UserPoiIconOption(slug: 'car', icon: Icons.directions_car_outlined),
  UserPoiIconOption(slug: 'train', icon: Icons.train_outlined),
  UserPoiIconOption(slug: 'bus', icon: Icons.directions_bus_outlined),
  UserPoiIconOption(slug: 'port', icon: Icons.anchor_outlined),
  UserPoiIconOption(slug: 'marina', icon: Icons.directions_boat_outlined),
  UserPoiIconOption(slug: 'checkpoint', icon: Icons.flag_outlined),
  UserPoiIconOption(slug: 'favorite', icon: Icons.favorite_border),
  UserPoiIconOption(slug: 'important', icon: Icons.priority_high),
  UserPoiIconOption(slug: 'warning', icon: Icons.warning_amber_outlined),
  UserPoiIconOption(slug: 'info', icon: Icons.info_outline),
];

const String kDefaultUserPoiIconSlug = 'mappin';

/// Returns the Material icon for the given slug, or `Icons.place_outlined`
/// when the slug is unknown or empty.
IconData iconForUserPoiSlug(String? slug) {
  if (slug == null || slug.trim().isEmpty) return Icons.place_outlined;
  final needle = slug.trim().toLowerCase();
  for (final option in kUserPoiIcons) {
    if (option.slug == needle) return option.icon;
  }
  return Icons.place_outlined;
}

/// Returns the label for a category value, falling back to the value itself
/// (Title Cased) when the category is custom/unknown.
String labelForUserPoiCategory(String? value) {
  if (value == null || value.trim().isEmpty) return 'Uncategorised';
  final needle = value.trim();
  for (final option in kUserPoiCategories) {
    if (option.value.toLowerCase() == needle.toLowerCase()) {
      return option.label;
    }
  }
  return needle;
}

IconData iconForUserPoiCategory(String? value) {
  if (value == null || value.trim().isEmpty) return Icons.place_outlined;
  final needle = value.trim().toLowerCase();
  for (final option in kUserPoiCategories) {
    if (option.value == needle) return option.icon;
  }
  return Icons.place_outlined;
}
