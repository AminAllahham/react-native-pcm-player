#import "PcmPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <React/RCTBridgeModule.h>
#import <PcmPlayerSpec/PcmPlayerSpec.h>

@interface PcmPlayer () <NativePcmPlayerSpec>

@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioPlayerNode *playerNode;
@property (nonatomic, strong) dispatch_queue_t audioQueue;

// AVAudioConverter for resampling from 32kHz Int16 to 44.1kHz Float32
@property (nonatomic, strong) AVAudioConverter *converter;

// Buffers for conversion
@property (nonatomic, strong) AVAudioPCMBuffer *sourceBuffer;
@property (nonatomic, strong) AVAudioPCMBuffer *convertedBuffer;

@end

@implementation PcmPlayer

RCT_EXPORT_MODULE()

- (instancetype)init {
  if (self = [super init]) {
    _audioQueue = dispatch_queue_create("pcm_audio_queue", DISPATCH_QUEUE_SERIAL);
    [self setupAudioEngineAndConverter];
  }
  return self;
}

- (void)setupAudioEngineAndConverter {
  self.engine = [[AVAudioEngine alloc] init];
  self.playerNode = [[AVAudioPlayerNode alloc] init];

  // Destination format: Float32, 44100 Hz, mono, interleaved (for playback)
  AVAudioFormat *destFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                                sampleRate:44100
                                                                  channels:1
                                                               interleaved:YES];

  // Source format: Int16, 32000 Hz, mono, interleaved (from sender)
  AVAudioFormat *sourceFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16
                                                                  sampleRate:32000
                                                                    channels:1
                                                                 interleaved:YES];

  // Setup converter for resampling + format conversion
  self.converter = [[AVAudioConverter alloc] initFromFormat:sourceFormat toFormat:destFormat];

  // Attach and connect playerNode to engine's main mixer node with destFormat
  [self.engine attachNode:self.playerNode];
  [self.engine connect:self.playerNode to:self.engine.mainMixerNode format:destFormat];

  NSError *error = nil;
  [self.engine startAndReturnError:&error];
  if (error) {
    NSLog(@"[PcmPlayer] Failed to start AVAudioEngine: %@", error.localizedDescription);
  } else {
    [self.playerNode play];
    NSLog(@"[PcmPlayer] AVAudioEngine started and player node playing");
  }
}

RCT_EXPORT_METHOD(playPCM:(NSArray<NSNumber *> *)pcmArray) {
  dispatch_async(self.audioQueue, ^{
    NSUInteger sampleCount = pcmArray.count;

    if (sampleCount == 0 || !self.engine || !self.playerNode || !self.converter) {
      NSLog(@"[PcmPlayer] No PCM data to play or audio engine not initialized");
      return;
    }

    // Prepare source buffer for incoming Int16 PCM data @ 32000 Hz
    AVAudioFormat *sourceFormat = self.converter.inputFormat;
    AVAudioFrameCount frames = (AVAudioFrameCount)sampleCount;

    self.sourceBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:sourceFormat frameCapacity:frames];
    self.sourceBuffer.frameLength = frames;

    int16_t *sourceData = (int16_t *)self.sourceBuffer.int16ChannelData[0];
    for (NSUInteger i = 0; i < sampleCount; i++) {
      sourceData[i] = (int16_t)[pcmArray[i] intValue];
    }

    // Prepare converted buffer for Float32 PCM data @ 44100 Hz
    AVAudioFormat *destFormat = self.converter.outputFormat;
    AVAudioFrameCount maxConvertedFrames = (AVAudioFrameCount)(frames * destFormat.sampleRate / sourceFormat.sampleRate) + 1;
    self.convertedBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:destFormat frameCapacity:maxConvertedFrames];

    NSError *error = nil;

    AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer * (AVAudioPacketCount inNumPackets, AVAudioConverterInputStatus *outStatus) {
      *outStatus = AVAudioConverterInputStatus_HaveData;
      return self.sourceBuffer;
    };

    // Perform conversion (resampling + format conversion)
    AVAudioConverterOutputStatus status = [self.converter convertToBuffer:self.convertedBuffer error:&error withInputFromBlock:inputBlock];

    if (status != AVAudioConverterOutputStatus_HaveData && status != AVAudioConverterOutputStatus_EndOfStream) {
      NSLog(@"[PcmPlayer] Audio conversion failed with status %ld error: %@", (long)status, error.localizedDescription);
      return;
    }

    // Schedule the converted buffer for playback
    [self.playerNode scheduleBuffer:self.convertedBuffer completionHandler:nil];
  });
}

RCT_EXPORT_METHOD(invalidate) {
  dispatch_async(self.audioQueue, ^{
    [self.playerNode stop];
    [self.engine stop];
    self.playerNode = nil;
    self.engine = nil;
    self.converter = nil;
    self.sourceBuffer = nil;
    self.convertedBuffer = nil;
    NSLog(@"[PcmPlayer] AVAudioEngine stopped and cleaned up");
  });
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
  (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativePcmPlayerSpecJSI>(params);
}

@end
