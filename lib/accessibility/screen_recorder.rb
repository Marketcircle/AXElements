framework 'AVFoundation'
require   'accessibility/version'
require   'ax_elements/core_graphics_workaround'

##
# Screen recordings, easy as pie.
#
# Things that you need to be concerned about:
#   - screen going to sleep
#   - short recordings (~1 second) don't work too well; it looks like
#     the last bit of the buffer does not get saved so the last ~0.5
#     seconds are not saved to disk (we could add a 0.5 second sleep)
#   - small memory leak when a recording starts on Mountain Lion (GC)
#   - constantly leaking memory during recording on Lion (GC)
#   - run loop hack is not needed if code is already being called from
#     in a run loop
#   - pausing is not working...not sure why
#
class Accessibility::ScreenRecorder

  ##
  # Record the screen while executing the given block. The path to the
  # recording will be returned.
  #
  # The recorder object is yielded.
  #
  # @yield
  # @yieldparam recorder [ScreenRecorder]
  # @return [String]
  def self.record file_name = nil
    raise 'block required' unless block_given?

    recorder = new
    file_name ? recorder.start(file_name) : recorder.start
    yield recorder
    recorder.file

  ensure
    recorder.stop
  end

  ##
  # Path to the screen recording. This is `nil` until the screen
  # recording begins.
  #
  # @return [String]
  attr_reader :file

  ##
  # @todo Expose configuration options at initialie time
  def initialize
    @session = AVCaptureSession.alloc.init

    @input = AVCaptureScreenInput.alloc.initWithDisplayID CGMainDisplayID()
    @input.capturesMouseClicks = true

    @output = AVCaptureMovieFileOutput.alloc.init
    @output.setDelegate self

    @session.addInput @input
    @session.addOutput @output

    @sema = Dispatch::Semaphore.new 0
  end

  ##
  # Synchrnously start recording. You can optionally specify a file
  # name for the recording; if you do not then a default name will be
  # provided in the form `~/Movies/TestRecording-20121017123230.mov`
  # (the timestamp will be different for you).
  #
  # @param file_name [String]
  def start file_name = default_file_name
    @file = default_file_name
    file_url = NSURL.fileURLWithPath @file, isDirectory: false

    @session.startRunning
    @output.startRecordingToOutputFileURL file_url,
                       recordingDelegate: self

    @sema.wait
  end

  ##
  # Whether or not the recording has begun. This will be `true`
  # after calling {#start} until {#stop} is called. It will be
  # `true` while the recording is paused.
  def started?
    @output.recording?
  end

  # ##
  # # Whether or not the recording has been paused.
  # def paused?
  #   @output.paused?
  # end

  ##
  # Duration of the recording, in seconds.
  #
  # @return [Float]
  def length
    duration = @output.recordedDuration
    (duration.value.to_f / duration.timescale.to_f)
  end

  ##
  # Size of the recording on disk, in bytes.
  #
  # @return [Fixnum]
  def size
    @output.recordedFileSize
  end

  # ##
  # # Synchronously pause the recording. You can optionally pass a block
  # # to this method.
  # #
  # # If you pass a block, the recording is paused so that the block
  # # can execute and recording resumes after the block finishes. If
  # # you do not pass a block then the recording is paused until you
  # # call {#resume} on the receiver.
  # #
  # # @yield Optionally pass a block
  # def pause
  #   @output.pauseRecording
  #   wait_for_callback
  #   @sema.wait

  #   if block_given?
  #     yield
  #     resume
  #   end
  # end

  # ##
  # # Synchronously resume a {#pause}d recording.
  # def resume
  #   @output.resumeRecording
  #   wait_for_callback
  #   @sema.wait
  # end

  ##
  # Synchronously stop recording and finish up commiting any data to disk.
  # A recording cannot be {#start}ed again after it has been stopped; if
  # you want to pause a recording then you should use {#pause} instead.
  def stop
    @session.stopRunning
    @output.stopRecording
    @sema.wait
    wait_for_callback
    @sema.wait
  end


  # @!group AVCaptureFileOutputDelegate

  def captureOutput captureOutput, didOutputSampleBuffer:sampleBuffer, fromConnection:connection
    # gets called for every chunk of the recording getting committed to disk
  end

  def captureOutput captureOutput, didDropSampleBuffer:sampleBuffer,   fromConnection:connection
    NSLog("Error: dropped same data from recording")
  end


  # @!group AVCaptureFileOutputRecordingDelegate

  def captureOutput captureOutput, didFinishRecordingToOutputFileAtURL:outputFileURL, fromConnections:connections, error:error
    NSLog('Finishing')
    CFRunLoopStop(CFRunLoopGetCurrent())
    @sema.signal
  end

  def captureOutput captureOutput, didPauseRecordingToOutputFileAtURL:fileURL, fromConnections:connections
    NSLog('Pausing')
    CFRunLoopStop(CFRunLoopGetCurrent())
    @sema.signal
  end

  def captureOutput captureOutput, didResumeRecordingToOutputFileAtURL:fileURL, fromConnections:connections
    NSLog('Resuming')
    CFRunLoopStop(CFRunLoopGetCurrent())
    @sema.signal
  end

  def captureOutput captureOutput, didStartRecordingToOutputFileAtURL:fileURL, fromConnections:connections
    NSLog('Starting')
    @sema.signal
  end

  def captureOutput captureOutput, willFinishRecordingToOutputFileAtURL:fileURL, fromConnections:connections, error:error
    NSLog('Will Finish')
    @sema.signal
  end


  private

  def default_file_name
    date = Time.now.strftime '%Y%m%d%H%M%S'
    File.expand_path("~/Movies/TestRecording-#{date}.mov")
  end

  def wait_for_callback
    case CFRunLoopRunInMode(KCFRunLoopDefaultMode, 30, false)
    when KCFRunLoopRunStopped
      true
    when KCFRunLoopRunTimedOut
      raise 'did not get callback'
    else
      raise 'unexpected result from waiting for callback'
    end
  end

end
