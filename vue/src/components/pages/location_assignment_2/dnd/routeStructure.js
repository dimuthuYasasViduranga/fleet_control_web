export class RouteStructure {
  constructor() {
    this._routes = [];
  }

  get routes() {
    return this._routes.slice();
  }

  getRoute(digUnitId, loadId, dumpId) {
    return this._routes.find(r => {
      return r._digUnitId === digUnitId && r._loadId === loadId && r._dumpId === dumpId;
    });
  }

  add(digUnitId, loadId, dumpId) {
    if (!digUnitId && !loadId && !dumpId) {
      throw new Error('Cannot add empty route');
    }

    const existingRoute = this.getRoute(digUnitId, loadId, dumpId);
    if (!existingRoute) {
      this._routes.push(new Route(digUnitId, loadId, dumpId));
    }
  }

  remove(digUnitId, loadId, dumpId) {
    if (!digUnitId && !loadId && !dumpId) {
      throw new Error('Cannot remove empty route');
    }

    this._routes = this._routes.filter(r => {
      return r._digUnitId !== digUnitId || r._loadId !== loadId || r._dumpId !== dumpId;
    });
  }
}

export class Route {
  constructor(digUnitId, loadId, dumpId) {
    this._digUnitId = digUnitId;
    this._loadId = loadId;
    this._dumpId = dumpId;
  }

  get digUnitId() {
    return this._digUnitId;
  }

  get loadId() {
    return this._loadId;
  }

  get dumpId() {
    return this._dumpId;
  }
}
