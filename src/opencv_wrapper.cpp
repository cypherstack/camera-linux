#include <iostream>
#include <opencv2/opencv.hpp>
#include <thread>
#include <atomic>
#include <mutex>

using namespace std;
using namespace cv;
    
std::thread videoThread;
std::atomic<bool> stopFlag(false);
std::mutex frameMutex;
Mat latestFrame;
                
// Extern C block to expose the function to C
extern "C" {
    // Function to capture video frames
    void runVideoCapture() {
        VideoCapture cap(0);
        if (!cap.isOpened()) {
            cout << "No video stream detected" << endl;
            system("pause");
            return;
        }

        while (!stopFlag.load()) {
            Mat frame;
            cap >> frame;
            if (frame.empty()) {
                printf("Frame is Empty");
                break;
            }

            {
                lock_guard<std::mutex> lock(frameMutex);
                frame.copyTo(latestFrame);
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        }
        cap.release();
    }

 
    void startVideoCaptureInThread() {
        stopFlag = false;
        videoThread = std::thread(runVideoCapture);
    }

    void stopVideoCapture() {
         stopFlag = true;
        if (videoThread.joinable()) {
            videoThread.join();
        }
    }

    uint8_t* getLatestFrameBytes(int* length) {

        // Ensure the pointer is valid
        if (!length) {
            cout << "Length pointer is null." << endl;
            return nullptr;
        }

        *length = 0;  // Initialize length to 0

        Mat frameCopy;
        {
            std::lock_guard<std::mutex> lock(frameMutex);

            if (latestFrame.empty()) {
                printf("Frame Empty\n");
                return nullptr;
            }

            frameCopy = latestFrame.clone(); // Clone the frame to avoid race conditions
            latestFrame.release(); // Clear the frame after it has been fetched
        }

        // Encode the frame as JPEG
        vector<uint8_t> buf;
        bool encodeSuccess = imencode(".jpg", frameCopy, buf);

        // Check if encoding was successful
        if (!encodeSuccess || buf.empty()) {
            cout << "Failed to encode image." << endl;
            return nullptr;
        }
        
        *length = static_cast<int>(buf.size());
        // Allocate memory and copy data
        uint8_t* data = new uint8_t[*length];

        if (!data) {
            cout << "Memory allocation failed." << endl;
            return nullptr;
        }
        
        memcpy(data, buf.data(), *length);

        return data;
    }
}
 