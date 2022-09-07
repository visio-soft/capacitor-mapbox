import { registerPlugin } from '@capacitor/core';

import type { CapacitorMapboxNavigationPlugin } from './definitions';

const CapacitorMapboxNavigation = registerPlugin<CapacitorMapboxNavigationPlugin>(
  'CapacitorMapboxNavigation',
  {
    web: () => import('./web').then(m => new m.CapacitorMapboxNavigationWeb()),
  },
);

export * from './definitions';
export { CapacitorMapboxNavigation };
