String formatDistance(double distanceInMeters) {
  if (distanceInMeters < 1000) {
    return "${distanceInMeters.toStringAsFixed(0)} metros";
  } else {
    double distanceInKm = distanceInMeters / 1000;
    return "${distanceInKm.toStringAsFixed(2)} km";
  }
}
