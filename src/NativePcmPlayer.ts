import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
   playPCM(pcmData: number[]): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('PcmPlayer');
