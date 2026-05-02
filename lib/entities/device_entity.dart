class DeviceEntity {
  final String id;
  final String name;
  final String location;
  final String? udn;
  final String? manufacturer;
  final String? modelName;

  const DeviceEntity({
    required this.id,
    required this.name,
    required this.location,
    this.udn,
    this.manufacturer,
    this.modelName,
  });

  DeviceEntity copyWith({
    String? id,
    String? name,
    String? location,
    String? udn,
    String? manufacturer,
    String? modelName,
  }) {
    return DeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      udn: udn ?? this.udn,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          location == other.location;

  @override
  int get hashCode => Object.hash(id, name, location);

  @override
  String toString() {
    return 'DeviceEntity(id: $id, name: $name, location: $location)';
  }
}
