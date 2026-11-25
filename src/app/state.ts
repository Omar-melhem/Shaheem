import { useStore } from 'zustand';
import { createApplicationStore, type AppState } from '@/application/store';
import { createEmptyData, createSeedData } from '@/infrastructure/seed';
import { browserRepository, STORAGE_KEY, observeStorage, startSimulationClock } from '@/infrastructure/browserState';
export * from '@/application/store';
// The site starts empty (no fictional data). The test suite runs against the fictional demo fixture.
const initialData = import.meta.env.MODE === 'test' ? createSeedData : createEmptyData;
const store = createApplicationStore(initialData, browserRepository);
export const useAppStore = Object.assign(<T = AppState>(selector: (state: AppState) => T = (s) => s as unknown as T) => useStore(store, selector), store);
export const getAppData = () => store.getState();
export const enableCrossTabSync = () => observeStorage(STORAGE_KEY, () => { const data = browserRepository.load(); if (data) store.setState(data); });
export const startDemoClock = () => startSimulationClock((now) => store.getState().tick(now));
export { generateTemporaryPassword } from '@/infrastructure/credentials';
