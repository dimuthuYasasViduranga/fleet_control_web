export function setMapTypeOverlay(map, google, mapManifest) {
  if (!map || !google || !mapManifest) {
    console.error('[MapOverlay] Cannot set custom map overlay');
    return;
  }
  const mapType = new google.maps.ImageMapType({
    name,
    getTileUrl: (coord, zoom) => {
      const coordStr = `${zoom}_${coord.x}_${coord.y}`;
      return (mapManifest || {})[coordStr];
    },
    tilteSize: new google.maps.Size(256, 256),
  });

  map.overlayMapTypes.push(mapType);
}
