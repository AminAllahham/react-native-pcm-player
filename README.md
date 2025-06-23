# react-native-pcm-player

A lightweight React Native library for playing raw PCM audio streams on Android and iOS. Perfect for real-time audio streaming, VoIP, or custom audio processing

## Installation

```sh
npm install react-native-pcm-player
```

## Usage


```js
import { playPCM } from 'react-native-pcm-player';

// ...

socket.on("audio-stream", (data) => {
    try {
      const buffer = Buffer.from(data.streamPCMBase64, "base64");
      const pcmArray = [];

      for (let i = 0; i < buffer.length; i += 2) {
        const sample = buffer.readInt16LE(i);
        pcmArray.push(sample);
      }

      playPCM(pcmArray);
    } catch (error) {
      console.error("Error playing PCM data:", error);
    }
});
```


## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
