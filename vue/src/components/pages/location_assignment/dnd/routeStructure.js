export class RouteStructure {
  constructor() {
    this._routes = [];
  }

  get routes() {
    return this._routes.slice();
  }

  get(digUnitId, loadId, dumpId) {
    return this._routes.find(r => {
      return r._digUnitId === digUnitId && r._loadId === loadId && r._dumpId === dumpId;
    });
  }

  add(digUnitId = null, loadId = null, dumpId = null) {
    if (!digUnitId && !loadId && !dumpId) {
      return;
    }

    if (digUnitId && loadId) {
      console.info('[Structure] Cannot have dig unit and load id at the same time');
      this.add(digUnitId, null, dumpId);
      return;
    }

    const existingRoute = this.get(digUnitId, loadId, dumpId);
    if (!existingRoute) {
      this._routes.push(new Route(digUnitId, loadId, dumpId));
    }
  }

  remove(digUnitId = null, loadId = null, dumpId = null) {
    if (!digUnitId && !loadId && !dumpId) {
      throw new Error('Cannot remove empty route');
    }

    this._routes = this._routes.filter(r => {
      return r._digUnitId !== digUnitId || r._loadId !== loadId || r._dumpId !== dumpId;
    });
  }

  removeAllDumpsFor(digUnitId, loadId) {
    this._routes = this._routes.filter(r => {
      return r._digUnitId !== digUnitId || r._loadId !== loadId;
    });
  }

  removeAll() { 
    this._routes = []
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
