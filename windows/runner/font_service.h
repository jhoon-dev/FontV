#ifndef RUNNER_FONT_SERVICE_H_
#define RUNNER_FONT_SERVICE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <condition_variable>
#include <deque>
#include <memory>
#include <mutex>
#include <thread>

// Serial native work keeps catalog scanning and PNG rendering off the UI thread.
class FontService {
 public:
  static constexpr UINT kResultMessage = WM_APP + 71;
  FontService(flutter::BinaryMessenger* messenger, HWND window);
  ~FontService();
  void CompleteResults();

 private:
  using Value = flutter::EncodableValue;
  using Result = flutter::MethodResult<Value>;
  struct Task {
    std::string method;
    Value arguments;
    std::unique_ptr<Result> result;
  };
  struct Completion {
    std::unique_ptr<Result> result;
    Value value;
    std::string error;
  };
  void Run();
  HWND window_;
  std::unique_ptr<flutter::MethodChannel<Value>> channel_;
  std::mutex mutex_;
  std::condition_variable ready_;
  std::deque<Task> tasks_;
  std::deque<Completion> completed_;
  bool stopping_ = false;
  std::thread worker_;
};
#endif
