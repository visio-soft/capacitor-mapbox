export interface CapacitorMapboxNavigationPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  show(options: MapboxNavOptions): Promise<void>;
  history(): Promise<any>;
}

export interface MapboxNavOptions {
  routes: LocationOption[];
  mapType?: string;
}

export interface LocationOption {
  latitude: number;
  longitude: number;
}

export interface MapboxNavStyleOption {

}