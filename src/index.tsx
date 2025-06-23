import PcmPlayer from './NativePcmPlayer';

export default {
  playPCM: (pcm: Uint8Array) => {
    PcmPlayer.playPCM(Array.from(pcm));
  },
};
